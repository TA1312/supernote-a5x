@ECHO OFF

echo This script installs dropbear for ssh access while disabling adb access to your supernote device
echo Did you create ssh key and placed public key (.pub) in ./dropbear/system/etc/dropbear/authorized_keys?
echo An invalid or non existing pub key might prevent you from logging into your device
choice /c yn /n /m "press y to continue, n to exit"
if not %ERRORLEVEL%==1 GOTO :fin

echo installing dropbear
adb shell mount -o rw,remount /system
adb push dropbear/system /
adb shell dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
adb shell dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key

echo unpatching
call :_patch_prop "ro.secure" , 1
call :_patch_prop "ro.adb.secure" , 1
call :_patch_prop "ro.debuggable" , 0
call :_patch_prop "sys.rkadb.root" , 0

echo setting properties (might fail, dont worry)
adb shell setprop 'persist.sys.usb.config' 'mtp'
adb shell setprop 'ro.secure' 1
adb shell setprop 'ro.adb.secure' 1
adb shell setprop 'sys.rkadb.root' 0
adb shell setprop 'ro.debuggable' 0

echo disabling adb
adb shell settings put global adb_enabled 0

echo done!

REM =============================================

GOTO :fin

:_wait_for_adb
    :loop
        >result.tmp adb devices 
        findstr "%~1" result.tmp>NUL
        if ERRORLEVEL 1 goto loop
    EXIT /B 0

:_patch_prop 
    if %~2 == 1 (
        SET SWITCH=0
    ) ELSE (
        SET SWITCH=1
    )

    set COMMAND="grep -c '%~1' /system/etc/prop.default"

    >result.tmp adb shell %COMMAND%
    SET /p resultcode= <result.tmp 
    IF "%resultcode%" == "1" (
        echo  - pattern %~1 found, setting to %~2
        adb shell "sed -i 's/%~1=%SWITCH%/%~1=%~2/' /system/etc/prop.default"
    ) else (
        echo  - pattern %~1 not found, setting to %~2
        adb shell "if $(tail -c 1 '/system/etc/prop.default' | tr -d -c $'\n' | cmp /dev/null - &>/dev/null); then sed -i -e '$a\' '/system/etc/prop.default'; else sleep 0; fi"
        adb shell "echo '%~1=%~2' >> /system/etc/prop.default"
    )

    EXIT /B 0

:fin