@echo off
setlocal
cd /d "%~dp0"

set "GODOT="
for /f "delims=" %%I in ('where Godot_v4.7.2-stable_win64_console.exe 2^>nul') do if not defined GODOT set "GODOT=%%I"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do if not defined GODOT if exist "%%~fD\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=%%~fD\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT (
  echo Godot 4.7.2 console executable was not found. Install Godot 4.7.2 or add it to PATH.
  pause
  exit /b 2
)

echo.
echo === Import project and register script classes ===
"%GODOT%" --headless --editor --path "%CD%" --quit
if errorlevel 1 goto failed

call :run "Core tests" "tests/run.gd" "--quit-after 2" "All headless project tests passed"
if errorlevel 1 goto failed
call :run "Content validation" "scripts/validate_content.gd" "--quit-after 2" "Content validation passed"
if errorlevel 1 goto failed
call :run "Campaign simulation" "tests/campaign_playability.gd" "--quit-after 2" "All 8 campaign stages won"
if errorlevel 1 goto failed
call :run "Editor preview isolation" "tests/editor_preview.gd" "" "Editor preview isolation passed"
if errorlevel 1 goto failed
call :run "Battle UI tests" "tests/results_view.gd" "" "Battle result panel tests passed"
if errorlevel 1 goto failed
echo Running editor-panel checks. Godot may print resource cleanup warnings after passing assertions.
set "EDITOR_LOG=%TEMP%\holo-godot-editor-%RANDOM%.log"
"%GODOT%" --headless --editor --path "%CD%" -s "tests/editor_panels.gd" >"%EDITOR_LOG%" 2>&1
set "EDITOR_EXIT=%ERRORLEVEL%"
type "%EDITOR_LOG%"
if not "%EDITOR_EXIT%"=="0" goto failed
findstr /L /C:"Editor content panels passed" "%EDITOR_LOG%" >nul
if errorlevel 1 goto failed
del "%EDITOR_LOG%" >nul 2>&1
echo.
echo All Godot test commands passed.
pause
exit /b 0

:run
echo.
echo === %~1 ===
set "RUN_LOG=%TEMP%\holo-godot-%RANDOM%.log"
"%GODOT%" --headless --path "%CD%" -s "%~2" %~3 >"%RUN_LOG%" 2>&1
set "RUN_EXIT=%ERRORLEVEL%"
type "%RUN_LOG%"
if not "%RUN_EXIT%"=="0" goto run_failed
findstr /L /C:"%~4" "%RUN_LOG%" >nul
if errorlevel 1 goto run_failed
del "%RUN_LOG%" >nul 2>&1
exit /b 0

:run_failed
del "%RUN_LOG%" >nul 2>&1
exit /b 1

:failed
echo.
echo A Godot test failed. Review the output above.
pause
exit /b 1
