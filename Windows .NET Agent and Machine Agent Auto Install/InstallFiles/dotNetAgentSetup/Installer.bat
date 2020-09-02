@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

REM The value of this path will be changed during build to use the version stamped msi file.

dir "%~dp0AppDynamics" /b | findstr "dotNetAgentSetup" > temp
SET /p msi_path=<temp
del temp
set msi_path=%~dp0AppDynamics\!msi_path!


REM Verify msi exists
IF NOT EXIST !msi_path! (
	ECHO Installer not found at !msi_path!
	ECHO.
	GOTO END
)

REM Verify config file exists
IF NOT EXIST "%~dp0AppDynamics\AD_Config.xml" (
	ECHO Configuration file not found
	ECHO.
	GOTO END
)

REM Do nothing if other profiler is installed
IF NOT "!COR_PROFILER!"=="" (
	IF NOT "!COR_PROFILER!"=="AppDynamics.AgentProfiler" (
		ECHO COR_PROFILER is set. Please uninstall existing profiler and try again
		ECHO.
		GOTO :END
	) ELSE (
		ECHO Found existing AppDynamics .NET agent. Uninstall and try again or use msi file directly.
		ECHO.
		GOTO :END
	)
)

REM Set default
IF DEFINED PROGRAMFILES (
	SET AGENT_FOLDER="%PROGRAMFILES%\AppDynamics\DotNetAgent"
) ELSE (
	SET AGENT_FOLDER="%ALLUSERSPROFILE%\Application Data\AppDynamics\DotNetAgent"
)

set DotNetAgentFolder=%AGENT_FOLDER%

IF EXIST "%DotNetAgentFolder%\Config\config.xml" (
	ECHO Installing AppDynamics .NET agent in %DotNetAgentFolder%
	ECHO.
	START /WAIT MSIEXEC /i !msi_path! /q /norestart /lv "AgentInstaller.log"
	IF !ERRORLEVEL!==0 (
		GOTO RESTARTCOORDINATOR
	) ELSE (
		ECHO Failed with ERRORCODE:!ERRORLEVEL!
		ECHO.
		GOTO END
	)
) ELSE (
	ECHO Installing AppDynamics .NET agent...
	ECHO.
	START /WAIT MSIEXEC /i !msi_path! /q /norestart /lv "AgentInstaller.log" AD_SetupFile="%~dp0AppDynamics\AD_Config.xml"
	IF !ERRORLEVEL!==0 (
		GOTO RESTARTCOORDINATOR
	) ELSE (
		ECHO Failed with ERRORCODE:!ERRORLEVEL!
		ECHO.
		GOTO END
	)
)

:RESTARTCOORDINATOR
SET APPD_SERVICE=AppDynamics.Agent.Coordinator_service
FOR /F "tokens=3 delims=: " %%H IN ('sc query "%APPD_SERVICE%" ^| findstr "STATE"') DO (
  IF /I "%%H" EQU "RUNNING" (
   NET STOP %APPD_SERVICE%
  )
)
NET START %APPD_SERVICE%

ECHO.
ECHO AppDynamics .NET agent has been successfully installed!
ECHO.
ECHO Please reset IIS, console applications and windows services to start monitoring
ECHO.


:END
ECHO Press any key to exit
ECHO.