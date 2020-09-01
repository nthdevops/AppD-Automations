@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS
ECHO Verifying installer package...
ECHO.

REM The value of this path will be changed during build to use the version stamped msi file.
SET msi_path="%~dp0AppDynamics\dotNetAgentSetup.msi"


REM Verify msi exists
IF EXIST !msi_path! (
	ECHO Installer file found
) ELSE (
	ECHO Installer not found at !msi_path!
	GOTO END
)

REM Verify config file exists
IF EXIST "%~dp0AppDynamics\AD_Config.xml" (
	ECHO Configuration file found
) ELSE (
	ECHO Configuration file not found
	GOTO END
)

ECHO.
ECHO Installer package verified
ECHO.

REM Do nothing if other profiler is installed
IF NOT "!COR_PROFILER!"=="" (
	IF NOT "!COR_PROFILER!"=="AppDynamics.AgentProfiler" (
		ECHO COR_PROFILER is set. Please uninstall existing profiler and try again
		GOTO :END
	) ELSE (
		ECHO Found existing AppDynamics .NET agent. Uninstall and try again or use msi file directly.
		GOTO :END
	)
)

REM Keep existing configuration if found.

REM Set default
IF DEFINED PROGRAMDATA (
	SET AGENT_FOLDER="%PROGRAMDATA%\AppDynamics\DotNetAgent"
) ELSE (
	SET AGENT_FOLDER="%ALLUSERSPROFILE%\Application Data\AppDynamics\DotNetAgent"
)

REM Look at the previous Environment variable
IF DEFINED DotNetAgentFolder (
	IF EXIST "%DotNetAgentFolder%\Config\config.xml" (
		SET AGENT_FOLDER="%DotNetAgentFolder%"
	)
)

REM Look for previous in the registry
SET REGKEY="HKEY_LOCAL_MACHINE\Software\AppDynamics\dotNet Agent"
SET REGVALNAME=DotNetAgentFolder
SET REG_DOTNET_FOLDER=
FOR /F "tokens=2*" %%A IN ('REG QUERY %REGKEY% /v %REGVALNAME%') DO SET REG_DOTNET_FOLDER=%%B
IF DEFINED REG_DOTNET_FOLDER (
	IF EXIST "%REG_DOTNET_FOLDER%\Config\config.xml" (
		SET AGENT_FOLDER="%REG_DOTNET_FOLDER%"
	)
)

set DotNetAgentFolder=%AGENT_FOLDER%

IF EXIST "%DotNetAgentFolder%\Config\config.xml" (
	ECHO Installing AppDynamics .NET agent with existing configuration...
	ECHO in %DotNetAgentFolder%
	START /WAIT MSIEXEC /i !msi_path! /q /norestart /lv "AgentInstaller.log"
	IF !ERRORLEVEL!==0 (
		GOTO RESTARTCOORDINATOR
	) ELSE (
		ECHO Failed with ERRORCODE:!ERRORLEVEL!
		GOTO END
	)
) ELSE (
	ECHO Installing AppDynamics .NET agent...
	START /WAIT MSIEXEC /i !msi_path! /q /norestart /lv "AgentInstaller.log" AD_SetupFile="%~dp0AppDynamics\AD_Config.xml"
	IF !ERRORLEVEL!==0 (
		GOTO RESTARTCOORDINATOR
	) ELSE (
		ECHO Failed with ERRORCODE:!ERRORLEVEL!
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

ECHO AppDynamics .NET agent has been successfully installed! 
ECHO Please reset IIS, console applications and windows services to start monitoring


:END
ECHO Press any key to exit
PAUSE>NUL
