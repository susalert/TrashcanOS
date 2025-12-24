#!/bin/bash
# customize-kde.sh
CONFIG_DIR="/etc/skel/.config"
ICON_DIR="/usr/share/icons/hicolor/48x48/apps"
WALLPAPER_DIR="/usr/share/wallpapers"

mkdir -p $CONFIG_DIR $ICON_DIR $WALLPAPER_DIR

chown -R root:root $CONFIG_DIR
chmod -R 755 $CONFIG_DIR

cp /usr/share/trashcanos-assets/usermenu-delete-symbolic.svg $ICON_DIR/start-menu.svg
cp /usr/share/trashcanos-assets/TrashcanOS-default.jpg $WALLPAPER_DIR/

# --- Panel & Taskbar (floating liquid-glass style) ---
cat > $CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc << 'EOF'
[Containments][1]
formfactor=2
location=2
alignment=center
height=36
opacity=0.6
immutability=1
widgets=[org.kde.plasma.panelapplets.launcher,org.kde.plasma.panelapplets.taskmanager,org.kde.plasma.panelapplets.systemtray,org.kde.plasma.panelapplets.clock]

[Containments][1][Applets][org.kde.plasma.panelapplets.launcher]
plugin=org.kde.plasma.panelapplets.launcher
alignment=left

[Containments][1][Applets][org.kde.plasma.panelapplets.taskmanager]
plugin=org.kde.plasma.panelapplets.taskmanager
alignment=center

[Containments][1][Applets][org.kde.plasma.panelapplets.systemtray]
plugin=org.kde.plasma.panelapplets.systemtray
alignment=right

[Containments][1][Applets][org.kde.plasma.panelapplets.clock]
plugin=org.kde.plasma.panelapplets.clock
alignment=right

[Configuration]
menuIcon=start-menu.svg

[Desktops][1]
wallpaperPlugin=org.kde.image
Image=file:///usr/share/wallpapers/TrashcanOS-default.jpg
EOF

# --- Fastfetch Logo ---
mkdir -p /etc/skel/.config/fastfetch
cp /usr/share/trashcanos-assets/ascii-art.txt /etc/skel/.config/fastfetch/logo.txt
cat > /etc/skel/.config/fastfetch/config << 'EOF'
logo="~/.config/fastfetch/logo.txt"
EOF

# --- Plasma Panel Blur (Liquid Glass) ---
THEME_DIR="/usr/share/plasma/desktoptheme/TrashcanOS"
mkdir -p $THEME_DIR/contents/config

chmod -R 755 /usr/share/plasma/desktoptheme/TrashcanOS
chown -R root:root /usr/share/plasma/desktoptheme/TrashcanOS

cat > $THEME_DIR/contents/config/plasma-org.kde.plasma.desktop-appletsrc << 'EOF'
[Theme]
translucency=2    # 0=Opaque, 1=Semi, 2=Blur (frosted glass)
EOF

# Set this theme as default for new users
cat >> $CONFIG_DIR/kdeglobals << 'EOF'
[Plasma]
Theme=TrashcanOS
EOF

