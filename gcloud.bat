@echo off
:: Tell coder.bat not to spawn endless loops when we use SSH in this script!
set CODER_SYNC_RUNNING=1

set WORKSPACE=%1

:: -------------------------------------------------------------------------
:: PHASE 1: Check Local Tokens (Do this while the server boots)
:: -------------------------------------------------------------------------
call gcloud auth print-access-token > NUL 2>&1
if %ERRORLEVEL% NEQ 0 (
    start /wait cmd /c "echo GCP CLI Token Expired. && echo Please log in via the browser window... && gcloud auth login && timeout 3"
)

call gcloud auth application-default print-access-token > NUL 2>&1
if %ERRORLEVEL% NEQ 0 (
    start /wait cmd /c "echo GCP Terraform Token Expired. && echo Please log in via the browser window... && gcloud auth application-default login && timeout 3"
)

:: -------------------------------------------------------------------------
:: PHASE 2: SSH Polling Loop (Wait up to 300 seconds for boot)
:: -------------------------------------------------------------------------
set MAX_WAIT=300
set CURRENT_WAIT=0

:POLL_LOOP
:: Try a silent, non-blocking SSH command. 
call ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=2 coder.%WORKSPACE% "exit" > NUL 2>&1

:: If ErrorLevel is 0, the SSH connection succeeded! Server is fully booted.
if %ERRORLEVEL% EQU 0 (
    goto SERVER_READY
)

:: Wait 1 second and try again
timeout /t 1 /nobreak > NUL
set /a CURRENT_WAIT+=1

if %CURRENT_WAIT% GEQ %MAX_WAIT% (
    exit
)
goto POLL_LOOP


:: -------------------------------------------------------------------------
:: PHASE 3: Push Credentials
:: -------------------------------------------------------------------------
:SERVER_READY

:: Create directory
call ssh -q -o StrictHostKeyChecking=no coder.%WORKSPACE% "mkdir -p ~/.config/gcloud"

:: Push the files
call scp -q -o StrictHostKeyChecking=no "%APPDATA%\gcloud\credentials.db" "coder.%WORKSPACE%:~/.config/gcloud/"
if exist "%APPDATA%\gcloud\application_default_credentials.json" (
    call scp -q -o StrictHostKeyChecking=no "%APPDATA%\gcloud\application_default_credentials.json" "coder.%WORKSPACE%:~/.config/gcloud/"
)

exit