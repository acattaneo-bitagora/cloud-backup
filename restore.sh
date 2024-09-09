#!/bin/bash

# Questo script decifra e ripristina tutti i file in una cartella da un bucket S3
# I file vengono decifrati con GPG e scaricati da S3 con l'utility AWS CLI
# I file vengono scaricati con la stessa struttura di cartelle della cartella remota
# I file vengono scaricati in una cartella passata come primo parametro allo script

# Requisiti:
# - AWS CLI
# - GPG
# - Il file chiave per la cifratura
# - Un bucket S3 con le credenziali configurate in AWS CLI
# - Un file di configurazione config.sh con le variabili BUCKET_ENDPOINT_URL, BUCKET_NAME, KEYFILE

set -e

# lettura configurazione
pushd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.sh
popd

# Semplice funzione per loggare un messaggio
# usage: log <message>
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Funzione per scaricare un singolo file da S3
# usage: download <filename>
#   filename: nome del file remoto
download() {
    local filename="$1"
    local remote_filename="$BUCKET_NAME/${filename#/}"
    log "Scaricamento di s3://$remote_filename ..."
    if aws s3 --endpoint-url "$BUCKET_ENDPOINT_URL" cp "s3://$remote_filename" -; then
        return 0
    else
        return 1
    fi
}

# Funzione scaricare e decriptare un singolo file
# usage: download_and_decrypt <remote_filename> <local_filename>
#   remote_filename: percorso del file remoto
#   local_filename: percorso del file locale
download_and_decrypt() {
    local remote_filename="$1"
    local local_filename="$2"
    local local_folder=$(dirname "$local_filename")
    mkdir -p "$local_folder"
    log "Elaborazione di $remote_filename > $local_filename ..."
    
    if [ ! -f "$KEYFILE" ]; then
        log "File chiave non trovato: $KEYFILE"
        return 1
    fi
    if download "${remote_filename}" | gpg --batch --yes  --pinentry-mode loopback --passphrase-file "$KEYFILE" --decrypt --output "$local_filename"; then
        log "File $remote_filename decifrato con file chiave e scaricato con successo"
    else
        log "Errore durante la decifratura o il scaricamento di $remote_filename"
        download "${remote_filename}" > "${local_filename}.gpg"
        return 1
    fi
}

# main 
DESTINATION_FOLDER="$@"

# check parameters
if [ -z "$DESTINATION_FOLDER" ]; then
    log "Specificare la cartella di destinazione come primo parametro"
    exit 1
fi

mkdir -p "$DESTINATION_FOLDER"

# Scarica e decifra tutti i file
aws s3 --endpoint-url "$BUCKET_ENDPOINT_URL" ls  --recursive "s3://$BUCKET_NAME" | while read -r line; do
    filename=$(echo "$line" | awk '{print $4}')
    if [ -z "$filename" ]; then
        continue
    fi
    destination_file="${DESTINATION_FOLDER%/}/${filename#/}"
    download_and_decrypt "$filename" "${destination_file%\.gpg}"
done
