# Custom Jellyfin Docker image extending LinuxServer.io's image
# This Dockerfile replaces the standard Jellyfin installation with a custom build

ARG TARGETARCH=amd64
FROM linuxserver/jellyfin:10.10.7ubu2404-ls72

# Switch to root for system modifications
USER root

# Install dependencies, OpenCL support, graphics libraries, and ffmpeg for media processing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        ocl-icd-libopencl1 \
        libfontconfig1 \
        libfreetype6 \
        libssl3 \
        libc6-dev \
        ffmpeg && \
    apt-get remove -y jellyfin && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/lib/jellyfin /usr/share/jellyfin

# Create directories for our custom installation
RUN mkdir -p /opt/jellyfin /opt/jellyfin-web

# Validate and copy our custom Jellyfin build
# These artifacts should be extracted and available in the build context
COPY --chown=abc:abc artifacts/server/ /opt/jellyfin/
COPY --chown=abc:abc artifacts/web/ /opt/jellyfin-web/

# Validate that required files exist
RUN test -f /opt/jellyfin/jellyfin || (echo "ERROR: jellyfin binary not found in artifacts/server/" && exit 1) && \
    test -d /opt/jellyfin-web || (echo "ERROR: web files not found in artifacts/web/" && exit 1)

# Create symbolic links to maintain compatibility (permissions already set in COPY)
RUN chmod +x /opt/jellyfin/jellyfin && \
    ln -sf /opt/jellyfin/jellyfin /usr/bin/jellyfin && \
    mkdir -p /usr/share/jellyfin && \
    ln -sf /opt/jellyfin-web /usr/share/jellyfin/web

# Override LinuxServer.io's existing jellyfin service to use our custom build
COPY <<EOF /etc/s6-overlay/s6-rc.d/svc-jellyfin/run
#!/usr/bin/with-contenv bash

# Ensure PATH includes standard locations for ffmpeg and other tools
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Apply standard LinuxServer.io permissions
lsiown abc:abc \\
    /config \\
    /opt/jellyfin \\
    /opt/jellyfin-web

echo "Starting custom Jellyfin build..."
cd /opt/jellyfin
exec s6-setuidgid abc ./jellyfin \\
    --datadir="/config" \\
    --cachedir="/config/cache" \\
    --configdir="/config/config" \\
    --logdir="/config/log" \\
    --webdir="/opt/jellyfin-web"
EOF

RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-jellyfin/run

# Add metadata
LABEL maintainer="Custom Jellyfin Build"
LABEL description="LinuxServer Jellyfin image with custom Jellyfin build"

# Ensure ports are explicitly exposed for accessibility
EXPOSE 8096 8920

# The LinuxServer base image health check should work with our custom binary