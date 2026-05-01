#!/bin/bash

TARGET="$1"

log() {
  local msg="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a /var/log/safe-mount.log
}

if [[ "$TARGET" == UUID=* ]] || [[ ! "$TARGET" == /* && ${#TARGET} -gt 10 ]]; then
    UUID_VAL=${TARGET#UUID=}
    # Encontra o dispositivo associado ao UUID
    DEV_PATH=$(blkid -U "$UUID_VAL")
    
    if [ -n "$DEV_PATH" ]; then
        # Encontra onde esse dispositivo está montado atualmente
        MOUNT_PATH=$(findmnt -n -o TARGET --source "$DEV_PATH")
        if [ -n "$MOUNT_PATH" ]; then
            log "UUID $UUID_VAL resolvido para o ponto de montagem: $MOUNT_PATH"
            TARGET="$MOUNT_PATH"
        else
            log "AVISO: O dispositivo com UUID $UUID_VAL não parece estar montado."
            exit 0
        fi
    else
        log "ERRO: Não foi possível encontrar dispositivo com UUID $UUID_VAL"
        exit 1
    fi
fi

log "Verificando processos ativos em $TARGET..."
# Captura processos (ignora o próprio script e o grep)
BUSY_PROCS=$(lsof -t "$TARGET")

if [[ -n "$BUSY_PROCS" ]]; then
    echo "--- ATENÇÃO: A unidade está sendo usada pelos seguintes processos: ---"
    lsof +f -- "$TARGET"
    
    echo ""
    read -p "Deseja tentar encerrar esses processos automaticamente? (s/n): " choice
    if [[ "$choice" != "s" ]]; then
        log "Operação cancelada pelo usuário. Os processos acima ainda estão ativos."
        exit 1
    fi
    
    # Se o usuário aceitou, o script segue para o fuser -k que você já tem
    log "Usuário autorizou o encerramento dos processos."
fi


check_dep() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERRO: utilitário '$1' não encontrado no sistema."
    return 1
  fi
  return 0
}

detect_fs() {
  blkid -o value -s TYPE "$1"
}

sync_disks() {
  log "Sincronizando buffers..."
  sync
}

if [[ -z "$TARGET" ]]; then
  echo "Uso: safe_unmount.sh /dev/sdXN | /ponto/de/montagem"
  exit 1
fi

log "=== DESMONTANDO $TARGET ==="

sync_disks

# 1️⃣ Tentar desmontagem normal
log "Tentando desmontagem normal..."
if umount "$TARGET" 2>/dev/null; then
  log "Desmontado com sucesso."
  exit 0
fi

# 2️⃣ Encontrar processos travando
log "Falha. Verificando processos que estão usando o caminho..."
PROCS=$(lsof +f -- "$TARGET" 2>/dev/null)

if [[ -n "$PROCS" ]]; then
  log "Processos encontrados:"
  echo "$PROCS" | tee -a /var/log/safe-mount.log

  log "Matando processos..."
  fuser -k "$TARGET" 2>/dev/null
  sleep 1

  log "Tentando novamente..."
  if umount "$TARGET" 2>/dev/null; then
    log "Desmontado com sucesso após matar processos."
    exit 0
  fi
fi

# 3️⃣ Desmontagem forçada
log "Última tentativa: desmontagem forçada."
if umount -l "$TARGET" 2>/dev/null; then
  log "Desmontagem forçada bem-sucedida (lazy umount)."
  exit 0
fi

log "ERRO: Não foi possível desmontar $TARGET."
exit 1
