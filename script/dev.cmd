@echo off
setlocal

for %%I in ("%~dp0..") do set "root=%%~fI"
set "script_dir=%~dp0"
set "pid_backend=%script_dir%opencode-backend.pid"
set "pid_web=%script_dir%opencode-web.pid"

set "action=%~1"
if "%action%"=="" set "action=start"

if /I "%action%"=="start" goto StartAll
if /I "%action%"=="restart" goto RestartAll
if /I "%action%"=="stop" goto StopAll
if /I "%action%"=="web" goto RestartWeb
if /I "%action%"=="backend" goto RestartBackend

echo Usage: dev.cmd ^[start^|stop^|restart^|web^|backend^]
exit /b 1

:StartAll
call :StartBackend
call :StartWeb
call :PrintInfo
exit /b 0

:RestartAll
call :StopBackend
call :StopWeb
call :StartBackend
call :StartWeb
call :PrintInfo
exit /b 0

:StopAll
call :StopBackend
call :StopWeb
exit /b 0

:RestartWeb
call :StopWeb
call :StartWeb
call :PrintWebInfo
exit /b 0

:RestartBackend
call :StopBackend
call :StartBackend
call :PrintBackendInfo
exit /b 0

:StartBackend
call :IsRunning "%pid_backend%"
if "%errorlevel%"=="0" exit /b 0
powershell -NoProfile -Command "$p=Start-Process -PassThru -WorkingDirectory '%root%\\packages\\opencode' -FilePath 'bun' -ArgumentList @('run','--conditions=browser','./src/index.ts','serve','--port','4096'); Set-Content -Path '%pid_backend%' -Value $p.Id"
exit /b 0

:StartWeb
call :IsRunning "%pid_web%"
if "%errorlevel%"=="0" exit /b 0
powershell -NoProfile -Command "$p=Start-Process -PassThru -WorkingDirectory '%root%\\packages\\app' -FilePath 'bun' -ArgumentList @('dev','--','--port','4444'); Set-Content -Path '%pid_web%' -Value $p.Id"
exit /b 0

:StopBackend
call :StopByPid "%pid_backend%"
exit /b 0

:StopWeb
call :StopByPid "%pid_web%"
exit /b 0

:IsRunning
powershell -NoProfile -Command "if (Test-Path '%~1') { $id=Get-Content '%~1'; if (Get-Process -Id $id -ErrorAction SilentlyContinue) { exit 0 } } exit 1"
exit /b

:StopByPid
powershell -NoProfile -Command "if (Test-Path '%~1') { $id=Get-Content '%~1'; if (Get-Process -Id $id -ErrorAction SilentlyContinue) { Stop-Process -Id $id -Force }; Remove-Item '%~1' -ErrorAction SilentlyContinue }"
exit /b 0

:PrintInfo
echo Backend: http://localhost:4096
echo App: http://localhost:4444
exit /b 0

:PrintWebInfo
echo App: http://localhost:4444
exit /b 0

:PrintBackendInfo
echo Backend: http://localhost:4096
exit /b 0
