#!/bin/ksh

PATH=/bin:/sbin

trap : INT TSTP QUIT
trap 'sulogin </dev/tty1 >/dev/tty1 2>&1' ERR

echo 'Starch Linux'
echo 'http://starchlinux.org/'

. /etc/rc.conf

echo '
/proc		proc		nosuid,noexec,nodev
/sys		sysfs		nosuid,noexec,nodev
/run		tmpfs		nosuid,nodev,mode=0755
/dev		devtmpfs	nosuid,mode=0755
/dev/pts	devpts		nosuid,noexec,mode=0620,gid=5
/dev/shm	tmpfs		nosuid,nodev,mode=1777
' | awk '/./ { print "mkdir -p", $1 "; mountpoint -q", $1, "|| mount -o", $3, "-t", $2, "_", $1 }' | ksh

mount -o remount,ro /

for x in /dev/tty+([0-9]); do ${CONSOLEFONT+setfont -C $x ${CONSOLEMAP+-m "$CONSOLEMAP"} "$CONSOLEFONT"}; done

${KEYMAP+loadkeys -q "$KEYMAP"}

hwclock -ut

for x in "${MODULES[@]}"; do modprobe "$x"; done

ip link set dev lo up
echo "$HOSTNAME" >/proc/sys/kernel/hostname

which dmraid >/dev/null && dmraid -a y
which lvm    >/dev/null && lvm vgchange --sysinit -a y

cat /etc/fstab | sort -t '	' -k 6 | awk '/^[^#]/ { if ($6 > 0) print "fsck -C 2", $1, "|| ((($? | 33) == 33))" }' | ksh

mount -o remount,rw /
cat /etc/fstab | awk '/^[^#]/ { if ($3 == "swap") print "swapon", $1; else print "mount -o", $4, "-t", $3, $1, $2 }' | ksh

${TIMEZONE+cp -f "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime}

mkdir -p /var/lib
cat </var/lib/random-seed >/dev/urandom 2>/dev/null || true
(umask 077; dd if=/dev/zero of=/var/lib/random-seed bs=512 count=1 >/dev/null 2>&1)

mkdir -p /var/log
dmesg >/var/log/dmesg.log

test -x /etc/rc.local && /etc/rc.local

for n in $(seq 1 6); do asynx_spawn setsid respawn /sbin/getty -LI "$(tput -T linux reset)" 38400 tty$n linux; done

mkfifo /run/halt
while read -r x; do; done </run/halt

dd if=/dev/urandom og=/var/lib/random-seed bs=512 count=1 >/dev/null 2>&1

hwclock -uw

killall5 -TERM
for _ in $(seq 0 8); do killall5 -CONT && break; sleep 0.5; done
killall5 -KILL

umount /tmp
cat /etc/fstab | awk '/^[^#]/ { if ($3 == "swap") print "swapoff", $1; else print "umount", $2 }' | ksh

which lvm >/dev/null && lvm vgchange --sysinit -a n
cat /etc/crypttab | awk '/^[^#]/ { print "cryptsetup luksClose", $1 }' | ksh
which lvm >/dev/null && lvm vgchange --sysinit -a n

mount -o remount,ro /
sleep 1
sync
