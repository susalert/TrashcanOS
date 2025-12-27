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
    rpm-ostree install neovim && \
    rpm-ostree install firefox

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
RUN echo 'echo "🍌 Welcome to TrashcanOS sAlpha."' > /etc/profile.d/00-trashcan-welcome.sh
## -------------------------------------------------------------------- ##

## ------------------- ☢️ NUCLEAR BRANDING INJECTION ------------------- ##
# 1. KILL THE FIRST-RUN WIZARD (YAFTI)
# This tool runs on boot and often resets settings. We murder it here.
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
# If these folders don't exist, KDE CANNOT switch back to them.
RUN rm -rf /usr/share/plasma/look-and-feel/org.valve.vapour.desktop \
           /usr/share/plasma/look-and-feel/org.valve.vgui.desktop \
           /usr/share/plasma/desktoptheme/Vapour

RUN rm -rf /usr/share/ublue-os \
           /usr/share/bazzite \
           /etc/profile.d/ublue-os-just.sh

RUN rm -f /usr/bin/bazzite* \
          /usr/libexec/bazzite*

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
# We remove the visual assets. Note: We use 'rm -rf' for folders and wildcards for files.
# COULD BREAK THE SYSTEM BUILD. REMOVE IF YES

RUN rm -rf \
    # 1. The Bazzite Wallpapers
    /usr/share/wallpapers/Bazzite \
    /usr/share/wallpapers/DeepBlue \
    /usr/share/wallpapers/F39 \
    # 2. The Bazzite Icons (The big search results you found)
    /usr/share/icons/hicolor/*/apps/bazzite* \
    /usr/share/pixmaps/bazzite* \
    # 3. The "Desktop Portal" images (screenshots used in their setup tool)
    /usr/share/bazzite/screenshots \
    2>/dev/null || true

# Double check we didn't break the icon cache (Optional but good practice)
RUN gtk-update-icon-cache /usr/share/icons/hicolor || true
## -------------------------------------------------------------------------- ##
