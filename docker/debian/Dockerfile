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
    apt-get --no-install-recommends install -y \
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

# Tell cron what to log about jobs (errors are logged regardless of this value) as the sum of the following values:
#     1      will log the start of all cron jobs
#     2      will log the end of all cron jobs
#     4      will log all failed jobs (exit status != 0)
#     8      will log the process number of all cron jobs
# The default is to log the start of all jobs (1).  Logging will be disabled if levels is set to zero (0).  A value of fifteen (15) will select all options.
ENV LOG_LEVEL 15

ADD . /opt/backup-cloud

RUN set -x && \
    touch /opt/backup-cloud/config.sh && \
    chmod +x /opt/backup-cloud/backup.sh

WORKDIR /opt/backup-cloud

ENTRYPOINT ["/opt/backup-cloud/backup.sh"]
