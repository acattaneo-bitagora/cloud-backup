
AWS_ENDPOINT_URL="https://s3.bitagoraorobica.cubbit.eu"
# TODO: usare AWS_ENDPOINT_URL_S3
AWS_ACCESS_KEY_ID="<access-key>"
AWS_SECRET_ACCESS_KEY="<secret-key>"
BUCKET_NAME="<bucket-name>"

SUCCESS_FILE="/var/cloud-backup/success"
FOLDER_TO_PROCESS="/var/lib/vz/dump/"
KEYFILE="/var/cloud-backup/cloud.key"
LOG_FILE="/var/cloud-backup/cloud-backup.log"
CHECKSUM_COMMAND="sha256sum"

# export DEBUG_DIR="./debug"

export AWS_ENDPOINT_URL
export BUCKET_NAME
export SUCCESS_FILE
export KEYFILE
export LOG_FILE
export CHECKSUM_COMMAND
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export FOLDER_TO_PROCESS