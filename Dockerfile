FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
LABEL maintainer="Mahmoud Almontasser"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"
# https://github.com/dlemstra/Magick.NET/issues/707#issuecomment-785351620
ENV MALLOC_TRIM_THRESHOLD_=131072

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    mesa-va-drivers \
    xmlstarlet && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Copy custom Jellyfin artifacts to LinuxServer.io expected locations
COPY artifacts/server/ /usr/lib/jellyfin/
COPY artifacts/web/ /usr/share/jellyfin/web/

# Create symbolic link for jellyfin binary in expected location
RUN ln -sf /usr/lib/jellyfin/jellyfin /usr/bin/jellyfin && \
    chmod +x /usr/lib/jellyfin/jellyfin

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8096 8920
VOLUME /config