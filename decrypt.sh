#!/bin/bash


pushd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
source ./config.sh
source ./functions.sh
popd &>/dev/null



if [ -z "$KEYFILE" ]; then
    log "Specificare la variabile KEYFILE nel file di configurazione"
    exit 1
fi

if [ ! -f "$KEYFILE" ]; then
    log "File chiave non trovato: '$KEYFILE'"
    exit 1
fi

if [ -z "$1" ]; then
    log "Specificare il file da cifrare come primo parametro"
    exit 1
fi

if [ ! -f "$1" ]; then
    log "Il file $1 non esiste"
    exit 1
fi

source_file="$1"

if [ -z "$2" ] ; then
    destination_file="${source_file}.gpg"
else
    destination_file="$2"
fi

decrypt < "$source_file" > "$destination_file"

