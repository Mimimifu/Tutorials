---

# Guia de Preparação de Disco (Interface de Recuperação)

Este documento descreve o procedimento de configuração de disco via **Command Prompt (CMD)** sem a necessidade de reinicialização do sistema, permitindo a continuidade da instalação do Windows através do ambiente de pré-instalação (WinPE).

---

## 1. Acesso ao Terminal

Caso esteja na tela de instalação do Windows:

1. Pressione **Shift + F10** no teclado.
2. O prompt de comando será aberto.

## 2. Preparação do Disco (Via Diskpart)

Utilize o utilitário `diskpart` para limpar e formatar o disco para o padrão MBR (necessário para placas-mãe em modo Legacy/CSM).

Execute os comandos abaixo sequencialmente:

```cmd
diskpart
list disk
select disk X        # Substitua 'X' pelo número do seu disco (ex: 0)
clean                # ATENÇÃO: Isso apaga todos os dados do disco
convert mbr          # Define o estilo de partição como MBR
create partition primary
format fs=ntfs quick
assign
exit

```

## 3. Reiniciando o Instalador sem Reboot

Se a tela de instalação não reconhecer as alterações, force a execução do `setup.exe` a partir da unidade onde o instalador está contido.

1. Identifique a letra da unidade da sua pen drive:
```cmd
wmic logicaldisk get caption, volumename

```



```
2. Execute o instalador (substitua `E:` pela letra encontrada):
   ```cmd
   E:\sources\setup.exe

```

---

## 4. Finalização

* Após a execução do comando, a interface gráfica do instalador voltará a ser exibida.
* Na tela de seleção de disco, clique em **"Atualizar" (Refresh)**.
* Selecione o volume criado e clique em **Avançar** para prosseguir com a cópia dos arquivos.

---

> **Nota de Referência:** Procedimento técnico consolidado para recuperação de ambiente e continuidade de deploy.
> *Gerado com suporte técnico do Gemini.*

---

### Dica para o Usuário:

* **`list disk`**: Confirme sempre se o disco escolhido é o correto antes de rodar o `clean`.
* **`convert mbr`**: Utilizado em hardware que não suporta o padrão UEFI/GPT.
* **`sources\setup.exe`**: O caminho padrão dentro de imagens ISO montadas para reiniciar a interface do usuário.
