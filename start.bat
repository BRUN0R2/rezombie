@echo off
setlocal EnableExtensions

set "SERVER_DIR=D:\ARQUIVOS IMPORTANTES\REPOSITORIOS\CS 1.6\REHLDS-Rezombie"
set "SERVER_EXE=%SERVER_DIR%\hlds.exe"
set "SERVER_PORT=27027"
set "RCON_PASSWORD=REDACTED_RCON_PASSWORD"
set "SERVER_MAP=de_dust2"

if not exist "%SERVER_EXE%" (
	echo ERROR: HLDS executable was not found: %SERVER_EXE%
	exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
	"$serverDir = '%SERVER_DIR%';" ^
	"$serverExe = '%SERVER_EXE%';" ^
	"$serverPort = %SERVER_PORT%;" ^
	"$portInUse = Get-NetUDPEndpoint -LocalPort $serverPort -ErrorAction SilentlyContinue;" ^
	"if ($portInUse) { Write-Host ('ERROR: Port ' + $serverPort + ' is already in use. Close the running server before starting.'); exit 1; }" ^
	"$arguments = @('-console', '-condebug', '-game', 'cstrike', '+sv_lan', '1', '+port', '%SERVER_PORT%', '+maxplayers', '32', '+rcon_password', '%RCON_PASSWORD%', '+map', '%SERVER_MAP%');" ^
	"$process = Start-Process -FilePath $serverExe -ArgumentList $arguments -WorkingDirectory $serverDir -WindowStyle Maximized -PassThru;" ^
	"Start-Sleep -Milliseconds 800;" ^
	"$shell = New-Object -ComObject WScript.Shell;" ^
	"$shell.AppActivate($process.Id) | Out-Null;" ^
	"Write-Host ('Started ReZombie server pid=' + $process.Id + ' port=' + $serverPort);"

if errorlevel 1 exit /b 1

exit /b 0
