[[customizations.filesystem]]
mountpoint = "/"
minsize = "50 GiB"
fs = "ext4"

[[customizations.filesystem.partitions]]
name = "boot"
size = "1 GiB"
fs = "vfat"
mountpoint = "/boot"

[[customizations.filesystem.partitions]]
name = "root"
size = "48 GiB"
fs = "ext4"
mountpoint = "/"

[[customizations.filesystem.partitions]]
name = "swap"
size = "2 GiB"
fs = "swap"
