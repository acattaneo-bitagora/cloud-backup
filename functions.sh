# shellcheck disable=SC2148

# Semplice funzione per loggare un messaggio
# usage: log <message>
log() {
    log_dir="$(dirname "$LOG_FILE")"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}


# Funzione per caricare un singolo file su S3 da stdin
# usage: cat <filepath> | upload <filename>
#   filename: nome del file remoto
upload() {
    local filename="$1"
    # optional parameter rate limit
    local rate_limit=""
    if [ -n "$2" ]; then
        if command -v pv &>/dev/null; then
            rate_limit="$2"
        else
            log "Il comando 'pv' non è installato, non è possibile limitare la velocità di upload"
        fi
    fi
    local remote_filename="$BUCKET_NAME/${filename#/}"
    log "Caricamento di $filename su s3://$remote_filename..."
    {
        if [ -n "$rate_limit" ]; then
            pv  --average-rate --rate --rate-limit "$rate_limit" --progress >&3
        else
            cat - >&3
        fi
    } 3>&1 | aws s3 cp "-" "s3://$remote_filename"
    return $?
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
    log "Elaborazione di $local_filename..."
    local rate_limit=""
    if [ -n "$2" ]; then
        rate_limit="$2"
    fi
    if [ ! -f "$KEYFILE" ]; then
        log "File chiave non trovato: '$KEYFILE'"
        exit 1
    fi
    if [ -n "$DEBUG_DIR" ] ; then
        debug_filename="$DEBUG_DIR/upload/${local_filename}.gpg"
        mkdir -p "$(dirname "$debug_filename")"
        encrypt "$local_filename" > "${debug_filename}.gpg"
        decrypt < "${debug_filename}.gpg" > "$debug_filename"
    fi
    if encrypt "$local_filename" | upload "${local_filename}.gpg" "$rate_limit"; then
        log "File $local_filename cifrato con file chiave e caricato con successo"
    else
        log "Errore durante la cifratura o il caricamento di $local_filename"
        return 1
    fi
}


# Funzione per scaricare un singolo file da S3 
# usage: download <filename>
#   filename: nome del file remoto ( percorso file senza nome del bucket )
download() {
    local filename="$1"
    local remote_filename="$BUCKET_NAME/${filename#/}"
    if aws s3 cp "s3://$remote_filename" -; then
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

    local local_checksum
    local_checksum="$($CHECKSUM_COMMAND "$local_filename" | cut -d ' ' -f 1)"
    
    local remove_checksum
    remove_checksum="$(download "${local_filename}.gpg" | decrypt | $CHECKSUM_COMMAND | cut -d ' ' -f 1)"
    
    echo "$local_checksum == $remove_checksum"
    
    if [ "$local_checksum" == "$remove_checksum" ]; then
        return 0
    else
        if [ -n "$DEBUG_DIR" ] ; then
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
    
    local local_folder
    local_folder=$(dirname "$local_filename")
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
        if [ -n "$DEBUG_DIR" ] ; then
            debug_filename="$DEBUG_DIR/download/${local_filename}.gpg"
            mkdir -p "$(dirname "$debug_filename")"
            download "${remote_filename}" > "$debug_filename"
        fi
        return 1
    fi
}

clean_old_files() {
    local days="$1"
    aws s3api list-objects-v2 --bucket "$BUCKET_NAME" \
        --query "Contents[?LastModified<=\`$(date -d "-$days days" +%Y-%m-%dT%H:%M:%SZ)\`] | {Keys: []}" \
        --output json | jq -r ".Keys[].Key" | while read -r line; do
        log "Rimozione di $line"
        s3_object_key="s3://$BUCKET_NAME/${line%/}"
        aws s3 rm "$s3_object_key"
    done
}

mirror_folder() {
    local folder="${1#/}"
    # for each file in bucket that start with folder name, check if the file exists in local folder ( without the .gpg extension )
    # if not, remove the file from bucket
    aws s3api list-objects-v2 --bucket "$BUCKET_NAME" \
        --query "Contents[?starts_with(Key, \`$folder\`) == \`true\`] | {Keys: []}" \
        --output json | jq -r ".Keys[].Key" | while read -r line; do
        local_filename="/${line%.gpg}"
        s3_object_key="s3://$BUCKET_NAME/${line%/}"
        echo "s3_object_key: $s3_object_key"
        echo "local_filename: $local_filename"
        #if [ ! -f "$local_filename" ]; then
        #    log "Rimozione di $line"
        #    aws s3 rm "$s3_object_key"
        #fi
    done
}


generate_key() {
    mkdir -p "$(dirname "$KEYFILE")"
    dd if=/dev/urandom bs=150 count=1 | base64 | tr -d '\n' > "$KEYFILE"
}