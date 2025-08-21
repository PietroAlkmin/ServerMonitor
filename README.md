# 🚀 Apache Monitor Pro

> **Monitoramento inteligente de servidores Apache com reinicialização automática e notificações em tempo real**

[![.NET](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/download)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Windows Service](https://img.shields.io/badge/Windows-Service-brightgreen.svg)](https://docs.microsoft.com/en-us/dotnet/core/extensions/windows-service)
[![Apache](https://img.shields.io/badge/Apache-Monitor-red.svg)](https://httpd.apache.org/)

---

## Sobre o Projeto

**Apache Monitor Pro** é uma solução profissional para **monitoramento 24/7 de servidores Apache**, com **recuperação automática** e **alertas em tempo real no Discord**.

Ele detecta quando o servidor Apache está **offline**, tenta **reiniciá-lo automaticamente** e mantém você informado sobre cada evento.

---

## Problemas Resolvidos

* Servidores Apache caindo sem aviso
* Downtime prolongado por falta de monitoramento
* Intervenção manual necessária para reinicializar serviços
* Ausência de visibilidade sobre o status do servidor

---

## Solução

* **Monitoramento contínuo** a cada 5 segundos
* **Detecção automática** de falhas no Apache
*  **Reinicialização inteligente** (até 3 tentativas)
*  **Notificações instantâneas** via Discord
*  **Zero configuração** – pronto para uso

---

## Funcionalidades

### Monitoramento Inteligente

* Verificação HTTP a cada 5s
* Timeout configurável (30s)
* Análise de códigos de resposta HTTP
* Medição de tempo de resposta

### Recuperação Automática

* Detecção do serviço Apache
* Reinicialização inteligente (até 3 tentativas)
* Suporte a execução como **serviço ou processo**
* Delay configurável entre tentativas

### Notificações em Tempo Real

* Integração nativa com Discord
* Alertas de servidor **offline/online**
* Status de reinicializações
* Relatórios de inicialização/parada

### ⚙️ Facilidade de Uso

* Instalação com **1 clique**
* **Windows Service** nativo (auto-start)
* Logs profissionais no **Event Viewer**

---

## Instalação

### Opção 1 – Instalador Automático (Recomendado)

1. Baixe a versão mais recente das [Releases](../../releases)
2. Clique direito em `Instalar.bat` → **Executar como administrador**
3. Aguarde a instalação
4. O serviço estará ativo 

### Opção 2 – PowerShell

```powershell
git clone https://github.com/SEU_USUARIO/apache-monitor-pro.git
cd apache-monitor-pro
.\InstalarServico.ps1 -Action install
```

---

## Configuração

### Arquivo `appsettings.json`

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

### Integração com Discord

1. Vá em **Configurações do Servidor → Integrações**
2. Crie um **Webhook**
3. Copie a URL
4. Cole no campo `DiscordWebhook`

---

## Monitoramento e Logs

### Verificar status do serviço

```powershell
.\VerificarStatus.bat
# ou
sc query "Monitor K2Web Service"
```

### Onde acompanhar logs

* **Event Viewer** → Windows Logs → Application → "K2MonitoringService"
* **Discord** → Notificações em tempo real
* **Console** → Modo debug

---

## Desenvolvimento

### Requisitos

* .NET 8.0 SDK
* Windows 10/11 ou Windows Server 2016+
* Visual Studio 2022 (recomendado)
* Privilégios de administrador

### Compilar e Executar

```bash
dotnet restore
dotnet build
dotnet run
dotnet publish -c Release --self-contained -r win-x64
```

---

## Casos de Uso

✅ Empresas com sites e aplicações críticas
✅ E-commerce que não pode ficar offline
✅ Agências web gerenciando múltiplos clientes
✅ Administradores de sistemas com múltiplos servidores
✅ Startups sem ferramentas caras de monitoramento

---

## Antes vs Depois

| Situação             | Antes          | Depois                       |
| -------------------- | -------------- | ---------------------------- |
| Descoberta de falhas | ❌ Tarde demais | ✅ Em 5 segundos              |
| Reinicialização      | ❌ Manual       | ✅ Automática                 |
| Visibilidade         | ❌ Nenhuma      | ✅ Notificações em tempo real |
| Downtime             | ❌ Prolongado   | ✅ Máx. 35 segundos           |
| Configuração         | ❌ Complexa     | ✅ Zero configuração          |

---

##  Segurança

* Sem coleta de dados pessoais
* Comunicação via **webhooks criptografados**
* Logs apenas **locais**
* Código aberto para auditoria
* Uso de **privilégios mínimos**

---

## Contribuindo

1. Fork do repositório
2. Crie uma branch (`feature/NovaFuncionalidade`)
3. Commit (`git commit -m "feat: adiciona NovaFuncionalidade"`)
4. Push (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

---

## 📄 Licença

Licenciado sob a **MIT License** → [LICENSE](LICENSE)

---

## 📊 Status do Projeto

* ✅ **Versão Estável**: v1.0.0
* 🔄 Em desenvolvimento: suporte a múltiplos servidores
* 📅 Próximas features: **interface gráfica, suporte a Nginx/IIS**

---
