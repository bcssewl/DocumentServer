FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=18.x

# Install base dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    gnupg \
    locales \
    lsb-release \
    apt-transport-https \
    apt-utils \
    nano \
    vim \
    net-tools \
    unzip \
    xxd \
    sudo \
    # Build tools
    build-essential \
    cmake \
    gdb \
    make \
    pkg-config \
    autoconf \
    automake \
    libtool \
    # Java (for Closure Compiler)
    default-jre \
    default-jdk \
    # Services
    nginx \
    supervisor \
    postgresql-client \
    # Development libraries
    libicu-dev \
    libcurl4-openssl-dev \
    libcurl4 \
    libxml2-dev \
    libxml2 \
    libxslt1-dev \
    libssl-dev \
    libboost-all-dev \
    libboost-regex-dev \
    libgtest-dev \
    libaio1 \
    libasound2 \
    libcairo2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libstdc++6 \
    libxss1 \
    libxtst6 \
    zlib1g \
    zlib1g-dev \
    # Font libraries
    libfreetype6-dev \
    libfontconfig1-dev \
    # Image libraries
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    # Other deps
    libglib2.0-dev \
    libpcre3-dev \
    # Docker CLI (for docker-in-docker if needed)
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION} nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g grunt-cli

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Switch to non-root user
USER $USERNAME

# Set working directory
WORKDIR /workspace

CMD ["/bin/bash"]
