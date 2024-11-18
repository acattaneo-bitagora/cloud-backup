#!/bin/bash
set -e
# Questo script cifra e carica tutti i file in una cartella su un bucket S3
# I file vengono cifrati con GPG e caricati su S3 con l'utility AWS CLI
# I file vengono caricati con la stessa struttura di cartelle della cartella locale
# I file vengono verificati dopo il caricamento con un checksum SHA256, utile per capire se il file è stato modificato durante il trasferimento
# e quindi verificare che il file remoto, una volta decriptato, corrisponda al file locale
#
# Requisiti:
# - AWS CLI
# - GPG
# - Un file chiave per la cifratura ( leggere il commento sotto per generare il file chiave )
# - Un bucket S3 con le credenziali configurate in AWS CLI
# - Un file di configurazione config.sh con le variabili AWS_ENDPOINT_URL, BUCKET_NAME, SUCCESS_FILE, FOLDER_TO_PROCESS, KEYFILE
#
# per creare il file chiave: 
# $ dd if=/dev/urandom bs=150 count=1 | base64 | tr -d '\n' > /var/cloud-backup/cloud.key


# lettura configurazione
pushd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
if [  -f ./config.sh ]; then
    source ./config.sh
fi
source ./functions.sh
popd &>/dev/null

MAX_UPLOAD_ATTEMPTS=${MAX_UPLOAD_ATTEMPTS:-10}

if [ -z "$BUCKET_NAME" ]; then
    log "Specificare la variabile BUCKET_NAME nel file di configurazione"
    exit 1
fi

if [ -z "$SUCCESS_FILE" ]; then
    log "Specificare la variabile SUCCESS_FILE nel file di configurazione"
    exit 1
fi

if [ -z "$KEYFILE" ]; then
    log "Specificare la variabile KEYFILE nel file di configurazione"
    exit 1
fi

if [ -n "$1" ]; then
    FOLDER_TO_PROCESS="$*"
fi

if [ -z "$FOLDER_TO_PROCESS" ]; then
    log "usage: $0 </directory/da/processare>"
    exit 1
fi

if [ ! -d "$FOLDER_TO_PROCESS" ]; then
    log "$FOLDER_TO_PROCESS: Il percorso non esiste"
    exit 1
fi

if [ -z "$UPLOAD_RATE_LIMIT" ]; then
    # Nessun limite di velocità configurato
    rate_limit=""
else
    if command -v pv &>/dev/null; then
        rate_limit="$UPLOAD_RATE_LIMIT"
    else
        log "Il comando 'pv' non è installato, non è possibile limitare la velocità di upload"
    fi
fi

# Verifica se il file chiave esiste
if [ ! -f "$KEYFILE" ]; then
    log "Generazione del file chiave '$KEYFILE' ..."
    generate_key
fi

# Elabora tutti i file nella cartella
find "$FOLDER_TO_PROCESS" -type f | while read -r file; do
    success=false
    
    for i in $(seq 1 $MAX_UPLOAD_ATTEMPTS); do
        if encrypt_and_upload "$file" "$rate_limit"; then
            success=true
            break
        else
            echo "Tentativo $i fallito per: $file"
            sleep 1
        fi
    done
    
    if [ "$success" = false ]; then
        echo "Impossibile caricare il file dopo $MAX_UPLOAD_ATTEMPTS tentativi: $file"
    fi
done

# Verifica tutti i file caricati
find "$FOLDER_TO_PROCESS" -type f | while read -r file; do
    log "Verifica di $file..."
    if verify_remote_file "$file"; then
        log "Verifica di $file completata con successo"
    else
        log "Errore durante la verifica di $file"
        exit 1
    fi
done

log "Operazione completata."
mkdir -p "$(dirname "$SUCCESS_FILE")"
touch "$SUCCESS_FILE"

log "Pulizia file non più presenti localmente..."
mirror_folder "$FOLDER_TO_PROCESS"

# ATTENZIONE: tutti i file sul bucket che sono più vecchi di $RETENTION_DAYS giorni vengono eliminati
if [ -n "$RETENTION_DAYS" ]; then
    clean_old_files "$RETENTION_DAYS"
fi
