FROM alpine:latest

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        gpg \
        jq \
        pv \
        aws-cli \
        bash

ENV AWS_ENDPOINT_URL=https://s3.bitagoraorobica.cubbit.eu
ENV AWS_ACCESS_KEY_ID=<access-key>
ENV AWS_SECRET_ACCESS_KEY=<secret-key>
ENV BUCKET_NAME=<bucket-name>
ENV SUCCESS_FILE=/var/cloud-backup/success
ENV FOLDER_TO_PROCESS=/data
ENV KEYFILE=/var/cloud-backup/cloud.key
ENV LOG_FILE=/var/cloud-backup/cloud-backup.log
ENV CHECKSUM_COMMAND=sha256sum
ENV SCHEDULE="0 0 * * *"
ENV BACKUP_ARGS=""
# MOST VERBOSE LOG LEVEL IS 0 - NORMAL IS 8
ENV LOG_LEVEL=0

ADD . /opt/backup-cloud

RUN set -x && \
    touch /opt/backup-cloud/config.sh && \
    chmod +x /opt/backup-cloud/backup.sh

VOLUME ["/var/cloud-backup", "/data"]

WORKDIR /opt/backup-cloud




COPY docker/alpine/entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
