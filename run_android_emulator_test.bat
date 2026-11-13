@echo off
setlocal
cd /d "%~dp0"

set "ANDROID_SDK=%ANDROID_SDK_ROOT%"
if not defined ANDROID_SDK set "ANDROID_SDK=%ANDROID_HOME%"
if not defined ANDROID_SDK set "ANDROID_SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%ANDROID_SDK%\platform-tools\adb.exe"
set "EMULATOR=%ANDROID_SDK%\emulator\emulator.exe"
set "APK=%CD%\build\holo-debug.apk"
if not exist "%ADB%" (
  echo Android SDK platform-tools not found at "%ANDROID_SDK%".
  echo Set ANDROID_SDK_ROOT or install the Android SDK.
  pause
  exit /b 2
)
if not exist "%EMULATOR%" (
  echo Android emulator executable was not found at "%EMULATOR%".
  pause
  exit /b 2
)
if not exist "%APK%" (
  echo APK not found: "%APK%"
  echo Export the Godot preset "Android Debug APK" to build\holo-debug.apk first.
  pause
  exit /b 2
)

set "AVD="
set "FIRST_AVD="
for /f "delims=" %%A in ('"%EMULATOR%" -list-avds') do (
  if not defined FIRST_AVD set "FIRST_AVD=%%A"
  if /i "%%A"=="MaDangStage6_API37" set "AVD=%%A"
)
if not defined AVD set "AVD=%FIRST_AVD%"
if not defined AVD (
  echo No Android Virtual Device is configured. Create an Android 37+ AVD first.
  pause
  exit /b 2
)
echo Using AVD: %AVD%

"%ADB%" start-server
"%ADB%" reconnect offline >nul 2>&1
call :find_emulator
if not defined SERIAL start "Holo Tactics Android Test" "%EMULATOR%" -avd "%AVD%"

set "ATTEMPTS=0"
:wait_device
if not defined SERIAL call :find_emulator
if defined SERIAL goto wait_boot
set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 90 goto device_timeout
timeout /t 2 /nobreak >nul
goto wait_device

:wait_boot
set "BOOTED="
set "BOOT_FILE=%TEMP%\holo-boot-%RANDOM%.txt"
"%ADB%" -s "%SERIAL%" shell getprop sys.boot_completed > "%BOOT_FILE%" 2>nul
set /p BOOTED=<"%BOOT_FILE%"
del "%BOOT_FILE%" >nul 2>&1
if "%BOOTED%"=="1" goto install_app
set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 150 goto device_timeout
timeout /t 2 /nobreak >nul
goto wait_boot

:install_app
echo Installing current debug APK on %SERIAL%...
"%ADB%" -s "%SERIAL%" install -r "%APK%"
if errorlevel 1 goto failed
"%ADB%" -s "%SERIAL%" shell monkey -p com.example.holotactics 1
if errorlevel 1 goto failed
echo.
echo Holo Tactics was installed and launched. Leave the emulator open for hands-on testing.
pause
exit /b 0

:device_timeout
echo Emulator did not finish booting. Check the AVD and Android SDK, then run this file again.
pause
exit /b 1

:failed
echo Emulator install or launch failed. Review the ADB output above.
pause
exit /b 1

:find_emulator
set "SERIAL="
set "DEVICE_LIST=%TEMP%\holo-adb-%RANDOM%.txt"
"%ADB%" devices >"%DEVICE_LIST%"
findstr /b emulator- "%DEVICE_LIST%" > "%DEVICE_LIST%.filtered"
for /f "tokens=1,2" %%A in (%DEVICE_LIST%.filtered) do if "%%B"=="device" if not defined SERIAL set "SERIAL=%%A"
del "%DEVICE_LIST%.filtered" >nul 2>&1
del "%DEVICE_LIST%" >nul 2>&1
exit /b 0
