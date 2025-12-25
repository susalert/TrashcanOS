var panel = new Panel
panel.location = "bottom"
panel.height = 36
panel.floating = true

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")

var desktop = desktops()[0];

desktop.wallpaperPlugin = "org.kde.image";

desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
desktop.writeConfig("Image", "file:///usr/share/wallpapers/default-light.png");
desktop.writeConfig("FillMode", "2"); // PreserveAspectFit
