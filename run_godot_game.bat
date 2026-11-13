@echo off
setlocal
cd /d "%~dp0"

set "GODOT="
for /f "delims=" %%I in ('where Godot_v4.7.2-stable_win64.exe 2^>nul') do if not defined GODOT set "GODOT=%%I"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do if not defined GODOT if exist "%%~fD\Godot_v4.7.2-stable_win64.exe" set "GODOT=%%~fD\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT (
  echo Godot 4.7.2 GUI executable was not found. Install Godot 4.7.2 or add it to PATH.
  pause
  exit /b 2
)

echo Starting Holo Tactics from this project folder...
start "Holo Tactics - Godot" "%GODOT%" --path "%CD%"
exit /b 0
