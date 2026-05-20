
---

### `README.md` (Arquivo Principal)

```markdown
# Tutorial: Como Configurar um Rerun 24/7 na Twitch Usando um VPS e FFmpeg

**Autor:** DeepSeek  
**Projeto para:** lbzconsultoria (Mimimifu)  
**Última atualização:** 2026

## 📌 Visão Geral

Este tutorial te guiará passo a passo para criar um sistema de **rerun (replay contínuo)** para a Twitch usando um VPS (Servidor Virtual Privado) e o FFmpeg. O objetivo é transformar um servidor Linux básico em uma estação de transmissão que roda 24/7, sem precisar deixar um computador pessoal ligado.

### 🎯 O que você vai conseguir?
- Transmitir um vídeo em **loop infinito** para o seu canal da Twitch.
- O sistema ficará rodando **24 horas por dia**, mesmo com seu computador desligado.
- Controle total sobre o processo, sem depender de serviços pagos de rerun.

### 🛠️ Ferramentas Utilizadas
- **FFmpeg**: Software para processar e transmitir o vídeo.
- **Screen** ou **Systemd**: Para manter o processo ativo no servidor.
- **Git** (opcional): Para clonar repositórios.

---

## 📂 Estrutura do Tutorial

O tutorial está dividido em várias etapas para facilitar o acompanhamento:

1. **[01 - Contratando o VPS](#01---contratando-o-vps)**
2. **[02 - Conectando ao Servidor via SSH](#02---conectando-ao-servidor-via-ssh)**
3. **[03 - Instalando o FFmpeg](#03---instalando-o-ffmpeg)**
4. **[04 - Obtendo a Stream Key da Twitch](#04---obtendo-a-stream-key-da-twitch)**
5. **[05 - Transmitindo com FFmpeg](#05---transmitindo-com-ffmpeg)**
6. **[06 - Mantendo o Processo Ativo (Screen ou Systemd)](#06---mantendo-o-processo-ativo-screen-ou-systemd)**
7. **[07 - Solução Alternativa: Usando Docker](#07---solu%C3%A7%C3%A3o-alternativa-usando-docker)**
8. **[08 - Créditos e Referências](#08---cr%C3%A9ditos-e-refer%C3%AAncias)**

---

## 01 - Contratando o VPS

Existem várias opções no mercado brasileiro com preços acessíveis. Escolha um plano com Linux (Ubuntu 22.04 ou 24.04) e que ofereça acesso root.

### **Recomendações:**

- **KingHost**
  - Planos a partir de R$ 29/mês.
  - Servidores 100% no Brasil.
  - Acesso root completo.
  - Pagamento em reais.
  - [Site Oficial](https://king.host)

- **ExpressVPS**
  - Planos a partir de R$ 72/mês.
  - Performance com NVME M.2.
  - Datacenter em Turmalina - SP.
  - [Site Oficial](https://expressvps.com.br)

- **Locaweb**
  - Planos a partir de R$ 15,90/mês.
  - [Site Oficial](https://www.locaweb.com.br)

### **O que observar na hora da compra:**
- **Tráfego de rede**: Verifique se é ilimitado ou se há franquia generosa. Uma stream 24/7 consome muitos dados.
- **Sistema Operacional**: Escolha **Ubuntu 22.04** ou **24.04** (as mais amigáveis para iniciantes).
- **Armazenamento**: Pelo menos 20GB para o sistema e alguns vídeos.
- **CPU/RAM**: 2 vCPUs e 2GB de RAM é suficiente para começar.

---

## 02 - Conectando ao Servidor via SSH

Após contratar o VPS, você receberá um e-mail com:

- **IP do servidor** (ex: `123.456.78.90`)
- **Usuário**: geralmente `root`
- **Senha** ou chave SSH.

### **Passo a passo (Windows):**
1. Baixe e instale o **PuTTY** (ferramenta gratuita de acesso remoto).
2. Abra o PuTTY e no campo "Host Name" cole o IP do seu servidor.
3. Clique em "Open".
4. No terminal que abrir, digite o usuário `root` e pressione Enter.
5. Digite a senha fornecida (ela não aparecerá na tela) e pressione Enter.

### **Passo a passo (Mac/Linux):**
1. Abra o **Terminal**.
2. Digite o comando:
   ```bash
   ssh root@IP_DO_SEU_SERVIDOR
   ```
3. Digite `yes` para confirmar a conexão.
4. Digite a senha quando solicitado.

> **Dica**: Se quiser enviar arquivos do seu computador para o servidor, use o **WinSCP** (Windows) ou o comando `scp` (Mac/Linux).

---

## 03 - Instalando o FFmpeg

Com o terminal conectado ao servidor, vamos instalar o FFmpeg.

### **Atualize os pacotes do sistema:**
```bash
sudo apt update && sudo apt upgrade -y
```

### **Instale o FFmpeg:**
```bash
sudo apt install ffmpeg -y
```

### **Verifique a instalação:**
```bash
ffmpeg -version
```
Se aparecer a versão do FFmpeg, a instalação foi bem-sucedida.

### **Crie uma pasta para os vídeos:**
```bash
mkdir -p /home/videos
```

Agora, envie o arquivo de vídeo (formato `.mp4`) para essa pasta. Você pode usar o WinSCP ou o comando `scp`:

```bash
scp caminho/do/video.mp4 root@IP_DO_SERVIDOR:/home/videos/
```

---

## 04 - Obtendo a Stream Key da Twitch

A Stream Key é como uma senha que autoriza seu servidor a transmitir para seu canal.

1. Faça login no painel da **Twitch**.
2. Acesse o **Creator Dashboard**.
3. No menu lateral, vá em **Configurações → Stream**.
4. Clique em **"Copiar"** ao lado da **Primary Stream Key**.
5. **Guarde essa chave em um local seguro!** Nunca compartilhe publicamente.

---

## 05 - Transmitindo com FFmpeg

Agora vamos executar o comando que inicia a transmissão.

### **Comando básico:**
```bash
ffmpeg -re -stream_loop -1 -i "/home/videos/seu_video.mp4" -c copy -f flv rtmp://live.twitch.tv/app/SUA_STREAM_KEY
```

**Substitua:**
- `/home/videos/seu_video.mp4` pelo caminho real do vídeo.
- `SUA_STREAM_KEY` pela Stream Key que você copiou.

### **Explicação do comando:**
| Parâmetro          | O que faz                                                                 |
|--------------------|---------------------------------------------------------------------------|
| `-re`              | Lê o arquivo na velocidade original (essencial para lives).              |
| `-stream_loop -1`  | Repete o vídeo em **loop infinito** (o número `-1` significa para sempre). |
| `-i`               | Define o arquivo de entrada (seu vídeo).                                 |
| `-c copy`          | Copia os codecs de vídeo e áudio sem re-encode (mais rápido e leve).     |
| `-f flv`           | Define o formato de saída como FLV (padrão para RTMP).                   |
| `rtmp://...`       | Endereço do servidor RTMP da Twitch com sua Stream Key.                  |

> **Atenção**: Esse comando, sozinho, será interrompido se você fechar o terminal. Vamos resolver isso no próximo passo.

---

## 06 - Mantendo o Processo Ativo (Screen ou Systemd)

Para que o stream continue rodando 24/7 mesmo após fechar o terminal, você tem duas opções:

### **Opção 1: Usando Screen (Mais Simples)**

O Screen cria uma "sessão" que continua ativa em segundo plano.

1. **Instale o Screen:**
   ```bash
   sudo apt install screen -y
   ```

2. **Crie uma nova sessão:**
   ```bash
   screen -S twitch-stream
   ```
   (Você será levado para uma nova tela em branco)

3. **Dentro da sessão, execute o comando de stream:**
   ```bash
   ffmpeg -re -stream_loop -1 -i "/home/videos/seu_video.mp4" -c copy -f flv rtmp://live.twitch.tv/app/SUA_STREAM_KEY
   ```

4. **Saia da sessão sem interromper o processo:**
   - Pressione `Ctrl + A`, depois `D`. Você voltará ao terminal normal.
   - O processo continua rodando em segundo plano.

5. **Para voltar à sessão (se precisar):**
   ```bash
   screen -r twitch-stream
   ```

6. **Para listar todas as sessões ativas:**
   ```bash
   screen -ls
   ```

### **Opção 2: Usando Systemd (Mais Robusta)**

O Systemd é o gerenciador de serviços do Linux. Você pode criar um serviço que inicia automaticamente com o servidor.

1. **Crie um arquivo de serviço:**
   ```bash
   sudo nano /etc/systemd/system/twitch-rerun.service
   ```

2. **Cole o conteúdo abaixo** (substitua o caminho do vídeo e a Stream Key):
   ```ini
   [Unit]
   Description=Twitch Rerun Service
   After=network.target

   [Service]
   Type=simple
   User=root
   ExecStart=/usr/bin/ffmpeg -re -stream_loop -1 -i "/home/videos/seu_video.mp4" -c copy -f flv rtmp://live.twitch.tv/app/SUA_STREAM_KEY
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

3. **Salve o arquivo** (`Ctrl + O`, Enter, `Ctrl + X`).

4. **Recarregue o Systemd:**
   ```bash
   sudo systemctl daemon-reload
   ```

5. **Inicie o serviço:**
   ```bash
   sudo systemctl start twitch-rerun
   ```

6. **Habilite o serviço para iniciar com o servidor:**
   ```bash
   sudo systemctl enable twitch-rerun
   ```

7. **Verifique se está rodando:**
   ```bash
   sudo systemctl status twitch-rerun
   ```

---

## 07 - Solução Alternativa: Usando Docker

Se você prefere uma abordagem ainda mais automatizada, existe um contêiner Docker que já faz tudo isso.

### **Repositório Recomendado:**
- **docker-ffmpeg-mp4-folder**: [https://github.com/simeononsecurity/docker-ffmpeg-mp4-folder](https://github.com/simeononsecurity/docker-ffmpeg-mp4-folder)

### **Como usar:**
1. **Instale o Docker no servidor:**
   ```bash
   sudo apt install docker.io -y
   ```

2. **Clone o repositório:**
   ```bash
   git clone https://github.com/simeononsecurity/docker-ffmpeg-mp4-folder.git
   cd docker-ffmpeg-mp4-folder
   ```

3. **Construa a imagem:**
   ```bash
   docker build -t mp4-streamer .
   ```

4. **Execute o contêiner com loop infinito:**
   ```bash
   docker run -td --restart unless-stopped \
     -v /home/videos:/videos \
     -e TWITCH_STREAM_KEY=SUA_STREAM_KEY \
     -e LOOP_INDEFINITELY=true \
     mp4-streamer
   ```

O contêiner já gerencia o loop e a reinicialização automática.

---

## 08 - Créditos e Referências

- **Tutorial criado por:** DeepSeek
- **Projeto para:** lbzconsultoria (Mimimifu)
- **Repositório original:** [https://github.com/Mimimifu/Tutorials](https://github.com/Mimimifu/Tutorials)

### **Referências úteis:**
- Documentação oficial do FFmpeg: [https://ffmpeg.org/documentation.html](https://ffmpeg.org/documentation.html)
- Guia de streaming da Twitch: [https://help.twitch.tv/s/article/broadcast-guidelines](https://help.twitch.tv/s/article/broadcast-guidelines)
- Dúvidas? Consulte a comunidade: [Reddit r/ffmpeg](https://www.reddit.com/r/ffmpeg/)

---

## 📞 Suporte

Se você encontrar problemas, verifique:

1. Se o vídeo está no formato `.mp4` e em um local acessível.
2. Se a Stream Key está correta (geralmente começa com `live_`).
3. Se o servidor tem tráfego de rede disponível (planos muito baratos podem ter franquia baixa).

**Agora é só executar e curtir o rerun 24/7!** 🚀

```

---

### Como usar:

1. **Crie uma pasta no seu repositório** no GitHub, por exemplo `Tutorials`.
2. Dentro dela, crie um arquivo chamado `README.md` e cole todo o conteúdo acima.
3. (Opcional) Se quiser separar em vários arquivos, você pode quebrar cada seção em arquivos como `01-contratando-vps.md`, `02-conectando-ssh.md`, etc., e usar links no `README.md` apontando para eles. O tutorial acima foi escrito para ser **autossuficiente em um único arquivo**, facilitando a leitura.

Pronto! Agora é só enviar o link do GitHub para sua conhecida. Ela terá um material completo, didático e em português. 🚀
