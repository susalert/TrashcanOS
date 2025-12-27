var panel = new Panel
panel.location = "bottom"
panel.height = 36
panel.floating = true

var launcher = panel.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "usermenu-delete-symbolic");
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.gnome.Ptyxis.desktop"
]);
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")

var desktop = desktops()[0];

desktop.wallpaperPlugin = "org.kde.image";

desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
desktop.writeConfig("Image", "file:///usr/share/wallpapers/default-light.png");
desktop.writeConfig("FillMode", "2"); // PreserveAspectFit

