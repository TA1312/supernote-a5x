@ECHO OFF

echo waiting for device (ADB installed and device attached?)
call :_wait_for_adb "SN100"

echo rebooting to recovery
adb reboot recovery
call :_wait_for_adb "rockchipplatform"

echo patching

call :_patch_prop "ro.secure" , 0
call :_patch_prop "ro.debuggable" , 1
call :_patch_prop "ro.adb.secure" , 0
call :_patch_prop "sys.rkadb.root" , 0

echo rebooting to system
adb reboot

call :_wait_for_adb "SN100"

echo installing apps
FOR %%F IN (*.apk) DO (
    echo installing %%F
    adb install "%%F"
)

echo rebooting to recovery
adb reboot recovery
call :_wait_for_adb "rockchipplatform"

echo unpatching
call :_patch_prop "ro.secure" , 1
call :_patch_prop "ro.debuggable" , 0
call :_patch_prop "ro.adb.secure" , 1
call :_patch_prop "sys.rkadb.root" , 1

echo rebooting to system
adb reboot

echo waiting for system
call :_wait_for_adb "SN100"

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

    >result.tmp adb shell "busybox grep -c -E 'by-name/system (.*) ro' /proc/mounts"
    SET /p resultcode= <result.tmp 
    IF "%resultcode%" == "1" (
        echo  - remounting rw /system
        adb shell "mount -o remount,rw /system"
    ) 

    >result.tmp adb shell "busybox grep -c -E 'by-name/system (.*) rw' /proc/mounts"
    SET /p resultcode= <result.tmp 
    IF "%resultcode%" == "1" (
        echo  - mounted rw
    ) ELSE (
        echo  - mounting /system
        adb shell "busybox mount -t ext4 -o rw,seclabel,relatime /dev/block/by-name/system /system"
    )
    
    timeout /T 1 > nul

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