# 🚀 Apache Monitor Pro

> **Monitoramento inteligente de servidores Apache com reinicialização automática e notificações em tempo real**

[![.NET](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/download)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Windows Service](https://img.shields.io/badge/Windows-Service-brightgreen.svg)](https://docs.microsoft.com/en-us/dotnet/core/extensions/windows-service)
[![Apache](https://img.shields.io/badge/Apache-Monitor-red.svg)](https://httpd.apache.org/)

## Sobre o Projeto

**Apache Monitor Pro** é uma solução profissional para monitoramento 24/7 de servidores Apache com capacidades de recuperação automática. Detecta automaticamente quando seu servidor Apache está offline e tenta reiniciá-lo automaticamente, mantendo você informado através de notificações Discord em tempo real.

### **Problema Resolvido**
- Servidores Apache que caem sem avisar
- Downtime prolongado por falta de monitoramento
- Intervenção manual necessária para reinicializar serviços
- Falta de visibilidade sobre status do servidor

### ✨ **Solução Oferecida**
- **Monitoramento contínuo** a cada 5 segundos
- **Detecção automática** do serviço Apache
- **Reinicialização inteligente** em caso de falha
- **Notificações instantâneas** via Discord
- **Zero configuração** - funciona out-of-the-box

## Funcionalidades

### **Monitoramento Inteligente**
- ✅ Verificação HTTP a cada 5 segundos
- ✅ Detecção de timeout (30 segundos)
- ✅ Análise de códigos de resposta HTTP
- ✅ Medição de tempo de resposta

### **Recuperação Automática**
- ✅ Detecção automática do serviço Apache
- ✅ Reinicialização inteligente (até 3 tentativas)
- ✅ Suporte a Apache como serviço ou processo
- ✅ Delay configurável entre tentativas

### **Notificações em Tempo Real**
- ✅ Integração nativa com Discord
- ✅ Alertas de servidor offline/online
- ✅ Status de reinicializações
- ✅ Relatórios de inicialização/parada

### **Facilidade de Uso**
- ✅ Windows Service nativo
- ✅ Instalação com 1 clique
- ✅ Auto-start com o Windows
- ✅ Logs profissionais no Event Viewer

## Instalação Rápida

### **Opção 1: Instalador Automático (Recomendado)**

1. **Baixe** a versão mais recente das [Releases](../../releases)
2. **Clique direito** em `Instalar.bat`
3. **Escolha** "Executar como administrador"
4. **Aguarde** a instalação automática
5. **Pronto!** O serviço estará rodando

### **Opção 2: PowerShell**

```powershell
# Clone o repositório
git clone https://github.com/SEU_USUARIO/apache-monitor-pro.git
cd apache-monitor-pro

# Execute a instalação
.\InstalarServico.ps1 -Action install
```

## ⚙️ Configuração

### **Configuração Básica**

Edite o arquivo `appsettings.json`:

```json
{
  "MonitoringSettings": {
    "Url": "https://seu-site.com",
    "IntervalSeconds": 5,
    "TimeoutSeconds": 30,
    "DiscordWebhook": "https://discord.com/api/webhooks/...",
    "EnableApacheRestart": true,
    "MaxRestartAttempts": 3
  }
}
```

### **Configuração do Discord**

1. Acesse seu servidor Discord
2. Vá em **Configurações do Servidor** → **Integrações**
3. Crie um **Webhook** para o canal desejado
4. Copie a URL do webhook
5. Cole no campo `DiscordWebhook` do arquivo de configuração

## 📊 Monitoramento e Logs

### **Verificar Status do Serviço**
```powershell
# Ver status
.\VerificarStatus.bat

# Ou via comando
sc query "Monitor K2Web Service"
```

### **Logs do Sistema**
- **Event Viewer**: Windows Logs → Application → "K2MonitoringService"
- **Discord**: Notificações em tempo real
- **Console**: Quando executado em modo debug

### **Comandos de Gerenciamento**
```powershell
# Iniciar serviço
sc start "Monitor K2Web Service"

# Parar serviço
sc stop "Monitor K2Web Service"

# Reiniciar serviço
sc stop "Monitor K2Web Service" && sc start "Monitor K2Web Service"

# Desinstalar
.\Desinstalar.bat
```

## 🔧 Desenvolvimento

### **Requisitos**
- .NET 8.0 SDK
- Windows 10/11 ou Windows Server 2016+
- Visual Studio 2022 (recomendado)
- Privilégios de administrador para teste

### **Compilar e Executar**
```bash
# Restaurar dependências
dotnet restore

# Compilar
dotnet build

# Executar em modo desenvolvimento
dotnet run

# Publicar versão release
dotnet publish -c Release --self-contained -r win-x64
```

### **Estrutura do Projeto**
```
StatusK2Web/
├── 📄 Program.cs              # Código principal do serviço
├── 📦 StatusK2Web.csproj      # Configuração do projeto
├── ⚙️ InstalarServico.ps1     # Script de instalação
├── 🔧 Instalar.bat           # Instalador rápido
├── 🗑️ Desinstalar.bat        # Desinstalador
├── 📊 VerificarStatus.bat     # Verificador de status
├── 📖 README.md              # Documentação
└── 📁 Deploy-V3/             # Pacotes de deployment
```

## 🎯 Casos de Uso

### **Ideal Para:**
- 🏢 **Empresas** com sites e aplicações críticas
- 🛒 **E-commerce** que não pode ficar offline
- 💼 **Agências web** gerenciando múltiplos clientes
- 🔧 **Administradores de sistema** com múltiplos servidores
- 🚀 **Startups** com recursos limitados de monitoramento

### **Cenários Comuns:**
- Apache trava por consumo excessivo de memória
- Falha de configuração após mudanças
- Problemas de conectividade temporários
- Sobrecarga de requisições simultâneas
- Atualizações que afetam o serviço

## 📈 Benefícios

| Antes | Depois |
|-------|--------|
| ❌ Descobrir problemas tarde demais | ✅ Alerta em 5 segundos |
| ❌ Intervenção manual sempre necessária | ✅ Recuperação automática |
| ❌ Sem visibilidade do status | ✅ Notificações em tempo real |
| ❌ Downtime prolongado | ✅ Máximo 35 segundos de downtime |
| ❌ Configuração complexa | ✅ Zero configuração |

## 🛡️ Segurança

- ✅ **Sem dados pessoais** coletados ou enviados
- ✅ **Webhooks criptografados** nas comunicações
- ✅ **Logs locais** apenas
- ✅ **Código-fonte aberto** para auditoria
- ✅ **Privilégios mínimos** necessários

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor:

1. **Fork** o repositório
2. **Crie** uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. **Push** para a branch (`git push origin feature/AmazingFeature`)
5. **Abra** um Pull Request

### **Diretrizes de Contribuição**
- Siga as convenções de código C#
- Adicione testes para novas funcionalidades
- Atualize a documentação quando necessário
- Use commit messages descritivas

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

### **Problemas Comuns**

<details>
<summary><strong>Serviço não inicia</strong></summary>

1. Verifique se executou como Administrador
2. Confira logs no Event Viewer
3. Teste executando `dotnet run` primeiro
4. Verifique se .NET 8 está instalado
</details>

<details>
<summary><strong>Discord não recebe mensagens</strong></summary>

1. Verifique URL do webhook
2. Teste webhook manualmente
3. Confirme conectividade com internet
4. Veja logs para erros específicos
</details>

<details>
<summary><strong>Apache não é detectado</strong></summary>

1. Verifique se Apache está instalado como serviço Windows
2. Confirme nomes de serviço em `possibleApacheNames`
3. Execute `sc query` para listar serviços
4. Veja logs de detecção para detalhes
</details>

### **Contato**
- 🐛 **Issues**: [GitHub Issues](../../issues)
- 💬 **Discussões**: [GitHub Discussions](../../discussions)
- 📧 **Email**: seu-email@exemplo.com

## 📊 Status do Projeto

- ✅ **Versão Estável**: v1.0.0
- 🔄 **Em Desenvolvimento**: Suporte a múltiplos servidores
- 📅 **Próximas Features**: Interface gráfica, suporte Nginx/IIS

---

<div align="center">

### ⭐ Se este projeto te ajudou, deixe uma estrela!

**Feito com ❤️ para administradores de sistema que valorizam uptime**

[⬆ Voltar ao topo](#-apache-monitor-pro)

</div>#   S e r v e r M o n i t o r  
 