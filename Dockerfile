FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
LABEL maintainer="Mahmoud Almontasser"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"
# https://github.com/dlemstra/Magick.NET/issues/707#issuecomment-785351620
ENV MALLOC_TRIM_THRESHOLD_=131072

RUN \
  echo "**** add jellyfin repository ****" && \
  curl -s https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor | tee /usr/share/keyrings/jellyfin.gpg >/dev/null && \
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu noble main' > /etc/apt/sources.list.d/jellyfin.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    mesa-va-drivers \
    xmlstarlet && \
  apt-get install $(apt-cache depends jellyfin | grep "Depends:" | awk '{print $2}' | tr -d '<>') && \
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