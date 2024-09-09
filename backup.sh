#!/bin/bash
set -e
# Questo script cifra e carica tutti i file in una cartella su un bucket S3
# I file vengono cifrati con GPG e caricati su S3 con l'utility AWS CLI
# I file vengono caricati con la stessa struttura di cartelle della cartella locale
# I file vengono verificati dopo il caricamento con un checksum SHA256, utile per capire se il file è stato modificato durante il trasferimento
# e che quindi il file remoto corrisponda al file locale
#
# Requisiti:
# - AWS CLI
# - GPG
# - Un file chiave per la cifratura ( leggere il commento sotto per generare il file chiave )
# - Un bucket S3 con le credenziali configurate in AWS CLI
# - Un file di configurazione config.sh con le variabili BUCKET_ENDPOINT_URL, BUCKET_NAME, SUCCESS_FILE, FOLDER_TO_PROCESS, KEYFILE
#
# per creare il file chiave: 
# $ dd if=/dev/urandom bs=1024 count=1 | base64 | tr --delete '\n' > /var/cloud-backup/cloud.key



# lettura configurazione
pushd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
source ./config.sh
source ./functions.sh
popd &>/dev/null


if [ -z "$BUCKET_NAME" ]; then
    log "Specificare la variabile BUCKET_NAME nel file di configurazione"
    exit 1
fi

if [ -z "$SUCCESS_FILE" ]; then
    log "Specificare la variabile SUCCESS_FILE nel file di configurazione"
    exit 1
fi

if [ -z "$FOLDER_TO_PROCESS" ]; then
    log "Specificare la variabile FOLDER_TO_PROCESS nel file di configurazione"
    exit 1
fi

if [ -z "$KEYFILE" ]; then
    log "Specificare la variabile KEYFILE nel file di configurazione"
    exit 1
fi

if [ ! -d "$FOLDER_TO_PROCESS" ]; then
    log "La cartella $FOLDER_TO_PROCESS non esiste"
    exit 1
fi

# Verifica se il file chiave esiste
if [ ! -f "$KEYFILE" ]; then
    log "Generazione del file chiave '$KEYFILE' ..."
    dd if=/dev/urandom bs=1024 count=1 | base64 | tr --delete '\n' > "$KEYFILE"
fi

# Elabora tutti i file nella cartella
find "$FOLDER_TO_PROCESS" -type f | while read -r file; do
    encrypt_and_upload "$file"
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
touch "$SUCCESS_FILE"
