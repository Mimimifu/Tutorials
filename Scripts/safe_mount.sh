#!/bin/bash
set -u

###################################################################
# SCRIPT DE MONTAGEM SEGURO COM VERIFICAÇÃO DE DEPENDÊNCIAS
# SUPORTA: EXT2/3/4, NTFS, FAT32, exFAT
# GERA LOG AUTOMÁTICO, REPARA SE NECESSÁRIO E MONTA DE FORMA SEGURA
###################################################################

LOGFILE="$(dirname "$0")/log_mount_error.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

DEVICE="${1:-}"
MOUNT_POINT="${2:-}"

# --- ADICIONE ESTE BLOCO AQUI ---
# Se o argumento começar com UUID=, resolve para o caminho do dispositivo
if [[ "$DEVICE" == UUID=* ]]; then
    UUID_VAL=${DEVICE#UUID=}
    RESOLVED_DEVICE=$(blkid -U "$UUID_VAL")
    if [ -z "$RESOLVED_DEVICE" ]; then
        log "ERRO: Não foi possível encontrar dispositivo com UUID $UUID_VAL"
        exit 1
    fi
    DEVICE="$RESOLVED_DEVICE"
fi
# --------------------------------

# Se o argumento for apenas o código do UUID (sem o prefixo UUID=)
if [[ ! "$DEVICE" == /dev/* ]] && [ ${#DEVICE} -gt 10 ]; then
    RESOLVED_DEVICE=$(blkid -U "$DEVICE")
    if [ -n "$RESOLVED_DEVICE" ]; then
        DEVICE="$RESOLVED_DEVICE"
    fi
fi

#------------------------#
#   VALIDAR EXECUÇÃO    #
#------------------------#

if [ "$EUID" -ne 0 ]; then
  echo "Erro: Execute com sudo ou como root."
  exit 1
fi

if [ -z "$DEVICE" ] || [ -z "$MOUNT_POINT" ]; then
  echo "Uso: $0 /dev/sdXN /mnt/ponto"
  exit 1
fi

if [ ! -b "$DEVICE" ]; then
  log "ERRO: Dispositivo $DEVICE não existe."
  exit 1
fi

#------------------------#
#   VERIFICAR UTILITÁRIOS
#------------------------#

check_dep() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERRO: O utilitário '$1' não está instalado."
    return 1
  fi
  return 0
}

#------------------------#
#   DETECTAR FS TYPE     #
#------------------------#

FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || echo "")

if [ -z "$FS_TYPE" ]; then
  log "ERRO: Não foi possível detectar o filesystem do dispositivo."
  exit 1
fi

log "Filesystem detectado: $FS_TYPE"

#------------------------#
#   FUNÇÃO PARA MONTAR   #
#------------------------#

attempt_mount() {
  mkdir -p "$MOUNT_POINT"

  if mount "$DEVICE" "$MOUNT_POINT" 2>>"$LOGFILE"; then
    echo "Montado com sucesso em $MOUNT_POINT."
    df -h "$MOUNT_POINT"
    return 0
  else
    log "FALHA ao montar $DEVICE em $MOUNT_POINT."
    return 1
  fi
}

#------------------------#
#  SE JÁ ESTIVER MONTADO #
#------------------------#

if mountpoint -q "$MOUNT_POINT"; then
  echo "$DEVICE já está montado em $MOUNT_POINT."
  exit 0
fi

echo "Tentando montar $DEVICE..."

# PRIMEIRA TENTATIVA
if attempt_mount; then
  exit 0
fi

log "Montagem falhou. Iniciando reparo..."

#------------------------#
#  TENTAR REPARAR O FS   #
#------------------------#

case "$FS_TYPE" in
  ext2|ext3|ext4)
    check_dep fsck || { log "fsck ausente. Não é possível reparar ext4."; exit 1; }

    log "Executando fsck -y em $DEVICE..."
    if fsck -y "$DEVICE" >>"$LOGFILE" 2>&1; then
      log "fsck concluído."
    else
      log "ERRO: fsck falhou."
    fi
    ;;

  ntfs)
    check_dep ntfsfix || { log "ntfsfix ausente. Instale com: apt install ntfs-3g"; exit 1; }

    log "Executando ntfsfix em $DEVICE..."
    if ntfsfix "$DEVICE" >>"$LOGFILE" 2>&1; then
      log "ntfsfix concluído."
    else
      log "ERRO: ntfsfix falhou."
    fi
    ;;

  vfat|fat32|fat)
    check_dep fsck.vfat || { log "fsck.vfat não encontrado."; exit 1; }

    log "Executando fsck.vfat -a em $DEVICE..."
    if fsck.vfat -a "$DEVICE" >>"$LOGFILE" 2>&1; then
      log "fsck.vfat concluído."
    else
      log "ERRO: fsck.vfat falhou."
    fi
    ;;

  exfat)
    check_dep fsck.exfat || { log "fsck.exfat não encontrado."; exit 1; }

    log "Executando fsck.exfat em $DEVICE..."
    if fsck.exfat "$DEVICE" >>"$LOGFILE" 2>&1; then
      log "fsck.exfat concluído."
    else
      log "ERRO: fsck.exfat falhou."
    fi
    ;;

  *)
    log "ERRO: Filesystem '$FS_TYPE' não suportado automaticamente."
    exit 1
    ;;
esac

#------------------------#
# SEGUNDA TENTATIVA DE MONTAGEM
#------------------------#

log "Tentando montar novamente após reparo..."

if attempt_mount; then
  echo "Montado com sucesso após reparo."
  exit 0
fi

log "FALHA CRÍTICA: Mesmo após reparo, o dispositivo não pôde ser montado."
log "Encerrando operação."

exit 1
