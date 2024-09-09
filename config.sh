#BUCKET_ENDPOINT_URL="https://s3.bitagoraorobica.cubbit.eu"
#BUCKET_NAME="bitagoraorobica-bucket-prova01"

BUCKET_ENDPOINT_URL=""
BUCKET_NAME="runme-sh-test"


SUCCESS_FILE="/var/cloud-backup/success"
# FOLDER_TO_PROCESS="/var/lib/vz/dump/"
FOLDER_TO_PROCESS="/var/prova"
KEYFILE="/var/cloud-backup/cloud.key"
LOG_FILE="/var/cloud-backup/cloud-backup.log"
CHECKSUM_COMMAND="sha256sum"

DEBUG_DIR="./debug"

export BUCKET_ENDPOINT_URL
export BUCKET_NAME
export SUCCESS_FILE
export FOLDER_TO_PROCESS
export KEYFILE
export LOG_FILE
export CHECKSUM_COMMAND
export DEBUG_DIR