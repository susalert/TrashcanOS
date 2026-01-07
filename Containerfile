# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# 🍌 ROOT CAUSE FIX: Pin to STABLE (Fedora 41) instead of :latest (which might be pulling Rawhide)
FROM ghcr.io/ublue-os/bazzite:stable

### [IM]MUTABLE /opt (Optional)
# RUN rm /opt && mkdir /opt

## -------------------------------- GPG KEY -------------------------------- ##
COPY assets/bin/terra.repo /etc/yum.repos.d/terra.repo
## ---------------------------------=======--------------------------------- ##

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

## ------------------- OS IDENTITY (CLEAN REBRAND) ------------------- ##
# 🍌 NO HACKS NEEDED HERE.
# Since we are on Fedora 41, we can just set the NAME and keep ID=fedora for safety.
# We include the Trojan Horse script just in case you want the runtime ID to be correct.

# 1. BUILD TIME: Set Branding
RUN sed -i \
    -e 's/^NAME=.*/NAME="TrashcanOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="TrashcanOS"/' \
    -e 's/^VARIANT=.*/VARIANT="General Drivers"/' \
    -e 's/^VARIANT_ID=.*/VARIANT_ID=trashcanos/' \
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
    /usr/lib/os-release

# 2. FIRST BOOT: Trojan Horse Script (Optional but recommended)
RUN echo '#!/bin/bash' > /usr/local/bin/fix-identity.sh && \
    echo 'sed -i "s/^ID=fedora/ID=trashcanos/" /usr/lib/os-release' >> /usr/local/bin/fix-identity.sh && \
    echo 'systemctl disable fix-identity.service' >> /usr/local/bin/fix-identity.sh && \
    echo 'rm -f /usr/local/bin/fix-identity.sh' >> /usr/local/bin/fix-identity.sh && \
    chmod +x /usr/local/bin/fix-identity.sh

RUN echo '[Unit]' > /etc/systemd/system/fix-identity.service && \
    echo 'Description=Initialize TrashcanOS Identity' >> /etc/systemd/system/fix-identity.service && \
    echo 'After=network.target' >> /etc/systemd/system/fix-identity.service && \
    echo '[Service]' >> /etc/systemd/system/fix-identity.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/fix-identity.service && \
    echo 'ExecStart=/usr/local/bin/fix-identity.sh' >> /etc/systemd/system/fix-identity.service && \
    echo '[Install]' >> /etc/systemd/system/fix-identity.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/fix-identity.service && \
    systemctl enable fix-identity.service

# 3. Create Custom Release File & Link Legacy Files
RUN printf "TrashcanOS release (General Drivers)\n" > /usr/lib/trashcanos-release && \
    ln -sf /usr/lib/trashcanos-release /etc/trashcanos-release && \
    ln -sf /usr/lib/trashcanos-release /etc/system-release && \
    ln -sf /usr/lib/trashcanos-release /etc/redhat-release

# 4. Inject the Logo
COPY assets/trashcanos.svg /usr/share/pixmaps/trashcanos.svg
COPY assets/trashcanos.svg /usr/share/icons/hicolor/scalable/apps/trashcanos.svg

# 5. Set Hostname
RUN echo "trashcanos" > /etc/hostname

# 6. Plymouth Theme
RUN plymouth-set-default-theme spinner
## ------------------------------------------------------------------ ##

## ------------------- ☢️ NUCLEAR VISUAL CLEANUP ☢️ ------------------- ##
RUN rm -f \
    /usr/share/applications/yafti-go.desktop \
    /usr/share/applications/*bazzite*.desktop \
    /usr/share/applications/*bluefin*.desktop \
    /usr/share/applications/*discourse*.desktop \
    /usr/share/applications/system-update.desktop \
    /usr/share/applications/org.gnome.Software.desktop \
    /etc/xdg/autostart/steam.desktop \
    /usr/share/autostart/steam.desktop \
    /etc/profile.d/bazzite-neofetch.sh \
    /etc/profile.d/user-motd.sh \
    /etc/profile.d/00-bazzite-welcome.sh \
    /etc/xdg/kcm-about-distrorc \
    /usr/share/kservices5/bazzite-about-distro.desktop \
    2>/dev/null || true

RUN echo 'echo "🍌 Welcome to TrashcanOS."' > /etc/profile.d/00-trashcan-welcome.sh
## -------------------------------------------------------------------- ##

## ------------------- ☢️ NUCLEAR BRANDING INJECTION ------------------- ##
# 1. KILL THE FIRST-RUN WIZARD (YAFTI)
RUN rm -f /usr/bin/yafti \
          /usr/share/applications/yafti-go.desktop \
          /etc/xdg/autostart/yafti-go.desktop \
          /etc/xdg/autostart/ublue-firstboot.desktop \
          /usr/share/applications/bazzite-portal.desktop \
          /usr/bin/bazzite-portal \
          /usr/share/applications/bazzite-documentation.desktop

RUN rm -f /usr/share/glib-2.0/schemas/*bazzite* \
    && glib-compile-schemas /usr/share/glib-2.0/schemas

RUN rm -f /usr/lib/systemd/system/bazzite-hardware-setup.service \
          /usr/bin/bazzite-hardware-setup

# 2. DELETE THE BAZZITE THEME (VAPOUR) SOURCE
RUN rm -rf /usr/share/plasma/look-and-feel/org.valve.vapour.desktop \
           /usr/share/plasma/look-and-feel/org.valve.vgui.desktop \
           /usr/share/plasma/desktoptheme/Vapour

RUN rm -rf /usr/share/ublue-os \
           /usr/share/bazzite \
           /etc/profile.d/ublue-os-just.sh

RUN rm -f /usr/bin/bazzite* \
          /usr/libexec/bazzite*

RUN mkdir -p /usr/share/ublue-os/ && \
    echo '{"image-name": "trashcanos", "image-flavor": "latest", "base-image-name": "fedora", "fedora-version": "unknown"}' > /usr/share/ublue-os/image-info.json

COPY assets/default-light.png /usr/share/wallpapers/default-light.png
COPY assets/default-dark.png /usr/share/wallpapers/default-dark.png
COPY assets/org.trashcanos.desktop /usr/share/plasma/look-and-feel/org.trashcanos.desktop
COPY assets/org.trashcanosdark.desktop /usr/share/plasma/look-and-feel/org.trashcanosdark.desktop
COPY assets/Oxy /usr/share/plasma/desktoptheme/Oxy
COPY assets/OxyDark /usr/share/plasma/desktoptheme/OxyDark
COPY assets/config/kdeglobals /etc/xdg/kdeglobals
COPY assets/config/plasmarc /etc/xdg/plasmarc
COPY assets/config/kwinrc /etc/xdg/kwinrc
COPY assets/config/kcminputrc /etc/xdg/kcminputrc
COPY assets/config/kscreenlockerrc /etc/xdg/kscreenlockerrc
COPY assets/config/plasma-org.kde.plasma.desktop-appletsrc /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc
COPY assets/oxy /usr/share/sddm/themes/oxy
COPY assets/Oxy.colors /usr/share/color-schemes/Oxy.colors
COPY assets/OxyDark.colors /usr/share/color-schemes/OxyDark.colors

RUN chmod -R a-w /usr/share/sddm/themes/oxy
## ------------------------------------------------------------------------- ##

## ------------------- FINAL SCRUB: REMOVE BAZZITE IMAGES ------------------- ##
RUN rm -rf \
    /usr/share/wallpapers/Bazzite \
    /usr/share/wallpapers/DeepBlue \
    /usr/share/wallpapers/F39 \
    /usr/share/icons/hicolor/*/apps/bazzite* \
    /usr/share/pixmaps/bazzite* \
    /usr/share/bazzite/screenshots \
    2>/dev/null || true

RUN gtk-update-icon-cache /usr/share/icons/hicolor || true
## -------------------------------------------------------------------------- ##
