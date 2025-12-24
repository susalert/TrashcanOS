# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite:latest

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

## ------- CUSTOMIZATION ASSETS ------- ##
COPY assets/ /usr/share/trashcanos-assets/

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
    
#RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
#    /ctx/customize-kde.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

## ---------- DEV TESTING PURPOSE ONLY ---------- ##
# Temporary test user to access the DE for testing #
RUN useradd -m -G wheel test && \
    echo "test:test" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-wheel-nopasswd
## ---------------------------------------------- ##

## ------------------- OS IDENTITY ------------------- ##
RUN sed -i \
  -e 's/^NAME=.*/NAME="TrashcanOS"/' \
  -e 's/^PRETTY_NAME=.*/PRETTY_NAME="TrashcanOS sAlpha"/' \
  -e 's/^ID=.*/ID=trashcanos/' \
  -e 's/^ID_LIKE=.*/ID_LIKE="fedora"/' \
  -e 's/^VARIANT=.*/VARIANT="Immutable Desktop"/' \
  -e 's/^LOGO=.*/LOGO=trashcanos/' \
  /usr/lib/os-release
## --------------------------------------------------- ##

## ------------------- TRASHCANOS ID ------------------- ##
RUN tee /usr/lib/trashcanos-release << 'EOF'
NAME=TrashcanOS
VERSION=sAlpha
EDITION=General
DE=Plasma
EOF

RUN ln -sf /usr/lib/trashcanos-release /etc/trashcanos-release
RUN ln -sf /usr/lib/trashcanos-release /etc/system-release
