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

    [System.IO.Compression.ZipFile]::ExtractToDirectory("$zipfile", "$outpath")
}

# Função para verificar e criar diretório
function Create {
	param ($dirPath)
	
	if(-not (Test-Path "$dirPath")){
		New-Item -ItemType directory -Path "$dirPath" | Out-Null
	}
}

# A partir do diretório InstallFiles, declara as variáveis iniciais e cria os diretórios necessários
Write-Host Setting up agent installation..
$installFiles = "$PSScriptRoot\InstallFiles\"
Set-Location "$installFiles"
$machineDir = "$Env:ProgramFiles\AppDynamics\MachineAgent"
Create $machineDir
$machineAgentZip = Get-ChildItem ".\*machineagent*" -Name
$machineAgentZip = "$installFiles" + "$machineAgentZip"
$controllerInfo = "$installFiles"+"controller-info.xml"

if (-not (Test-Path "$machineAgentZip")){
  Write-Host Missing machineagent zip file
  Break
}

if (-not (Test-Path "$controllerInfo")){
  Write-Host Missing configuration file controller-info.xml
  Break
}

# Faz unzip do machineagent e o instala
Write-Host Unzipping Machine Agent Files..
Unzip "$machineAgentZip" "$machineDir"
Copy-Item $controllerInfo -Destination "$machineDir\conf\" -Force
Write-Host Installing Machine Agent..
Start-Process "$machineDir\InstallService.vbs" -Wait

Write-Host Installation finished!
Pause