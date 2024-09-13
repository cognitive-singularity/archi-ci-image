# Base image
FROM docker.io/ubuntu:22.04 AS base

# Set working directory
WORKDIR /archi

# Set timezone argument
ARG TZ=UTC

# Install necessary packages
RUN set -eux; \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime; \
    echo "$TZ" > /etc/timezone; \
    apt-get update; \
    apt-get install -y \
      ca-certificates \
      libgtk2.0-cil \
      libswt-gtk-4-jni \
      dbus-x11 \
      xvfb \
      curl \
      git \
      openssh-client \
      unzip; \
    apt-get clean; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# Download and extract Archi
FROM base AS archi
ARG ARCHI_VERSION=5.4.1

RUN set -eux; \
    curl -#Lo archi.tgz \
      "https://www.archimatetool.com/downloads/archi/$ARCHI_VERSION/Archi-Linux64-$ARCHI_VERSION.tgz"; \
    tar zxf archi.tgz -C /opt/; \
    rm archi.tgz; \
    chmod +x /opt/Archi/Archi; \
    mkdir -p /root/.archi/dropins /archi/report /archi/project

# Download and extract coArchi plugin
FROM archi AS coarchi
ARG COARCHI_VERSION=0.9.2

RUN set -eux; \
    curl -#Lo coarchi.zip --request POST \
      "https://www.archimatetool.com/downloads/coarchi/coArchi_$COARCHI_VERSION.archiplugin"; \
    unzip coarchi.zip -d /root/.archi/dropins/ && \
    rm coarchi.zip

# Final image setup
FROM coarchi

# Create a non-root user and set permissions
ARG UID=1000
RUN set -eux; \
    groupadd --gid "$UID" archi; \
    useradd --uid "$UID" --gid archi --shell /bin/bash \
      --home-dir /archi --create-home archi; \
    mv /root/.archi /archi/; \
    chown -R archi:archi /archi; \
    chmod -R g+rw /archi

# Copy entrypoint script
COPY --chown=archi:archi entrypoint.sh /opt/Archi/

# Switch to non-root user
USER archi

# Set the entrypoint
ENTRYPOINT [ "/opt/Archi/entrypoint.sh" ]
