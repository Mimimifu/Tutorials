
## 📋 Arquitetura do LoadBalancer

```
Máquina 1 (192.168.1.100)          Máquina 2 (192.168.1.101)
├── Ollama (porta 11434)           ├── Ollama (porta 11434)
├── OLOL Server (porta 50051)       ├── OLOL Server (porta 50051)
└── Modelos: DeepSeek, Qwen         └── Modelos: DeepSeek, Qwen
                    ↓                              ↓
              ┌──────────────────────────────────────┐
              │  Proxy Load Balancer (porta 8000)    │
              │  - Distribui requests entre as duas  │
              │  - Mantém consistência               │
              └──────────────────────────────────────┘
```

---

## 🚀 Script de Instalação Automática

Crie um arquivo chamado `install_ollama_cluster.sh`:

```bash
#!/bin/bash

# Script de instalação do LoadBalancer Ollama com 2 máquinas
# Autor: Seu nome
# Uso: ./install_ollama_cluster.sh

set -e  # Para o script se algum comando falhar

# Cores pra deixar bonito
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Ollama Cluster Installer v1.0       ${NC}"
echo -e "${BLUE}========================================${NC}"

# Configurações
read -p "IP da MÁQUINA 1 (ex: 192.168.1.100): " IP1
read -p "IP da MÁQUINA 2 (ex: 192.168.1.101): " IP2
read -p "Esta máquina é a Máquina 1 ou 2? [1/2]: " THIS_MACHINE

echo -e "\n${YELLOW}📦 Instalando dependências...${NC}"

# 1. Instalar Ollama (se não tiver)
if ! command -v ollama &> /dev/null; then
    echo -e "${YELLOW}Instalando Ollama...${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}✓ Ollama já instalado${NC}"
fi

# 2. Instalar Python e pip se não tiver
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Instalando Python3...${NC}"
    sudo apt update && sudo apt install python3 python3-pip -y
fi

# 3. Instalar OLOL (Ollama Load Balancer)
echo -e "${YELLOW}Instalando OLOL...${NC}"
pip3 install olol --break-system-packages 2>/dev/null || pip3 install olol

# 4. Parar serviço do Ollama se estiver rodando
echo -e "${YELLOW}Configurando serviços...${NC}"
sudo systemctl stop ollama 2>/dev/null || true

# 5. Criar arquivo de serviço systemd para o OLOL Server
echo -e "${YELLOW}Criando serviço OLOL Server...${NC}"
sudo tee /etc/systemd/system/olol-server.service > /dev/null <<EOF
[Unit]
Description=OLOL Server for Ollama Cluster
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/olol server --host 0.0.0.0 --port 50051 --ollama-host http://localhost:11434
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 6. Configurar baseado em qual máquina é
if [ "$THIS_MACHINE" = "1" ]; then
    echo -e "${GREEN}Configurando MÁQUINA 1 (Mestre)${NC}"
    
    # Criar serviço do proxy (só roda na máquina 1)
    sudo tee /etc/systemd/system/olol-proxy.service > /dev/null <<EOF
[Unit]
Description=OLOL Proxy Load Balancer
After=network.target olol-server.service
Requires=olol-server.service

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/olol proxy --host 0.0.0.0 --port 8000 --servers "${IP1}:50051,${IP2}:50051"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Servidores que serão registrados
    echo -e "${GREEN}Servidores do cluster:${NC}"
    echo "  - ${IP1}:50051 (esta máquina)"
    echo "  - ${IP2}:50051"
    
    # Habilitar proxy
    sudo systemctl enable olol-proxy.service
    
elif [ "$THIS_MACHINE" = "2" ]; then
    echo -e "${GREEN}Configurando MÁQUINA 2 (Worker)${NC}"
    echo -e "${YELLOW}⚠️  Lembre-se de que a Máquina 1 precisa ter o IP ${IP1}${NC}"
else
    echo -e "${RED}❌ Opção inválida! Execute novamente e escolha 1 ou 2${NC}"
    exit 1
fi

# 7. Habilitar e iniciar serviços
echo -e "${YELLOW}Iniciando serviços...${NC}"
sudo systemctl enable ollama 2>/dev/null || true
sudo systemctl enable olol-server.service
sudo systemctl start ollama
sudo systemctl start olol-server.service

if [ "$THIS_MACHINE" = "1" ]; then
    sudo systemctl start olol-proxy.service
fi

# 8. Baixar modelos recomendados
echo -e "${YELLOW}📥 Baixando modelos recomendados...${NC}"
echo -e "${BLUE}Isso pode levar alguns minutos...${NC}"

ollama pull qwen2.5:7b
ollama pull deepseek-r1:7b
ollama pull nomic-embed-text  # Para RAG

# 9. Script de teste
cat > ~/test_cluster.sh << 'TESTEOF'
#!/bin/bash
echo "🧪 Testando Cluster Ollama"
echo "=========================="
echo ""
echo "1. Verificando servidores OLOL:"
curl -s http://localhost:50051 2>/dev/null && echo "✓ Server OK" || echo "✗ Server offline"
echo ""
echo "2. Testando proxy (via API do Ollama):"
curl -s http://localhost:8000/api/tags | python3 -m json.tool 2>/dev/null | head -20
echo ""
echo "3. Testando geração de texto:"
curl -s http://localhost:8000/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "Diga 'Olá, cluster funcionando!' em português",
  "stream": false
}' | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null
echo ""
echo "✅ Teste concluído!"
TESTEOF

chmod +x ~/test_cluster.sh

# 10. Informações finais
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Instalação COMPLETA!${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$THIS_MACHINE" = "1" ]; then
    echo -e "${BLUE}📡 Proxy Load Balancer rodando em:${NC}"
    echo -e "   http://${IP1}:8000"
    echo -e "   http://localhost:8000"
    echo -e "\n${BLUE}🔗 Para acessar de OUTRA máquina na rede:${NC}"
    echo -e "   curl http://${IP1}:8000/api/generate ..."
else
    echo -e "${BLUE}🔧 Worker configurado!${NC}"
    echo -e "   Aguardando conexão com máquina 1 (${IP1})"
fi

echo -e "\n${BLUE}🎯 Comandos úteis:${NC}"
echo -e "   ./test_cluster.sh            # Testar se o cluster está funcionando"
echo -e "   sudo journalctl -u olol-server -f  # Ver logs do servidor"
echo -e "   ollama list                   # Ver modelos instalados"
echo -e "   curl http://localhost:8000/api/tags  # Ver modelos via proxy"

if [ "$THIS_MACHINE" = "1" ]; then
    echo -e "\n${YELLOW}⚠️  IMPORTANTE:${NC}"
    echo -e "   1. Execute este script na MÁQUINA 2 também"
    echo -e "   2. Verifique se as portas 50051 e 8000 estão liberadas no firewall"
    echo -e "      sudo ufw allow 50051/tcp && sudo ufw allow 8000/tcp"
fi

echo -e "\n${GREEN}🚀 Cluster pronto para usar!${NC}"
```

---

## 📝 Como usar o script

### Passo 1: Em ambas as máquinas, salve o script

```bash
nano install_ollama_cluster.sh
# Cole o conteúdo acima
chmod +x install_ollama_cluster.sh
```

### Passo 2: Execute na Máquina 1

```bash
./install_ollama_cluster.sh
# Quando perguntar:
# IP da MÁQUINA 1: 192.168.1.100 (exemplo)
# IP da MÁQUINA 2: 192.168.1.101 (exemplo)
# Esta máquina é a 1 ou 2? 1
```

### Passo 3: Execute na Máquina 2

```bash
./install_ollama_cluster.sh
# IP da MÁQUINA 1: 192.168.1.100
# IP da MÁQUINA 2: 192.168.1.101  
# Esta máquina é a 1 ou 2? 2
```

---

## 🔥 Script de verificação rápida

Crie um arquivo `cluster_status.sh` para verificar se tudo está ok:

```bash
#!/bin/bash
echo "📊 Status do Cluster Ollama"
echo "==========================="
echo ""

# Verifica serviços na máquina atual
echo "🖥️  Máquina atual:"
systemctl is-active ollama && echo "  ✓ Ollama: ativo" || echo "  ✗ Ollama: inativo"
systemctl is-active olol-server && echo "  ✓ OLOL Server: ativo" || echo "  ✗ OLOL Server: inativo"

# Se for máquina 1, verifica proxy
if systemctl is-active olol-proxy &>/dev/null; then
    echo "  ✓ OLOL Proxy: ativo"
    echo ""
    echo "📡 Endpoints disponíveis:"
    echo "  Proxy: http://localhost:8000"
    echo "  API:   http://localhost:11434"
fi

echo ""
echo "📦 Modelos disponíveis:"
ollama list

echo ""
echo "🔗 Conexões ativas:"
sudo netstat -tlnp | grep -E ":(11434|50051|8000)" || echo "  Nenhuma porta ouvindo"
```

---

## 🧪 Testando o Cluster

```bash
# Teste simples via proxy
curl http://localhost:8000/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "O que é um cluster de IA? Responda curto",
  "stream": false
}'

# Ver logs para ver qual máquina processou
sudo journalctl -u olol-proxy -f
```

---

## ⚠️ Configurações adicionais para Windows

Se estiver usando **Multipass no Windows 11** como suas máquinas, você precisa:

```bash
# Dentro de CADA VM, liberar as portas no firewall
sudo ufw allow 11434/tcp
sudo ufw allow 50051/tcp
sudo ufw allow 8000/tcp
sudo ufw enable

# No Windows HOST, criar port forwarding (PowerShell Admin)
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=192.168.1.100

# Verificar
netsh interface portproxy show all
```

---

## 📊 Monitoramento básico

```bash
# Ver carga em tempo real
watch -n 2 'curl -s http://localhost:8000/api/tags | jq ".models[].name"'

# Ver logs do cluster
tail -f /var/log/syslog | grep -E "(olol|ollama)"
```

Pronto! Agora você tem um **cluster de 2 máquinas rodando LLMs em paralelo** 🎉

