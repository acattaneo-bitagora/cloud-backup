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
    apt-get remove -y \
        curl \
        unzip \
    && \
    apt-get clean

ADD . /opt/backup-cloud

RUN touch /opt/backup-cloud/config.sh

WORKDIR /opt/backup-cloud

ENTRYPOINT ["/opt/backup-cloud/backup.sh"]
