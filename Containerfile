# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite:latest

### [IM]MUTABLE /opt (Optional)
# RUN rm /opt && mkdir /opt

## ------- CUSTOMIZATION ASSETS ------- ##
COPY assets/ /usr/share/trashcanos-assets/
## ------------------------------------ ##

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
RUN bootc container lint

## ----------- BAZAAR DISPOSAL & EDITOR SETUP ----------- ##
RUN rpm-ostree override remove bazaar && \
    rpm-ostree install plasma-discover && \
    rpm-ostree override remove vim-enhanced && \
    rpm-ostree install neovim

ENV EDITOR=nvim
ENV VISUAL=nvim
## ------------------------------------------------------ ##

## ---------- DEV TESTING USER ---------- ##
RUN useradd -m -G wheel test && \
    echo "test:test" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-wheel-nopasswd
## -------------------------------------- ##

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

## ------------------- OS IDENTITY (THE REBRAND) ------------------- ##
# 1. Modify the Base OS Release File
RUN sed -i \
    -e 's/^NAME=.*/NAME="TrashcanOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="TrashcanOS sAlpha"/' \
    -e 's/^ID=.*/ID=trashcanos/' \
    -e 's/^ID_LIKE=.*/ID_LIKE="fedora"/' \
    -e 's/^VARIANT=.*/VARIANT="General Drivers"/' \
    -e 's/^LOGO=.*/LOGO=trashcanos/' \
    -e 's/^BOOTLOADER_NAME=.*/BOOTLOADER_NAME="TrashcanOS"/' \
    -e 's|bazzite.gg|trashcanos.org|g' \
    -e 's|universal-blue:bazzite|susalert:trashcanos|g' \
    -e 's|DEFAULT_HOSTNAME="bazzite"|DEFAULT_HOSTNAME="trashcanos"|g' \
    -e '/^HOME_URL=/d' \
    -e '/^DOCUMENTATION_URL=/d' \
    -e '/^BUG_REPORT_URL=/d' \
    -e '/^SUPPORT_URL=/d' \
    -e '/^SUPPORT_END=/d' \
    -e '/^IMAGE_ID=/d' \
    -e '/^VARIANT_ID=/d' \
    /usr/lib/os-release

# 2. Create Custom Release File & Link Legacy Files
# (We link redhat-release too, because KDE sometimes checks it)
RUN printf "TrashcanOS release sAlpha (General Drivers)\n" > /usr/lib/trashcanos-release && \
    ln -sf /usr/lib/trashcanos-release /etc/trashcanos-release && \
    ln -sf /usr/lib/trashcanos-release /etc/system-release && \
    ln -sf /usr/lib/trashcanos-release /etc/redhat-release

# 3. Inject the Logo
COPY assets/trashcanos.svg /usr/share/pixmaps/trashcanos.svg
COPY assets/trashcanos.svg /usr/share/icons/hicolor/scalable/apps/trashcanos.svg

# 4. Set Hostname
RUN echo "trashcanos" > /etc/hostname

# 5. Plymouth Theme
RUN plymouth-set-default-theme spinner
## ------------------------------------------------------------------ ##

## ------------------- ☢️ NUCLEAR VISUAL CLEANUP ☢️ ------------------- ##
# This block kills Bazzite Apps, Steam Autostart, and Branding Overrides

RUN rm -f \
    # 1. The Bazzite Portal (Traitor Found!)
    /usr/share/applications/yafti-go.desktop \
    # 2. Bazzite Documentation, Welcome & Setup
    /usr/share/applications/*bazzite*.desktop \
    /usr/share/applications/*bluefin*.desktop \
    # 3. Universal Blue Forums (Discourse)
    /usr/share/applications/*discourse*.desktop \
    # 4. The Manual Update Icon (We use 'app' now)
    /usr/share/applications/system-update.desktop \
    /usr/share/applications/org.gnome.Software.desktop \
    # 5. Steam Autostart (Silence!)
    /etc/xdg/autostart/steam.desktop \
    /usr/share/autostart/steam.desktop \
    # 6. Bazzite Scripts
    /etc/profile.d/bazzite-neofetch.sh \
    /etc/profile.d/user-motd.sh \
    /etc/profile.d/00-bazzite-welcome.sh \
    # 7. The "About System" Override (Fixes "Bazzite 43" text)
    /etc/xdg/kcm-about-distrorc \
    /usr/share/kservices5/bazzite-about-distro.desktop \
    2>/dev/null || true

# Add Trashcan Welcome Script
RUN echo 'echo "🍌 Welcome to TrashcanOS sAlpha. Prepare for chaos."' > /etc/profile.d/00-trashcan-welcome.sh
## -------------------------------------------------------------------- ##
