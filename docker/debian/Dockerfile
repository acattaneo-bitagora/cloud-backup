FROM debian:bookworm-slim

# Install dependencies
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get -qq update && \
    apt-get install -y \
        gpg \
        jq \
        pv \
    && \
    apt-get clean

WORKDIR /tmp

# Install aws-cli
RUN --mount=type=cache,target=/var/lib/apt/lists \
    set -x && \
    apt-get -qq update && \
    apt-get install -y \
        curl \
        unzip \
    && \
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    # test aws-cli
    /usr/local/bin/aws --version && \
    apt-get remove -y \
        curl \
        unzip \
    && \
    apt-get clean


ENV AWS_ENDPOINT_URL="https://s3.bitagoraorobica.cubbit.eu"
ENV AWS_ACCESS_KEY_ID="<access-key>"
ENV AWS_SECRET_ACCESS_KEY="<secret-key>"
ENV BUCKET_NAME="<bucket-name>"
ENV SUCCESS_FILE="/var/cloud-backup/success"
ENV FOLDER_TO_PROCESS="/data"
ENV KEYFILE="/var/cloud-backup/cloud.key"
ENV LOG_FILE="/var/cloud-backup/cloud-backup.log"
ENV CHECKSUM_COMMAND="sha256sum"

VOLUME ["/var/cloud-backup", "/data"]

ADD . /opt/backup-cloud

RUN set -x && \
    touch /opt/backup-cloud/config.sh && \
    chmod +x /opt/backup-cloud/backup.sh

WORKDIR /opt/backup-cloud

ENTRYPOINT ["/opt/backup-cloud/backup.sh"]
