# ?? Monitor K2Web - Deploy para Servidor

## ?? Conteúdo do Pacote

- **InstalarServidor.bat** - Instalador principal (execute como admin)
- **DesinstalarServidor.bat** - Remove o serviço 
- **StatusServidor.bat** - Verifica status do serviço
- **Executavel/** - Aplicação compilada
- **Scripts/** - Scripts PowerShell de instalação

## ?? Instalação no Servidor

### Pré-requisitos
- ? Windows Server 2016+ ou Windows 10+
- ? Privilégios de Administrador
- ? Conexão com internet para Discord
- ? .NET 8 Runtime (incluído no pacote)

### Passos de Instalação

1. **Copie esta pasta completa** para o servidor
2. **Clique direito** em InstalarServidor.bat  
3. **Escolha** "Executar como administrador"
4. **Aguarde** a instalação automática
5. **Verifique** se recebeu mensagem no Discord

### Verificação da Instalação
# Ver se está rodando
sc query "MonitorK2Web"

# Ver logs
Event Viewer ? Windows Logs ? Application ? Procurar "K2MonitoringService"

# Gerenciador de Serviços  
services.msc ? Procurar "Monitor K2Web Service"
## ?? Configurações

### URLs e Configurações Atuais
- **URL Monitorada:** https://k2datacenter.com.br/k2web.dll#
- **Intervalo:** 5 minutos
- **Timeout:** 30 segundos  
- **Discord:** Webhook configurado

### Para Alterar Configurações
1. Edite o código fonte no desenvolvimento
2. Gere novo pacote de deploy
3. Execute DesinstalarServidor.bat
4. Copie nova versão
5. Execute InstalarServidor.bat

## ?? Troubleshooting

### Serviço não inicia
1. Verifique logs no Event Viewer
2. Execute StatusServidor.bat
3. Teste conectividade com a URL
4. Verifique firewall/antivírus

### Discord não recebe mensagens  
1. Teste webhook manualmente
2. Verifique conectividade com internet
3. Confirme URL do webhook no código

## ?? Suporte

- **Logs:** Event Viewer ? Application ? K2MonitoringService
- **Status:** StatusServidor.bat
- **Reinstalar:** DesinstalarServidor.bat + InstalarServidor.bat

---
**Pacote gerado em:** 21/07/2025 10:17:26
**Servidor de destino:** Servidor-Producao
