#!/bin/sh -xe

if [ -f root ]; then
	echo "ERROR: already there, will not setup"
	exit 1
fi

touch root
chattr +Cm root
truncate -s 10G root
/sbin/mkfs.ext2 root

./root-mount || { echo "ERROR: no mount"; exit 1; }
sudo cp dumb-init mnt
if [ -f "zypp.conf" ]; then
	sudo mkdir -p mnt/etc/zypp
	sudo cp zypp.conf mnt/etc/zypp
	echo "Looks like you have manual zyp config, unpause"
	read pause
fi

# Workaround for busybox-* substitutes that are not on par with standard tools
#sudo mkdir -p mnt/etc/zypp/locks
#sudo touch mnt/etc/zypp
#./install-al 'busybox-*'

./install-cmd ar --no-gpgcheck --refresh https://download.opensuse.org/tumbleweed/repo/oss tw-oss
./install-cmd ref -f
./install-cmd install `cat packages-*`
./install-cmd se busybox

if false; then
for p in packages-*; do
	./install-list "$p"
	sync
done
fi

./update-init

./root-umount

echo "NOTE: add your testing files"
