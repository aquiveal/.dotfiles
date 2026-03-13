@echo off
:: CIRCUIT BREAKER: Prevent recursive loops
if "%CODER_SYNC_RUNNING%"=="1" goto RUN_CODER

:: Create a tiny, temporary VBScript to launch the sync script in absolute stealth mode (0 = Hidden)
echo Set objShell = WScript.CreateObject("WScript.Shell") > "%TEMP%\coder_sync_launcher.vbs"
echo objShell.Run "cmd /c C:\Users\aquiv\.ssh\sync-gcloud.bat %1", 0, False >> "%TEMP%\coder_sync_launcher.vbs"

:: Execute the stealth launcher
cscript //nologo "%TEMP%\coder_sync_launcher.vbs"

:RUN_CODER
:: Establish the VS Code tunnel
"C:\Program Files\Coder\bin\coder.exe" --global-config "C:\Users\aquiv\AppData\Roaming\coderv2" ssh --stdio --hostname-suffix coder %1
exit /b