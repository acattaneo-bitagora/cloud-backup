# Semplice funzione per loggare un messaggio
# usage: log <message>
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}


aws_s3_cmd() {
    if [ -z "$AWS_ENDPOINT_URL" ]; then
        if aws s3 "$@" ; then
            return 0
        else
            return 1
        fi
    else
        if aws s3 --endpoint-url "$AWS_ENDPOINT_URL" "$@" ; then
            return 0
        else
            return 1
        fi
    fi
}

# Funzione per caricare un singolo file su S3 da stdin
# usage: cat <filepath> | upload <filename>
#   filename: nome del file remoto
upload() {
    local filename="$1"
    local remote_filename="$BUCKET_NAME/${filename#/}"
    log "Caricamento di $filename su s3://$remote_filename..."
    if aws_s3_cmd cp "-" "s3://$remote_filename" ; then
        return 0
    else
        return 1
    fi
}

encrypt() {
    local local_filename="$1"
    gpg --batch --yes --pinentry-mode loopback --cipher-algo AES256 --passphrase-file "$KEYFILE" --symmetric --output - "$local_filename"
}

decrypt() {
    gpg --batch --yes --pinentry-mode loopback --passphrase-file "$KEYFILE" --decrypt --output - 
}

# Funzione per cifrare e caricare un singolo file
# usage: encrypt_and_upload <local_filename>
#   local_filename: percorso del file locale
encrypt_and_upload() {
    local local_filename="$1"
    log "Elaborazione di $file..."
    
    if [ ! -f "$KEYFILE" ]; then
        log "File chiave non trovato: '$KEYFILE'"
        exit 1
    fi
    if [ ! -z "$DEBUG_DIR" ] ; then
        debug_filename="$DEBUG_DIR/upload/${local_filename}.gpg"
        mkdir -p "$(dirname "$debug_filename")"
        encrypt "$local_filename" > "${debug_filename}.gpg"
        cat "${debug_filename}.gpg" | decrypt > "$debug_filename"
    fi
    if encrypt "$local_filename" | upload "${local_filename}.gpg"; then
        log "File $local_filename cifrato con file chiave e caricato con successo"
    else
        log "Errore durante la cifratura o il caricamento di $file"
        return 1
    fi
}


# Funzione per scaricare un singolo file da S3 
# usage: download <filename>
#   filename: nome del file remoto ( percorso file senza nome del bucket )
download() {
    local filename="$1"
    local remote_filename="$BUCKET_NAME/${filename#/}"
    if aws_s3_cmd cp "s3://$remote_filename" -; then
        return 0
    else
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

    local local_checksum="$($CHECKSUM_COMMAND "$local_filename" | cut -d ' ' -f 1)"
    local remove_checksum="$(download "${local_filename}.gpg" | decrypt | $CHECKSUM_COMMAND | cut -d ' ' -f 1)"
    echo "$local_checksum == $remove_checksum"
    if [ "$local_checksum" == "$remove_checksum" ]; then
        return 0
    else
        if [ ! -z "$DEBUG_DIR" ] ; then
            debug_filename="$DEBUG_DIR/download/${local_filename}.gpg"
            mkdir -p "$(dirname "$debug_filename")"
            download "${local_filename}.gpg" > "$debug_filename"
        fi
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
    if download "${remote_filename}" | decrypt > "$local_filename"; then
        log "File $remote_filename decifrato con file chiave e scaricato con successo"
    else
        log "Errore durante la decifratura o il scaricamento di $remote_filename"
        if [ ! -z "$DEBUG_DIR" ] ; then
            debug_filename="$DEBUG_DIR/download/${local_filename}.gpg"
            mkdir -p "$(dirname "$debug_filename")"
            download "${remote_filename}" > "$debug_filename"
        fi
        return 1
    fi
}