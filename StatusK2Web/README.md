# StatusK2Web - Monitor de Servidor Avançado

Monitor profissional para servidor K2Web com notificações Discord e reinicialização automática do Apache.

## Principais Melhorias Implementadas

### Configuração Externa
- Todas as configurações movidas para `appsettings.json`
- Webhook Discord protegido (não mais hardcoded)
- Intervalo configurável (padrão: 60 segundos)
- Configurações do Apache externalizadas

### Segurança e Estabilidade
- Rate limiting para Discord (evita spam)
- Validação de configurações na inicialização
- Logs sensíveis protegidos
- Tratamento robusto de erros

### Apache Management Avançado
- Detecção automática de múltiplos tipos de Apache
- Suporte para Apache como serviço Windows
- Suporte para Apache como processo direto (httpd.exe)
- Reinicialização inteligente com retry logic
- Limite máximo de tentativas (padrão: 3)

## Estrutura de Arquivos
StatusK2Web/
??? Program.cs              # Código principal melhorado
??? StatusK2Web.csproj      # Configuração do projeto
??? appsettings.json        # Configurações externas
??? InstalarServico.ps1     # Script de instalação avançado
??? Instalar.bat            # Instalador rápido
??? README.md               # Documentação atualizada

## Configuração (appsettings.json){
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
4. Reinstale o serviço com `Instalar.bat`

## Instalação

### Método 1: Instalação Rápida
Execute como Administrador:Instalar.bat
### Método 2: PowerShell Avançado
Execute como Administrador:PowerShell -ExecutionPolicy Bypass -File InstalarServico.ps1 -Action install
## Funcionalidades

### Monitoramento Inteligente
- Verificação HTTP com timeout configurável
- Detecção de servidor offline, lento ou inacessível
- Monitoramento contínuo com intervalo configurável
- Logs detalhados no Event Viewer

### Notificações Discord
- Mensagem de inicialização do serviço
- Alertas de servidor offline/lento
- Confirmação de recuperação
- Status de reinicialização do Apache
- Rate limiting automático (evita spam)

### Gerenciamento do Apache
- Detecção automática de instalações Apache
- Múltiplos nomes suportados: Apache24, ApacheHTTPServer, httpd, etc.
- Reinicialização inteligente em caso de problemas
- Processo direto ou serviço Windows
- Retry logic com limite de tentativas

## Tipos de Apache Suportados

| Tipo                | Método de Detecção   | Método de Reinício           |
|---------------------|---------------------|------------------------------|
| Serviço Windows     | Nome do serviço     | `net stop/start`             |
| Processo Direto     | httpd.exe           | Kill/Restart processo        |
| XAMPP               | Apache24            | `net stop/start Apache24`    |
| Apache HTTP Server  | ApacheHTTPServer    | `net stop/start`             |

## Comandos de Gerenciamento

- Status do Serviço:sc query "MonitorK2Web"- Parar Serviço:sc stop "MonitorK2Web"- Iniciar Serviço:sc start "MonitorK2Web"- Desinstalar:sc delete "MonitorK2Web"- Ver Logs:
  1. Event Viewer ? Windows Logs ? Application
  2. Procurar por: "K2MonitoringService"

## Troubleshooting

### Serviço não inicia
- Verificar configuração:Get-Content appsettings.json- Testar manualmente:dotnet run- Ver logs detalhados:Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='K2MonitoringService'}
### Discord não funciona
- Verificar `appsettings.json`:{
  "Discord": {
    "WebhookUrl": "https://discord.com/api/webhooks/..." // Deve estar preenchido
    }
  }
### Apache não é detectado
- Verificar serviços Apache manualmente:sc query | findstr /i apache
sc query | findstr /i httpd- Verificar processos:tasklist | findstr /i httpd
## Melhorias de Performance

### Antes
- Verificação a cada 5 segundos (muito agressivo)
- Configurações hardcoded
- Sem rate limiting no Discord
- Webhook exposto no código

### Depois
- Verificação configurável (padrão: 60 segundos)
- Configurações externas e seguras
- Rate limiting automático
- Validação de configurações
- Logs protegidos

## Exemplo de Mensagens Discord

### InicializaçãoSERVIÇO MONITOR K2 INICIADO
Monitorando: https://k2datacenter.com.br/k2web.dll#
Servidor ONLINE na inicialização
Tempo de resposta: 1200ms
16/01/2025 14:30:15
Verificando a cada 60 segundos
Apache Restart: Habilitado
Apache Detectado: Apache24
### Reinicialização do ApacheREINICIANDO APACHE
Tentativa: 1/3
Método: Serviço Apache24
16/01/2025 14:35:22

APACHE REINICIADO COM SUCESSO
Método: Serviço Apache24
Tentativa: 1/3
16/01/2025 14:35:45
Aguardando próxima verificação para confirmar recuperação...
## Configurações de Segurança

### Recomendações
1. Manter appsettings.json seguro (não compartilhar webhook)
2. Executar sempre como Administrador
3. Configurar firewall para permitir conexões HTTP
4. Monitorar logs regularmente
5. Backup das configurações

---

## Suporte

Para problemas ou dúvidas:
1. Verificar logs no Event Viewer
2. Testar configuração com `dotnet run`
3. Verificar permissões de Administrador
4. Validar webhook do Discord manualmente