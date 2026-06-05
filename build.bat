@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
for %%I in ("%ROOT%..\..") do set "CS_ROOT=%%~fI"

set "COMPILER=%CS_ROOT%\Compiler\amxxpc.exe"
set "COMPILER_INCLUDE=%CS_ROOT%\Compiler\include"
set "PROJECT_INCLUDE=%ROOT%include"
set "PACKAGE_ROOT=%ROOT%build\cstrike"
set "PLUGIN_ROOT=%PACKAGE_ROOT%\addons\amxmodx\plugins\rezombie"
set "PLUGIN_API_DIR=%PLUGIN_ROOT%\api"
set "PLUGIN_CLASSES_DIR=%PLUGIN_ROOT%\classes"
set "PLUGIN_CORE_DIR=%PLUGIN_ROOT%\core"
set "PLUGIN_DEV_DIR=%PLUGIN_ROOT%\dev"
set "PLUGIN_GAMEMODES_DIR=%PLUGIN_ROOT%\gamemodes"
set "PLUGIN_HUD_DIR=%PLUGIN_ROOT%\hud"
set "CONFIG_DIR=%PACKAGE_ROOT%\addons\amxmodx\configs"
set "PLUGIN_CONFIG=%CONFIG_DIR%\plugins-rezombie.ini"
set "DEV_PLUGIN_CONFIG=%CONFIG_DIR%\plugins-rezombie-dev.ini"
set "RESOURCES_DIR=%ROOT%resources"

if not exist "%COMPILER%" (
	echo ERROR: AMX Mod X compiler was not found: %COMPILER%
	exit /b 1
)

if not exist "%PROJECT_INCLUDE%\rezombie.inc" (
	echo ERROR: Project includes were not found: %PROJECT_INCLUDE%
	exit /b 1
)

if exist "%PACKAGE_ROOT%" (
	rmdir /s /q "%PACKAGE_ROOT%"
	if errorlevel 1 (
		echo ERROR: Failed to clean build package: %PACKAGE_ROOT%
		exit /b 1
	)
)

call :EnsureDirectory "%PLUGIN_API_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%PLUGIN_CLASSES_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%PLUGIN_CORE_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%PLUGIN_DEV_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%PLUGIN_GAMEMODES_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%PLUGIN_HUD_DIR%"
if errorlevel 1 exit /b 1

call :EnsureDirectory "%CONFIG_DIR%"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiProps.sma
"%COMPILER%" "%ROOT%src\api\ApiProps.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiProps.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiModels.sma
"%COMPILER%" "%ROOT%src\api\ApiModels.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiModels.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiWeapons.sma
"%COMPILER%" "%ROOT%src\api\ApiWeapons.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiWeapons.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiClasses.sma
"%COMPILER%" "%ROOT%src\api\ApiClasses.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiClasses.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiSubclasses.sma
"%COMPILER%" "%ROOT%src\api\ApiSubclasses.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiSubclasses.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiModes.sma
"%COMPILER%" "%ROOT%src\api\ApiModes.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiModes.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiGameVars.sma
"%COMPILER%" "%ROOT%src\api\ApiGameVars.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiGameVars.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\api\ApiPlayers.sma
"%COMPILER%" "%ROOT%src\api\ApiPlayers.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_API_DIR%\ApiPlayers.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\classes\Human.sma
"%COMPILER%" "%ROOT%src\classes\Human.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CLASSES_DIR%\Human.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\classes\Zombie.sma
"%COMPILER%" "%ROOT%src\classes\Zombie.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CLASSES_DIR%\Zombie.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\classes\ZombieFleshpound.sma
"%COMPILER%" "%ROOT%src\classes\ZombieFleshpound.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CLASSES_DIR%\ZombieFleshpound.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\gamemodes\Infection.sma
"%COMPILER%" "%ROOT%src\gamemodes\Infection.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_GAMEMODES_DIR%\Infection.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\core\GameCvars.sma
"%COMPILER%" "%ROOT%src\core\GameCvars.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CORE_DIR%\GameCvars.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\core\MapObjectives.sma
"%COMPILER%" "%ROOT%src\core\MapObjectives.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CORE_DIR%\MapObjectives.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\core\SpawnPoints.sma
"%COMPILER%" "%ROOT%src\core\SpawnPoints.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CORE_DIR%\SpawnPoints.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\core\PlayerAdmission.sma
"%COMPILER%" "%ROOT%src\core\PlayerAdmission.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CORE_DIR%\PlayerAdmission.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\core\GameRules.sma
"%COMPILER%" "%ROOT%src\core\GameRules.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_CORE_DIR%\GameRules.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\hud\RoundFeedback.sma
"%COMPILER%" "%ROOT%src\hud\RoundFeedback.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_HUD_DIR%\RoundFeedback.amxx"
if errorlevel 1 exit /b 1

echo Compiling src\dev\DevRuntime.sma
"%COMPILER%" "%ROOT%src\dev\DevRuntime.sma" "-i%PROJECT_INCLUDE%" "-i%COMPILER_INCLUDE%" "-o%PLUGIN_DEV_DIR%\DevRuntime.amxx"
if errorlevel 1 exit /b 1

> "%PLUGIN_CONFIG%" echo ; ReZombie Plugins
>> "%PLUGIN_CONFIG%" echo ; Generated by build.bat.
>> "%PLUGIN_CONFIG%" echo.
>> "%PLUGIN_CONFIG%" echo ; APIs
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiProps.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiModels.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiWeapons.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiClasses.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiSubclasses.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiModes.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiGameVars.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/api/ApiPlayers.amxx
>> "%PLUGIN_CONFIG%" echo.
>> "%PLUGIN_CONFIG%" echo ; Classes
>> "%PLUGIN_CONFIG%" echo rezombie/classes/Human.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/classes/Zombie.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/classes/ZombieFleshpound.amxx
>> "%PLUGIN_CONFIG%" echo.
>> "%PLUGIN_CONFIG%" echo ; Game Modes
>> "%PLUGIN_CONFIG%" echo rezombie/gamemodes/Infection.amxx
>> "%PLUGIN_CONFIG%" echo.
>> "%PLUGIN_CONFIG%" echo ; Core
>> "%PLUGIN_CONFIG%" echo rezombie/core/GameCvars.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/core/MapObjectives.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/core/SpawnPoints.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/core/PlayerAdmission.amxx
>> "%PLUGIN_CONFIG%" echo rezombie/core/GameRules.amxx
>> "%PLUGIN_CONFIG%" echo.
>> "%PLUGIN_CONFIG%" echo ; HUD
>> "%PLUGIN_CONFIG%" echo rezombie/hud/RoundFeedback.amxx
if errorlevel 1 (
	echo ERROR: Failed to write plugin config: %PLUGIN_CONFIG%
	exit /b 1
)

> "%DEV_PLUGIN_CONFIG%" echo ; ReZombie Dev Plugins
>> "%DEV_PLUGIN_CONFIG%" echo ; Generated by build.bat.
>> "%DEV_PLUGIN_CONFIG%" echo ; Load only on local validation servers.
>> "%DEV_PLUGIN_CONFIG%" echo.
>> "%DEV_PLUGIN_CONFIG%" echo rezombie/dev/DevRuntime.amxx debug
if errorlevel 1 (
	echo ERROR: Failed to write dev plugin config: %DEV_PLUGIN_CONFIG%
	exit /b 1
)

if exist "%RESOURCES_DIR%" (
	xcopy "%RESOURCES_DIR%\*" "%PACKAGE_ROOT%\" /E /I /Y >nul
	if errorlevel 1 (
		echo ERROR: Failed to copy resources from: %RESOURCES_DIR%
		exit /b 1
	)
)

echo Build completed: %PACKAGE_ROOT%
exit /b 0

:EnsureDirectory
mkdir "%~1" >nul 2>nul
if errorlevel 1 (
	echo ERROR: Failed to create directory: %~1
	exit /b 1
)
exit /b 0
