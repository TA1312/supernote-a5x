#!/bin/bash

_wait_for_adb () {
    ANSWER=0
    #echo "waiting for device"
    while [ "$ANSWER" != "1" ]; do
        sleep 1
        ANSWER=$(adb devices | grep $1 -c)
    done
}

_patch_prop () {
    if [ $2 == "1" ]
    then
        SWITCH="0"
    else 
        SWITCH="1"
    fi

    if adb shell "busybox grep -q -E 'by-name/system (.*) ro' /proc/mounts"; then
        echo " - remounting rw /system"
        adb shell "mount -o remount,rw /system"
    else 
        if adb shell "busybox grep -q -E 'by-name/system (.*) rw' /proc/mounts"; then
            echo " - mounted rw"
        else
            echo " - mounting /system"
            adb shell "busybox mount -t ext4 -o rw,seclabel,relatime /dev/block/by-name/system /system"
        fi
    fi 

    sleep 1

    COMMAND="if grep -q '$1' /system/etc/prop.default; then echo 1; else echo 0; fi | grep -q '1'"

    if adb shell $COMMAND; then
        echo " - pattern $1 found, setting to $2"
        adb shell "sed -i 's/$1=$SWITCH/$1=$2/' /system/etc/prop.default"
    else
        echo " - pattern $1 not found, setting to $2"
        adb shell "if \$(tail -c 1 '/system/etc/prop.default' | tr -d -c \$'\n' | cmp /dev/null - &>/dev/null); then sed -i -e '\$a\' '/system/etc/prop.default'; else sleep 0; fi"
        adb shell "echo '$1=$2' >> /system/etc/prop.default"
    fi
}

_patch() {
    echo -n "Rebooting to recovery... "
    adb reboot recovery
    _wait_for_adb "rockchipplatform"
    echo "Device in recovery."

    echo -n "Patching to $1... "
    _patch_prop "ro.secure" "$2"
    _patch_prop "ro.debuggable" "$3"
    _patch_prop "ro.adb.secure" "$4"
    _patch_prop "sys.rkadb.root" "$5"
    echo "Patched."

    echo -n "Rebooting to system... "
    adb reboot
    _wait_for_adb "SN100"
    echo "Booted."
}

_unlock() {
    _patch "unlock" 0 1 0 0
}

_relock() {
    _patch "relock" 1 0 1 1
}

echo "waiting for device (ADB installed and device attached?)"
_wait_for_adb "SN100"

_unlock

echo "installing apps"
for f in ./*.apk; do echo " - $f"; adb install "$f"; done

_relock

echo "Done!"
