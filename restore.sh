#!/bin/bash

# Questo script decifra e ripristina tutti i file da un bucket S3
# I file vengono decifrati con GPG e scaricati da S3 con l'utility AWS CLI
# I file vengono scaricati con la stessa struttura di cartelle della cartella remota
# I file vengono scaricati in una cartella passata come primo parametro allo script

# Requisiti:
# - AWS CLI
# - GPG
# - Il file chiave per la cifratura
# - Un bucket S3 con le credenziali configurate in AWS CLI
# - Un file di configurazione config.sh con le variabili AWS_ENDPOINT_URL, BUCKET_NAME, KEYFILE

set -e

# lettura configurazione
pushd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
source ./config.sh
source ./functions.sh
popd &>/dev/null


# main 

# gestione dei parametri 
# usage: restore.sh [--override-if-exists] <destination_folder>
# --override-if-exists: se specificato, i file esistenti verranno sovrascritti
# destination_folder: cartella di destinazione dei file

# cicla i parametri
OVERRIDE_IF_EXISTS=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --override-if-exists)
            OVERRIDE_IF_EXISTS=1
            ;;
        *)
            DESTINATION_FOLDER="$1"
            ;;
    esac
    shift
done


# check parameters
if [ -z "$DESTINATION_FOLDER" ]; then
    log "Specificare la cartella di destinazione come primo parametro"
    exit 1
fi

mkdir -p "$DESTINATION_FOLDER"

# Scarica e decifra tutti i file
aws s3 ls --recursive "s3://$BUCKET_NAME" | while read -r line; do
    filename=$(echo "$line" | awk '{print $4}')
    if [ -z "$filename" ]; then
        continue
    fi
    destination_file="${DESTINATION_FOLDER%/}/${filename#/}"
    if [ -f "$destination_file" ] && [ "$OVERRIDE_IF_EXISTS" -eq 0 ]; then
        log "Il file $destination_file esiste già, salto il download"
        continue
    fi
    download_and_decrypt "$filename" "${destination_file%\.gpg}"
done
