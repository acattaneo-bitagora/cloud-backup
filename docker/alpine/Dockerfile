FROM alpine:latest

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        gpg \
        jq \
        pv

WORKDIR /tmp

# Install aws-cli
RUN --mount=type=cache,target=/var/cache/apk \
    set -x && \
    apk add --no-cache \
        curl \
        unzip \
    && \
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    apk del \
        curl \
        unzip

ADD . /opt/backup-cloud

RUN touch /opt/backup-cloud/config.sh

WORKDIR /opt/backup-cloud

ENTRYPOINT ["/opt/backup-cloud/backup.sh"]
