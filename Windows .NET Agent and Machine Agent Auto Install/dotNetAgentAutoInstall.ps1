# Solicitação de admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

# A partir do diretório InstallFiles, declara as variáveis iniciais e cria os diretórios necessários
Write-Host Setting up agent installation..
$installFiles = "$PSScriptRoot\InstallFiles\"
Set-Location $installFiles
$ADConfig = $installFiles+"AD_Config.xml"

if (-not (Test-Path $ADConfig)){
  Write-Host Missing configuration file AD_Config.xml
  Break
}

# Muda propriedade no registro do windows para não ter problemas na subida de serviços do windows com o agente
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control -Name ServicesPipeTimeout -Value 180000 -PropertyType DWORD -Force
# Copia o arquivo de configuração do instalador de .NET e instala o agente
Copy-Item $ADConfig $installFiles"dotNetAgentSetup\AppDynamics\" -Force
Write-Host Installing AppDynamics .NET Agent
Start-Process $installFiles"dotNetAgentSetup\Installer.bat" -Wait

# Deleta o arquivo de configuração
Remove-Item $installFiles"dotNetAgentSetup\AppDynamics\AD_Config.xml"

Write-Host Installation finished!
Pause