# .NET Agent and Machine Agent Auto Installing

## Preparação para execução:

### Alterar os arquivos AD_Config.xml (.NET Agent) e controller-info.xml (Machine Agent)

**Basta alterar para ambos as informações do controller, application, etc.**

### Alteração da versão dos agentes

**Para a instalação do Machine Agent deve ser substituido o arquivo zip do machine agent dentro do diretório InstallFiles (Apenas um arquivo deve estar no diretório), mantendo o inicio do nome do zip machineagent**

**Para a instalação do .NET Agent, basta trocar o arquivo msi dentro do diretório InstallFiles/dotNetAgentSetup/AppDynamics (Apenas um arquivo deve estar no diretório), mantendo o inicio do nome do msi dotNetAgentSetup**