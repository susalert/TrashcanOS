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
## ------------------------------------ ##

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

## -------------- APP DOCKER WORK IMAGE -------------- ##
#RUN podman pull registry.fedoraproject.org/fedora:latest
## --------------------------------------------------- ##

## ----------- BAZAAR DISPOSAL ----------- ##
RUN rpm-ostree override remove bazaar && \
    rpm-ostree install plasma-discover && \
    rpm-ostree override remove vim-enhanced && \
    rpm-ostree install neovim

ENV EDITOR=nvim
ENV VISUAL=nvim
## --------------------------------------- ##

## ---------- DEV TESTING PURPOSE ONLY ---------- ##
# Temporary test user to access the DE for testing #
RUN useradd -m -G wheel test && \
    echo "test:test" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-wheel-nopasswd
## ---------------------------------------------- ##

## ------------------- APP MANAGER & RESTRICTIONS ------------------- ##
COPY assets/bin/app /usr/bin/app
COPY assets/bin/trashcanctl /usr/bin/trashcanctl
COPY assets/bin/locked-command-wrapper /usr/local/bin/rpm-ostree
COPY assets/bin/locked-command-wrapper /usr/local/bin/bootc

RUN chmod +x /usr/bin/app \
             /usr/bin/trashcanctl \
             /usr/local/bin/rpm-ostree \
             /usr/local/bin/bootc

RUN mkdir -p /etc/trashcan
## ------------------------------------------------------------------ ##

## ------------------- OS IDENTITY & CLEANUP ------------------- ##
# 1. Modify the Base OS Release File (Consolidated)
RUN sed -i \
    # Rename the OS
    -e 's/^NAME=.*/NAME="TrashcanOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="TrashcanOS sAlpha"/' \
    -e 's/^ID=.*/ID=trashcanos/' \
    -e 's/^ID_LIKE=.*/ID_LIKE="fedora"/' \
    -e 's/^VARIANT=.*/VARIANT="General Drivers"/' \
    -e 's/^LOGO=.*/LOGO=trashcanos/' \
    -e 's/^BOOTLOADER_NAME=.*/BOOTLOADER_NAME="TrashcanOS"/' \
    # Fix the URLs (Bazzite -> Trashcan)
    -e 's|bazzite.gg|trashcanos.org|g' \
    -e 's|universal-blue:bazzite|susalert:trashcanos|g' \
    -e 's|DEFAULT_HOSTNAME="bazzite"|DEFAULT_HOSTNAME="trashcanos"|g' \
    # Nuke the Ghost Links (Delete lines starting with these keys)
    -e '/^HOME_URL=/d' \
    -e '/^DOCUMENTATION_URL=/d' \
    -e '/^BUG_REPORT_URL=/d' \
    -e '/^SUPPORT_URL=/d' \
    -e '/^SUPPORT_END=/d' \
    -e '/^IMAGE_ID=/d' \
    -e '/^VARIANT_ID=/d' \
    /usr/lib/os-release

# 2. Create the Custom Release File
RUN printf "NAME=TrashcanOS\nVERSION=sAlpha\nEDITION=General\nDE=Plasma\n" > /usr/lib/trashcanos-release

# 3. Link it so the system sees it
RUN ln -sf /usr/lib/trashcanos-release /etc/trashcanos-release && \
    ln -sf /usr/lib/trashcanos-release /etc/system-release

# 4. Cleanup Bazzite Scripts
RUN rm -f /etc/profile.d/bazzite-neofetch.sh \
          /etc/profile.d/user-motd.sh \
          /etc/profile.d/00-bazzite-welcome.sh 2>/dev/null || true

# 5. Add Trashcan Welcome
RUN echo 'echo "🍌 Welcome to TrashcanOS sAlpha. Prepare for chaos."' > /etc/profile.d/00-trashcan-welcome.sh

# 6. Set Hostname
RUN echo "trashcanos" > /etc/hostname
## ------------------------------------------------------------- ##

## -------------------------------- LOGO FIX -------------------------------- ##
COPY assets/trashcanos.svg /usr/share/icons/hicolor/scalable/apps/trashcanos.svg
COPY assets/trashcanos.svg /usr/share/pixmaps/trashcanos.svg
## -------------------------------------------------------------------------- ##
