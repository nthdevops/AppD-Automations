# Solicitação de admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

# Função para Unzip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Função para verificar e criar diretório
function Create {
	param ($dirPath)
	
	if(-not (Test-Path $dirPath)){
		New-Item -ItemType directory -Path $dirPath
	}
}

# A partir do diretório InstallFiles, declara as variáveis iniciais e cria os diretórios necessários
Set-Location "$PSScriptRoot\InstallFiles"
$machineDir = "$Env:ProgramData\AppDynamics\MachineAgent"
Create $machineDir
$machineAgentZip = Get-ChildItem ".\*machineagent*" -Name
$ADConfig = ".\AD_Config.xml"
$controllerInfo = ".\controller-info.xml"

# Faz unzip do machineagent e o instala
Unzip "$machineAgentZip" "$machineDir"
Copy-Item $controllerInfo -Destination "$machineDir\conf\" -Force
Start-Process "$machineDir\InstallService.vbs"

# Muda propriedade no registro do windows para não ter problemas na subida de serviços do windows com o agente
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control -Name ServicesPipeTimeout -Value 180000 -PropertyType DWORD -Force
# Copia o arquivo de configuração do instalador de .NET e instala o agente
Copy-Item $ADConfig ".\dotNetAgentSetup\AppDynamics\"
Start-Process ".\dotNetAgentSetup\Installer.bat"

# Restart dos serviços do AppDynamics
Restart-Service -Name "AppDynamics.Agent.Coordinator_service"
Restart-Service -Name "Appdynamics Machine Agent"

# Deleta o arquivo de configuração
Remove-Item ".\dotNetAgentSetup\AppDynamics\AD_Config.xml"