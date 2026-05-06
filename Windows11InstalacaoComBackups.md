Se possivel use discos e HDs e SSDs separados para maxima segurança dos dados.

Aqui está um README simples, direto, e que reflete **exatamente** o fluxo que você usou para criar sua imagem de ouro do Windows 11, compactá-la, restaurá-la no NVMe e deixar o sistema no estado "pré-configuração" (OOBE).

O texto está em português (padrão do seu GitHub), com comandos e explicações para quem quiser reproduzir.

---

## 🐧 Windows 11 Golden Image: QEMU → RAW → Deploy Físico

**Resumo:** Instale o Windows 11 em uma VM (QEMU/KVM), converta a imagem para RAW, compacte (`xz`), e restaure em uma máquina física. O sistema inicia na tela de configuração regional (OOBE), sem drivers específicos da VM – pronto para deploy.

### ✅ Pré-requisitos

- **Linux** (Debian/Ubuntu) com `qemu-kvm`, `libvirt`, `virt-manager` (opcional).  
- **Espaço em disco** para a imagem RAW (~64 GB) e para o `.xz` compactado (~8-12 GB).  
- **NVMe/SSD de destino** (no PC físico) com pelo menos 64 GB (recomendo 128 GB para folga).

---

### 1. Instalar o Windows 11 na VM (QEMU)

```bash
# Criar disco QCOW2 (64 GB, dinâmico)
qemu-img create -f qcow2 windows.qcow2 64G

# Iniciar a VM com UEFI (OVMF), 4 GB de RAM, TPM virtual (opcional)
qemu-system-x86_64 \
  -enable-kvm -m 4096 -cpu host -smp 4 \
  -drive file=windows.qcow2,format=qcow2,if=virtio \
  -cdrom ~/Downloads/Win11_23H2_PortugueseBrazil_x64.iso \
  -bios /usr/share/qemu/OVMF.fd \
  -device intel-hda -device hda-duplex
```

> ⚠️ **IMPORTANTE:** Pare a instalação **assim que chegar na tela de seleção de país/idioma** (ou logo após). Não complete o OOBE. Esse estado "pré-configuração" é o que torna a imagem clonável.

### 2. Converter QCOW2 → RAW

```bash
qemu-img convert -f qcow2 -O raw windows.qcow2 windows.raw
```

### 3. Compactar o RAW (para armazenamento)

```bash
xz -z -9 -v -T 0 windows.raw
```

Agora você tem `windows.raw.xz` (~8-12 GB). Essa é sua **imagem ouro**.

---

### 4. Restaurar no NVMe (Máquina Física)

- **Com GUI:** Use o **GNOME Disks** (`gnome-disk-utility`).  
  Selecione o NVMe de destino → menu ⋮ → **Restaurar imagem de disco** → escolha `windows.raw.xz`.

- **Pelo terminal:**
  ```bash
  xz -d -c windows.raw.xz | sudo dd of=/dev/nvme0n1 bs=4M status=progress
  ```

> 🔁 Após restaurar, o NVMe conterá exatamente o conteúdo da VM: partição EFI, partição do Windows, tudo pronto para boot.

---

### 5. Primeiro Boot Físico (OOBE)

- Conecte o NVMe (se externo) ou reinicie o PC.  
- Entre na BIOS e configure o NVMe como primeiro dispositivo de boot.  
- O Windows iniciará na tela de **seleção de país/idioma**.  
- Complete a configuração (usuário, senha, privacidade).  
- O sistema instalará os drivers **do hardware real** (GPU, áudio, rede, etc.) automaticamente (via Windows Update).

**Pronto.** Você tem um Windows 11 limpo, instalado em hardware real, sem pendrive e sem intermediários.

---

### ✅ Dicas Pós-Restauração

- **Ative o Windows** com sua licença (se a imagem já foi ativada na VM, pode pedir ativação novamente).
- **Instale os drivers específicos** (especialmente GPU, chipset, rede) se o Windows Update não os encontrar.
- **Desative a hibernação** (`powercfg -h off`) e mova o `pagefile.sys` para outra partição (se desejar).
- **Configure separação de dados** (movendo `Users`, `Program Files`, etc. para outras unidades, se aplicável).

---

### ❌ Desvantagens / Cuidados

- **BitLocker:** Se ativado na VM, pode pedir a chave de recuperação no hardware real. Desative antes de clonar (`manage-bde -off C:`).
- **Drivers:** A primeira inicialização no hardware pode demorar um pouco (Windows detectando novos dispositivos).
- **Licença:** Pode ser necessário reativar o Windows (a imagem contém informações de hardware da VM).

---

### 🔧 Removendo a Imagem Após o Deploy

```bash
rm windows.qcow2 windows.raw windows.raw.xz
```

Mantenha apenas o `.xz` como backup (pode ser restaurado novamente em qualquer outro PC).

---

### 🧠 Filosofia do Método

> *“Separe o sistema dos dados. Isole a imagem da VM do hardware real. Tenha um ponto de restauração único e imutável.”*

Com essa técnica, você nunca mais precisará fazer uma instalação tradicional do Windows. Basta restaurar sua imagem ouro e pronto.

---

**Repositório:** (coloque o link do seu GitHub aqui)  
**Autor:** Centurião (e um assistente que aprendeu com ele).

Aqui está a **segunda parte** do README, já incorporando a sua estratégia avançada de **separação total do sistema** (`C:` de apenas 64 GB), a criação da conta de resgate (`svadminlocal` / `safe`), a **migração de todos os dados** para outra partição, e finalmente o **backup da partição do sistema** (e apenas dela) para restauração instantânea.

---

## 🧠 Windows 11: Arquitetura de Sistema Imune (64 GB + Dados Separados)

### Conceito

- **Partição do Sistema (`C:`)** : Apenas o Windows base + espaço reservado. **Tamanho fixo: 64 GB**. Nada de dados de usuário, programas ou pagefile moram aqui.  
- **Partição de Dados (`D:` ou `G:`)** : Tudo o que é do usuário (`Users`, `Program Files`, `ProgramData`, pagefile, caches).  
- **Conta de resgate (`svadminlocal`)** : Administrador local independente, usado para manutenção e para mover pastas.  
- **Backup da partição `C:`** : Imagem apenas do sistema, para restauração rápida (sem reinstalar tudo).

Esse modelo torna o Windows **imune** a corrupção de dados e a reinstalações completas.

---

## 🗺️ Passo a Passo (Após a Restauração da Imagem Ouro)

### 1. Criação da Partição de Sistema de 64 GB

Durante o **deploy da imagem ouro** (restauração do `.raw.xz` no NVMe), a partição já terá o tamanho original (64 GB se você criou o QCOW2 com esse tamanho). Se quiser redimensionar (aumentar), use o **GNOME Disks** ou `gparted` antes do primeiro boot.

> 💡 A imagem ouro **não deve ultrapassar 64 GB**. Se você criou o QCOW2 com 64 GB, a partição terá esse tamanho após a restauração.

---

### 2. Configurar o Windows (OOBE)

- Após a restauração, ligue o PC.
- Use uma conta local (desconecte a internet para forçar a opção).

---

### 3. Criar a Conta de Resgate (`svadminlocal` / `safe`)

Logado como `svlocal`, abra o **PowerShell como Administrador** (Win+X → Terminal (Admin)) e execute:

```powershell
manage-bde -off C:
```
Aguarde descriptografia da unidade se estiver criptografada ...

```powershell
manage-bde -status
```

Complete a OOBE (crie seu usuário principal – ex: `svlocal`, senha qualquer).  

```powershell
net user svadminlocal 1234 /add
net localgroup administrators svadminlocal /add
```

Agora você tem uma conta de contingência (`svadminlocal`). **Teste o login** (faça logout e entre como `svadminlocal`/`1234`).

---

### 4. Mover **TUDO** para a Partição de Dados (`G:`)

> ⚠️ **Faça esses passos logado como `svadminlocal`** (para evitar arquivos travados do `svlocal`).

#### 4.1 Preparar o destino (`G:`)

```powershell
mkdir G:\Usuarios
mkdir G:\Programas
mkdir G:\ProgramData
mkdir G:\pagefile
```

#### 4.2 Mover a pasta `Users` (do `svlocal`)

```powershell
# Copiar mantendo permissões
robocopy "C:\Users\svlocal" "G:\Usuarios\svlocal" /mir /copyall /r:0 /w:0

# Deletar a original
rmdir /s /q "C:\Users\svlocal"

# Criar junction (link)
mklink /J "C:\Users\svlocal" "G:\Usuarios\svlocal"
```

#### 4.3 Mover `Program Files` e `Program Files (x86)`

```powershell
# Program Files 64-bit
robocopy "C:\Program Files" "G:\Programas\Program Files" /mir /copyall /r:0 /w:0
rmdir /s /q "C:\Program Files"
mklink /J "C:\Program Files" "G:\Programas\Program Files"

# Program Files 32-bit
robocopy "C:\Program Files (x86)" "G:\Programas\Program Files (x86)" /mir /copyall /r:0 /w:0
rmdir /s /q "C:\Program Files (x86)"
mklink /J "C:\Program Files (x86)" "G:\Programas\Program Files (x86)"
```

#### 4.4 Mover `ProgramData`

```powershell
robocopy "C:\ProgramData" "G:\ProgramData" /mir /copyall /r:0 /w:0
rmdir /s /q "C:\ProgramData"
mklink /J "C:\ProgramData" "G:\ProgramData"
```

#### 4.5 Mover o pagefile.sys

- Win+ R → `sysdm.cpl` → Avançado → Desempenho (Configurações) → Avançado → Memória Virtual → Alterar.  
- Remova o pagefile do `C:` (selecione "Sem arquivo de paginação").  
- Adicione um pagefile no `G:` (ex: tamanho gerenciado pelo sistema ou fixo – 8 GB, 16 GB).  
- Reinicie.

#### 4.6 Desligar a hibernação (libera espaço no `C:`)

```powershell
powercfg -h off
```

---

### 5. Verificação Final e Limpeza

- **Logout do `svadminlocal`** e **login como `svlocal`**.  
- Verifique se os links simbólicos estão funcionando:
  ```cmd
  dir C:\Users
  dir C:\Program Files
  dir C:\ProgramData
  ```
  Você deve ver `<JUNCTION>` ao lado das pastas movidas.

- Use o **WinDirStat** (ou `compact.exe`) para verificar o espaço no `C:`.  
  - **Esperado:** Menos de 35 GB ocupados, pelo menos 25 GB livres.

- Registro que vai mudar os arquivos dos instaladores para nova partição !
 
auto_reg.reg

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion]
"ProgramFilesDir"="G:\\Programas\\Program Files"
"ProgramFilesDir (x86)"="G:\\Programas\\Program Files (x86)"
"ProgramW6432Dir"="G:\\Programas\\Program Files"

[HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion]
"ProgramFilesDir"="G:\\Programas\\Program Files (x86)"
"ProgramFilesDir (x86)"="G:\\Programas\\Program Files (x86)"
"ProgramW6432Dir"="G:\\Programas\\Program Files"
```



- **Delete o perfil `svadminlocal`?** Não – mantenha como contingência. Use apenas quando necessário.

---

## 💾 Backup da Partição do Sistema (64 GB)

Após mover todos os dados para `G:`, a partição `C:` contém **apenas o Windows base, drivers e o espaço reservado**. Você pode fazer backup **apenas dela**, sem os dados.

### Método 1 – Via GNOME Disks (Linux)

- Boot por um pendrive Linux (Ventoy).  
- Use o GNOME Disks para criar uma **imagem da partição `C:`** (não do disco inteiro).  
- Compacte com `xz` (opcional).  
- Guarde essa imagem em um HD externo ou no próprio `G:` (como `windows_system.raw.xz`).

### Método 2 – Via Windows (nativo)

- Use `dism /Capture-Image`:
  ```cmd
  dism /Capture-Image /ImageFile:G:\backup\win11_system.wim /CaptureDir:C:\ /Name:"Windows base"
  ```
- Posteriormente, restaure com:
  ```cmd
  dism /Apply-Image /ImageFile:G:\backup\win11_system.wim /Index:1 /ApplyDir:C:\
  ```

### Vantagem

- **Backup pequeno** (10-20 GB, após compactação).  
- **Restauração rápida** (sem perder seus dados em `G:`).  
- **Ideal para testes** (você pode restaurar o sistema base quantas vezes quiser).

---

## ✅ Resumo do Modelo Final

| Componente | Local | Tamanho | Backup |
|-------------|-------|---------|--------|
| **Sistema base (Windows + drivers)** | `C:` | 64 GB | Imagem separada (`.wim` ou `.raw.xz`) |
| **Dados de usuário (`Users`)** | `G:\Usuarios` | Variável | Backup convencional |
| **Programas (`Program Files`)** | `G:\Programas` | Variável | Não precisa (reinstale se necessário) |
| **Dados compartilhados (`ProgramData`)** | `G:\ProgramData` | Variável | Backup opcional |
| **Arquivo de paginação (`pagefile.sys`)** | `G:\pagefile` | 8-16 GB | Não precisa |
| **Conta de resgate (`svadminlocal`)** | `C:\Users\svadminlocal` | Pequeno | Mantida localmente |

---

## 🧠 Filosofia

> *"O Windows precisa de apenas 64 GB. Tudo o resto é **dado**, e os dados não pertencem ao sistema."*

Com esse setup, você pode:

- Restaurar o Windows sem perder um arquivo sequer (basta restaurar a imagem do `C:`).  
- Expandir o `G:` à vontade.  
- Usar o `svadminlocal` como `safe` para manutenção.  
- Fazer backup **incremental** apenas dos dados (`G:`).

**Se o Windows pifar, você restaura a imagem do sistema em 10 minutos. Seus dados continuam intactos em `G:`.**

---

**Próximo passo:** (opcional) Automatizar a criação da imagem do sistema com um script PowerShell ou `dism`.  

**Repositório:** (coloque o link)  
**Autor:** Centurião – aquele que domou o Windows pela raiz. 🐧🚀💨
