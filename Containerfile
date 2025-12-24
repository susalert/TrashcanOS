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
RUN printf "NAME=TrashcanOS\nVERSION=sAlpha\nEDITION=General\nDE=Plasma\n" > /usr/lib/trashcanos-release

# Link it so the system can find it
RUN ln -sf /usr/lib/trashcanos-release /etc/trashcanos-release
RUN ln -sf /usr/lib/trashcanos-release /etc/system-release
# 1. Nuke the Bazzite Welcome Scripts 🗑️
RUN rm -f /etc/profile.d/bazzite-neofetch.sh \
          /etc/profile.d/user-motd.sh \
          /etc/profile.d/00-bazzite-welcome.sh 2>/dev/null || true

# 2. Add our own simple welcome message (Optional)
RUN echo 'echo "🍌 Welcome to TrashcanOS sAlpha. Prepare for chaos."' > /etc/profile.d/00-trashcan-welcome.sh

# 3. Fix the Hostname permanently
RUN echo "trashcanos" > /etc/hostname

# 4. Scrub the remaining URLs and Metadata in os-release
# We use sed to replace the remaining "bazzite" references with "trashcanos"
RUN sed -i \
    -e 's|bazzite.gg|trashcanos.org|g' \
    -e 's|universal-blue:bazzite|susalert:trashcanos|g' \
    -e 's|DEFAULT_HOSTNAME="bazzite"|DEFAULT_HOSTNAME="trashcanos"|g' \
    -e 's|VARIANT_ID=bazzite|VARIANT_ID=trashcanos|g' \
    /usr/lib/os-release
RUN sed -i 's/^BOOTLOADER_NAME=.*/BOOTLOADER_NAME="TrashcanOS"/' /usr/lib/os-release
## --------------------------------------------------- ##

## ------------------- VISUAL CLEANUP ------------------- ##
RUN plymouth-set-default-theme spinner

RUN mkdir -p /usr/share/backgrounds/trashcanos
COPY assets/TrashcanOS-default.jpg /usr/share/backgrounds/trashcanos/login.jpg

RUN printf "[Theme]\nCurrent=breeze\n" > /etc/sddm.conf.d/kde_settings.conf

RUN ln -sf /usr/share/backgrounds/trashcanos/login.jpg /usr/share/wallpapers/Next/contents/images/1920x1080.png
RUN ln -sf /usr/share/backgrounds/trashcanos/login.jpg /usr/share/wallpapers/Next/contents/images/2560x1440.png

RUN [ -f /etc/default/grub ] && sed -i 's/^GRUB_THEME=.*/#GRUB_THEME="disabled"/' /etc/default/grub || true
## -------------------------------------------------------- ##
