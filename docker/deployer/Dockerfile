FROM python:3.8-bullseye

# Packages
RUN apt update && \
    apt install -y \
    curl \
    gcc \
    git \
    net-tools \
    openssh-client \
    procps \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# terraform
RUN VERSION=1.0.10 && \
    wget https://releases.hashicorp.com/terraform/$VERSION/terraform_"$VERSION"_linux_amd64.zip && \
    unzip terraform_"$VERSION"_linux_amd64.zip -d /tmp/ && \
    mv /tmp/terraform /usr/local/bin/ && \
    rm -f terraform_"$VERSION"_linux_amd64.zip
