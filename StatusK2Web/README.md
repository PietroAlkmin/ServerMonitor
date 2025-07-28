# StatusK2Web - Monitor de Servidor Avan�ado

Monitor profissional para servidor K2Web com notifica��es Discord e reinicializa��o autom�tica do Apache.

## Principais Melhorias Implementadas

### Configura��o Externa
- Todas as configura��es movidas para `appsettings.json`
- Webhook Discord protegido (n�o mais hardcoded)
- Intervalo configur�vel (padr�o: 60 segundos)
- Configura��es do Apache externalizadas

### Seguran�a e Estabilidade
- Rate limiting para Discord (evita spam)
- Valida��o de configura��es na inicializa��o
- Logs sens�veis protegidos
- Tratamento robusto de erros

### Apache Management Avan�ado
- Detec��o autom�tica de m�ltiplos tipos de Apache
- Suporte para Apache como servi�o Windows
- Suporte para Apache como processo direto (httpd.exe)
- Reinicializa��o inteligente com retry logic
- Limite m�ximo de tentativas (padr�o: 3)

## Estrutura de Arquivos
StatusK2Web/
??? Program.cs              # C�digo principal melhorado
??? StatusK2Web.csproj      # Configura��o do projeto
??? appsettings.json        # Configura��es externas
??? InstalarServico.ps1     # Script de instala��o avan�ado
??? Instalar.bat            # Instalador r�pido
??? README.md               # Documenta��o atualizada

## Configura��o (appsettings.json){
  "Monitoring": {
    "Url": "https://k2datacenter.com.br/k2web.dll#",
    "IntervalSeconds": 60,
    "TimeoutSeconds": 30
  },
  "Discord": {
    "WebhookUrl": "COLE_SEU_WEBHOOK_AQUI",
    "RateLimitMinutes": 1
  },
  "Apache": {
    "EnableRestart": true,
    "RestartDelaySeconds": 30,
    "MaxRestartAttempts": 3
  }
}
### Configurando o Discord
1. Abra o arquivo `appsettings.json`
2. Cole seu webhook no campo `WebhookUrl`
3. Salve o arquivo
4. Reinstale o servi�o com `Instalar.bat`

## Instala��o

### M�todo 1: Instala��o R�pida
Execute como Administrador:Instalar.bat
### M�todo 2: PowerShell Avan�ado
Execute como Administrador:PowerShell -ExecutionPolicy Bypass -File InstalarServico.ps1 -Action install
## Funcionalidades

### Monitoramento Inteligente
- Verifica��o HTTP com timeout configur�vel
- Detec��o de servidor offline, lento ou inacess�vel
- Monitoramento cont�nuo com intervalo configur�vel
- Logs detalhados no Event Viewer

### Notifica��es Discord
- Mensagem de inicializa��o do servi�o
- Alertas de servidor offline/lento
- Confirma��o de recupera��o
- Status de reinicializa��o do Apache
- Rate limiting autom�tico (evita spam)

### Gerenciamento do Apache
- Detec��o autom�tica de instala��es Apache
- M�ltiplos nomes suportados: Apache24, ApacheHTTPServer, httpd, etc.
- Reinicializa��o inteligente em caso de problemas
- Processo direto ou servi�o Windows
- Retry logic com limite de tentativas

## Tipos de Apache Suportados

| Tipo                | M�todo de Detec��o   | M�todo de Rein�cio           |
|---------------------|---------------------|------------------------------|
| Servi�o Windows     | Nome do servi�o     | `net stop/start`             |
| Processo Direto     | httpd.exe           | Kill/Restart processo        |
| XAMPP               | Apache24            | `net stop/start Apache24`    |
| Apache HTTP Server  | ApacheHTTPServer    | `net stop/start`             |

## Comandos de Gerenciamento

- Status do Servi�o:sc query "MonitorK2Web"- Parar Servi�o:sc stop "MonitorK2Web"- Iniciar Servi�o:sc start "MonitorK2Web"- Desinstalar:sc delete "MonitorK2Web"- Ver Logs:
  1. Event Viewer ? Windows Logs ? Application
  2. Procurar por: "K2MonitoringService"

## Troubleshooting

### Servi�o n�o inicia
- Verificar configura��o:Get-Content appsettings.json- Testar manualmente:dotnet run- Ver logs detalhados:Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='K2MonitoringService'}
### Discord n�o funciona
- Verificar `appsettings.json`:{
  "Discord": {
    "WebhookUrl": "https://discord.com/api/webhooks/..." // Deve estar preenchido
    }
  }
### Apache n�o � detectado
- Verificar servi�os Apache manualmente:sc query | findstr /i apache
sc query | findstr /i httpd- Verificar processos:tasklist | findstr /i httpd
## Melhorias de Performance

### Antes
- Verifica��o a cada 5 segundos (muito agressivo)
- Configura��es hardcoded
- Sem rate limiting no Discord
- Webhook exposto no c�digo

### Depois
- Verifica��o configur�vel (padr�o: 60 segundos)
- Configura��es externas e seguras
- Rate limiting autom�tico
- Valida��o de configura��es
- Logs protegidos

## Exemplo de Mensagens Discord

### Inicializa��oSERVI�O MONITOR K2 INICIADO
Monitorando: https://k2datacenter.com.br/k2web.dll#
Servidor ONLINE na inicializa��o
Tempo de resposta: 1200ms
16/01/2025 14:30:15
Verificando a cada 60 segundos
Apache Restart: Habilitado
Apache Detectado: Apache24
### Reinicializa��o do ApacheREINICIANDO APACHE
Tentativa: 1/3
M�todo: Servi�o Apache24
16/01/2025 14:35:22

APACHE REINICIADO COM SUCESSO
M�todo: Servi�o Apache24
Tentativa: 1/3
16/01/2025 14:35:45
Aguardando pr�xima verifica��o para confirmar recupera��o...
## Configura��es de Seguran�a

### Recomenda��es
1. Manter appsettings.json seguro (n�o compartilhar webhook)
2. Executar sempre como Administrador
3. Configurar firewall para permitir conex�es HTTP
4. Monitorar logs regularmente
5. Backup das configura��es

---

## Suporte

Para problemas ou d�vidas:
1. Verificar logs no Event Viewer
2. Testar configura��o com `dotnet run`
3. Verificar permiss�es de Administrador
4. Validar webhook do Discord manualmente