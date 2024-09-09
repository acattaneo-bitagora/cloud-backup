#!/bin/bash
# Questo script cifra e carica tutti i file in una cartella su un bucket S3
# I file vengono cifrati con GPG e caricati su S3 con l'utility AWS CLI
# I file vengono caricati con la stessa struttura di cartelle della cartella locale
# I file vengono verificati dopo il caricamento con un checksum SHA256, utile per capire se il file è stato modificato durante il trasferimento
# e che quindi il file remoto corrisponda al file locale
#
# Requisiti:
# - AWS CLI
# - GPG
# - Un file chiave per la cifratura ( generabile con dd if=/dev/urandom bs=1024 count=1 | base64 > /var/cloud-backup/cloud.key )
# - Un bucket S3 con le credenziali configurate in AWS CLI
# - Un file di configurazione config.sh con le variabili BUCKET_ENDPOINT_URL, BUCKET_NAME, SUCCESS_FILE, FOLDER_TO_PROCESS, KEYFILE
#
set -e

## per creare il file chiave: 
## $ 

# lettura configurazione
pushd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.sh
popd

# Semplice funzione per loggare un messaggio
# usage: log <message>
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Funzione per caricare un singolo file su S3 da stdin
# usage: cat <filepath> | upload <filename>
#   filename: nome del file remoto
upload() {
    local filename="$1"
    local remote_filename="$BUCKET_NAME/${filename#/}"
    log "Caricamento di $filename su s3://$remote_filename..."
    if aws s3  --endpoint-url "$BUCKET_ENDPOINT_URL" cp "-" "s3://$remote_filename"; then
        return 0
    else
        return 1
    fi
}

# Funzione per cifrare e caricare un singolo file
# usage: encrypt_and_upload <local_filename>
#   local_filename: percorso del file locale
encrypt_and_upload() {
    local local_filename="$1"
    log "Elaborazione di $file..."
    
    if [ ! -f "$KEYFILE" ]; then
        log "File chiave non trovato: $KEYFILE"
        return 1
    fi
    if gpg --batch --yes --passphrase-file "$KEYFILE" --symmetric --output - "$local_filename" | upload "${local_filename}.gpg"; then
        log "File $local_filename cifrato con file chiave e caricato con successo"
    else
        log "Errore durante la cifratura o il caricamento di $file"
        return 1
    fi

}

# Funzione per verificare che il file remoto corrisponda al file locale
# usage: verify_remote_file <local_filename>
#   local_filename: percorso del file locale
verify_remote_file() {
    local local_filename="$1"
    local remote_filename="$BUCKET_NAME/${local_filename#/}.gpg"

    log "Verifica di $local_filename su s3://$remote_filename..."

    local local_checksum="$(sha256sum "$local_filename" | cut -d ' ' -f 1)"
    local remove_checksum="$(aws s3 --endpoint-url "$BUCKET_ENDPOINT_URL" cp "s3://${remote_filename}" - | gpg --batch --yes --passphrase-file "$KEYFILE" --decrypt | sha256sum | cut -d ' ' -f 1)"
    if [ "$local_checksum" == "$remove_checksum" ]; then
        return 0
    else
        return 1
    fi
}

# Verifica se la cartella esiste
if [ ! -d "$FOLDER_TO_PROCESS" ]; then
    log "La cartella $FOLDER_TO_PROCESS non esiste"
    exit 1
fi

# Elabora tutti i file nella cartella
find "$FOLDER_TO_PROCESS" -type f | while read -r file; do
    encrypt_and_upload "$file"
done

# Verifica tutti i file caricati
find "$FOLDER_TO_PROCESS" -type f | while read -r file; do
    log "Verifica di $file..."
    CHECKSUM=$(sha256sum "$file" | cut -d ' ' -f 1)
    if verify_remote_file "$file"; then
        log "Verifica di $file completata con successo"
    else
        log "Errore durante la verifica di $file"
        exit 1
    fi
done

log "Operazione completata."
touch "$SUCCESS_FILE"
