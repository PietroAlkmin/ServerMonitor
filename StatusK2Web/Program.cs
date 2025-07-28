using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;
using System.Text.Json;

// CONFIGURAÇÃO DO WINDOWS SERVICE (GRATUITO)
var builder = Host.CreateApplicationBuilder(args);

// Adiciona configuração
builder.Configuration.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);

// Adiciona suporte a Windows Service
builder.Services.AddWindowsService(options =>
{
    options.ServiceName = "Monitor K2Web Service";
});

// Adiciona logging para arquivo (opcional)
builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddEventLog(); // Logs do Windows Event Viewer
});

// Registra nosso serviço de monitoramento
builder.Services.AddHostedService<K2MonitoringService>();

var host = builder.Build();

// Inicia o serviço
await host.RunAsync();

// CLASSE DO SERVIÇO DE MONITORAMENTO
public class K2MonitoringService : BackgroundService
{
    private readonly ILogger<K2MonitoringService> _logger;
    private readonly IConfiguration _configuration;
    
    // === CONFIGURAÇÕES DO SISTEMA (com fallbacks) ===
    private readonly string urlParameter;
    private readonly int interval;
    private readonly string webhookDiscord;
    
    // === CONFIGURAÇÕES DO APACHE ===
    private readonly bool enableApacheRestart;
    private readonly string[] possibleApacheNames = { "ApacheHTTPServer", "Apache24", "Apache", "Apache HTTP Server", "httpd" };
    private string? detectedApacheServiceName = null;
    private readonly int apacheRestartDelay = 30000; // 30 segundos de espera entre parar e iniciar
    private readonly int maxRestartAttempts = 3; // Máximo de tentativas de reinicialização
    
    private bool serverWasDown = false;
    private bool systemJustStarted = true;
    private int restartAttempts = 0;
    private DateTime lastDiscordMessage = DateTime.MinValue;
    private readonly int discordRateLimit = 60000; // 1 minuto entre mensagens para evitar spam

    public K2MonitoringService(ILogger<K2MonitoringService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        
        // Carregar configurações com fallbacks seguros
        urlParameter = _configuration["Monitoring:Url"] ?? "https://k2datacenter.com.br/k2web.dll#";
        interval = _configuration.GetValue<int>("Monitoring:IntervalSeconds", 60) * 1000; // Padrão: 60 segundos
        webhookDiscord = _configuration["Discord:WebhookUrl"] ?? "";
        enableApacheRestart = _configuration.GetValue<bool>("Apache:EnableRestart", true);
        
        // Validações básicas
        if (string.IsNullOrEmpty(webhookDiscord))
        {
            _logger.LogWarning("⚠️ Webhook Discord não configurado - notificações desabilitadas");
        }
        
        if (!Uri.TryCreate(urlParameter, UriKind.Absolute, out _))
        {
            _logger.LogError("❌ URL de monitoramento inválida: {Url}", urlParameter);
        }
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🚀 Serviço Monitor K2Web iniciado!");
        _logger.LogInformation("📡 Monitorando: {Url}", urlParameter);
        _logger.LogInformation("⏱️ Intervalo: {Interval} segundos", interval / 1000);
        
        // DETECTAR NOME DO APACHE AUTOMATICAMENTE
        await DetectApacheServiceName();
        
        _logger.LogInformation("🔧 Apache Restart: {Enabled} | Serviço: {ServiceName}", 
            enableApacheRestart ? "Habilitado" : "Desabilitado", 
            detectedApacheServiceName ?? "NÃO ENCONTRADO");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Verificando status do servidor K2Web...");

                using HttpClient client = new HttpClient();
                client.Timeout = TimeSpan.FromSeconds(30);

                var stopwatch = Stopwatch.StartNew();
                HttpResponseMessage response = await client.GetAsync(urlParameter, stoppingToken);
                stopwatch.Stop();

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("✅ Servidor online! Tempo: {Time}ms", stopwatch.ElapsedMilliseconds);

                    // MENSAGEM INICIAL quando serviço inicia
                    if (systemJustStarted)
                    {
                        _logger.LogInformation("📱 Enviando mensagem inicial para Discord...");
                        string apacheStatus = enableApacheRestart ? "✅ Habilitado" : "❌ Desabilitado";
                        string apacheInfo = detectedApacheServiceName ?? "❌ NÃO ENCONTRADO";
                        
                        await SendDiscordMessageSafe(
                            $"🚀 **SERVIÇO MONITOR K2 INICIADO** 🚀\n" +
                            $"📡 Monitorando: {urlParameter}\n" +
                            $"✅ Servidor ONLINE na inicialização\n" +
                            $"⏱️ Tempo de resposta: {stopwatch.ElapsedMilliseconds}ms\n" +
                            $"🕐 {DateTime.Now:dd/MM/yyyy HH:mm:ss}\n" +
                            $"🔄 Verificando a cada {interval / 1000} segundos\n" +
                            $"🔧 Apache Restart: {apacheStatus}\n" +
                            $"🔍 Apache Detectado: {apacheInfo}");
                        systemJustStarted = false;
                    }

                    // Servidor voltou após problema
                    if (serverWasDown)
                    {
                        _logger.LogInformation("🎉 Servidor recuperado!");
                        await SendDiscordMessageSafe($"✅ **SERVIDOR RECUPERADO**: {urlParameter} voltou online! - {DateTime.Now:HH:mm:ss}");
                        serverWasDown = false;
                        restartAttempts = 0; // Reset contador de tentativas
                    }
                }
                else
                {
                    // Servidor com problemas
                    _logger.LogWarning("❌ Servidor offline - Status: {Status}", response.StatusCode);

                    if (systemJustStarted)
                    {
                        await SendDiscordMessageSafe(
                            $"🚀 **SERVIÇO MONITOR K2 INICIADO** 🚀\n" +
                            $"📡 Monitorando: {urlParameter}\n" +
                            $"❌ Servidor OFFLINE na inicialização\n" +
                            $"🔍 Status: {response.StatusCode}\n" +
                            $"🕐 {DateTime.Now:dd/MM/yyyy HH:mm:ss}");
                        systemJustStarted = false;
                    }

                    if (!serverWasDown)
                    {
                        _logger.LogError("🚨 ALERTA: Servidor caiu!");
                        await SendDiscordMessageSafe($"🚨 **SERVIDOR OFFLINE**: {urlParameter} - Status: {response.StatusCode} - {DateTime.Now:HH:mm:ss}");
                        
                        // NOVA FUNCIONALIDADE: Reiniciar Apache automaticamente
                        if (enableApacheRestart && detectedApacheServiceName != null && restartAttempts < maxRestartAttempts)
                        {
                            await HandleApacheRestart(stoppingToken);
                        }
                        else if (detectedApacheServiceName == null)
                        {
                            _logger.LogError("⚠️ Apache não detectado - reinicialização desabilitada");
                            await SendDiscordMessageSafe($"⚠️ **APACHE NÃO DETECTADO**: Reinicialização automática não disponível. Verificação manual necessária.");
                        }
                        else if (restartAttempts >= maxRestartAttempts)
                        {
                            _logger.LogError("⚠️ Máximo de tentativas de reinicialização atingido ({MaxAttempts})", maxRestartAttempts);
                            await SendDiscordMessageSafe($"⚠️ **LIMITE DE REINICIALIZAÇÕES ATINGIDO**: {maxRestartAttempts} tentativas falharam. Intervenção manual necessária.");
                        }
                        
                        serverWasDown = true;
                    }
                }
            }
            catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
            {
                _logger.LogWarning("⏰ Timeout no servidor (30+ segundos)");
                
                if (systemJustStarted)
                {
                    await SendDiscordMessageSafe(
                        $"🚀 **SERVIÇO MONITOR K2 INICIADO** 🚀\n" +
                        $"📡 Monitorando: {urlParameter}\n" +
                        $"⏰ Servidor com TIMEOUT na inicialização\n" +
                        $"🕐 {DateTime.Now:dd/MM/yyyy HH:mm:ss}");
                    systemJustStarted = false;
                }

                if (!serverWasDown)
                {
                    await SendDiscordMessageSafe($"⏰ **SERVIDOR LENTO**: {urlParameter} - Timeout 30s - {DateTime.Now:HH:mm:ss}");
                    
                    // Timeout também pode indicar problema no Apache
                    if (enableApacheRestart && detectedApacheServiceName != null && restartAttempts < maxRestartAttempts)
                    {
                        await HandleApacheRestart(stoppingToken);
                    }
                    
                    serverWasDown = true;
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "❌ Erro de conexão com servidor");
                
                if (systemJustStarted)
                {
                    await SendDiscordMessageSafe(
                        $"🚀 **SERVIÇO MONITOR K2 INICIADO** 🚀\n" +
                        $"📡 Monitorando: {urlParameter}\n" +
                        $"❌ Servidor FORA DO AR na inicialização\n" +
                        $"🔍 Erro: {ex.Message}\n" +
                        $"🕐 {DateTime.Now:dd/MM/yyyy HH:mm:ss}");
                    systemJustStarted = false;
                }

                if (!serverWasDown)
                {
                    await SendDiscordMessageSafe($"🚨 **SERVIDOR FORA DO AR**: {urlParameter} - {ex.Message} - {DateTime.Now:HH:mm:ss}");
                    
                    // Erro de conexão - definitivamente reiniciar Apache
                    if (enableApacheRestart && detectedApacheServiceName != null && restartAttempts < maxRestartAttempts)
                    {
                        await HandleApacheRestart(stoppingToken);
                    }
                    
                    serverWasDown = true;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Erro inesperado no monitoramento");
            }

            // Aguarda próxima verificação
            await Task.Delay(interval, stoppingToken);
        }
    }

    // === MÉTODOS DO APACHE (mantidos iguais) ===
    
    private async Task DetectApacheServiceName()
    {
        _logger.LogInformation("🔍 Detectando serviço Apache automaticamente...");
        
        // Primeiro: Tentar detectar pelo nome do serviço
        foreach (string serviceName in possibleApacheNames)
        {
            try
            {
                var queryProcess = new ProcessStartInfo
                {
                    FileName = "sc",
                    Arguments = $"query \"{serviceName}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var process = Process.Start(queryProcess);
                await process.WaitForExitAsync();
                
                if (process.ExitCode == 0)
                {
                    detectedApacheServiceName = serviceName;
                    _logger.LogInformation("✅ Apache detectado pelo nome do serviço: {ServiceName}", serviceName);
                    return;
                }
            }
            catch (Exception ex)
            {
                _logger.LogDebug("Erro ao verificar serviço {ServiceName}: {Error}", serviceName, ex.Message);
            }
        }
        
        // Segundo: Se não encontrou, tentar detectar por processo httpd.exe
        _logger.LogInformation("🔍 Não encontrado por nome de serviço, tentando detectar por processo httpd.exe...");
        await DetectApacheByProcess();
        
        if (detectedApacheServiceName == null)
        {
            _logger.LogWarning("⚠️ Nenhum serviço Apache detectado");
            _logger.LogInformation("💡 Nomes testados: {Names}", string.Join(", ", possibleApacheNames));
            _logger.LogInformation("💡 Processo testado: httpd.exe");
        }
    }

    private async Task DetectApacheByProcess()
    {
        try
        {
            // Verificar se processo httpd.exe está rodando
            var processes = Process.GetProcessesByName("httpd");
            
            if (processes.Length > 0)
            {
                _logger.LogInformation("🔍 Processo httpd.exe encontrado, tentando identificar serviço...");
                
                // Tentar encontrar serviço que corresponde ao processo httpd
                var allServicesProcess = new ProcessStartInfo
                {
                    FileName = "sc",
                    Arguments = "query type= service",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var process = Process.Start(allServicesProcess);
                await process.WaitForExitAsync();
                
                if (process.ExitCode == 0)
                {
                    string output = await process.StandardOutput.ReadToEndAsync();
                    
                    // Procurar por serviços que contem httpd ou apache
                    var lines = output.Split('\n');
                    foreach (var line in lines)
                    {
                        if (line.Contains("SERVICE_NAME:"))
                        {
                            string serviceName = line.Replace("SERVICE_NAME:", "").Trim();
                            if (serviceName.ToLower().Contains("httpd") || 
                                serviceName.ToLower().Contains("apache"))
                            {
                                // Verificar se este serviço está realmente rodando
                                if (await IsServiceRunning(serviceName))
                                {
                                    detectedApacheServiceName = serviceName;
                                    _logger.LogInformation("✅ Apache detectado por processo httpd: {ServiceName}", serviceName);
                                    return;
                                }
                            }
                        }
                    }
                }
                
                // Se não encontrou serviço específico, mas httpd está rodando
                // Pode ser que Apache esteja rodando como executável direto (não como serviço)
                _logger.LogWarning("⚠️ Processo httpd.exe está rodando, mas não como serviço Windows");
                _logger.LogInformation("💡 Apache pode estar rodando diretamente como executável");
                
                // Neste caso, tentaremos reiniciar o processo diretamente
                detectedApacheServiceName = "httpd-process"; // Flag especial
                return;
            }
            else
            {
                _logger.LogInformation("ℹ️ Processo httpd.exe não encontrado");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao detectar Apache por processo");
        }
    }

    private async Task<bool> IsServiceRunning(string serviceName)
    {
        try
        {
            var queryProcess = new ProcessStartInfo
            {
                FileName = "sc",
                Arguments = $"query \"{serviceName}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(queryProcess);
            await process.WaitForExitAsync();
            
            if (process.ExitCode == 0)
            {
                string output = await process.StandardOutput.ReadToEndAsync();
                return output.Contains("RUNNING");
            }
            
            return false;
        }
        catch
        {
            return false;
        }
    }

    // === NOVA FUNCIONALIDADE: GERENCIAMENTO DO APACHE ===
    
    private async Task HandleApacheRestart(CancellationToken stoppingToken)
    {
        if (detectedApacheServiceName == null)
        {
            _logger.LogError("❌ Apache não detectado - não é possível reiniciar");
            return;
        }

        try
        {
            restartAttempts++;
            _logger.LogWarning("🔄 Iniciando reinicialização do Apache (Tentativa {Attempt}/{Max})", restartAttempts, maxRestartAttempts);
            
            await SendDiscordMessageSafe(
                $"🔄 **REINICIANDO APACHE** 🔄\n" +
                $"🎯 Tentativa: {restartAttempts}/{maxRestartAttempts}\n" +
                $"🔧 Método: {(detectedApacheServiceName == "httpd-process" ? "Processo httpd.exe" : $"Serviço {detectedApacheServiceName}")}\n" +
                $"⏰ {DateTime.Now:dd/MM/yyyy HH:mm:ss}");

            // Verificar se é processo direto ou serviço
            if (detectedApacheServiceName == "httpd-process")
            {
                await RestartApacheProcess();
            }
            else
            {
                // Parar o Apache (serviço)
                await StopApacheService();
                
                // Aguardar antes de reiniciar
                _logger.LogInformation("⏳ Aguardando {Delay} segundos antes de reiniciar...", apacheRestartDelay / 1000);
                await Task.Delay(apacheRestartDelay, stoppingToken);
                
                // Iniciar o Apache (serviço)
                await StartApacheService();
            }
            
            // Aguardar um pouco e verificar se o serviço/processo está rodando
            await Task.Delay(5000, stoppingToken);
            bool isRunning = await CheckApacheServiceStatus();
            
            if (isRunning)
            {
                _logger.LogInformation("✅ Apache reiniciado com sucesso!");
                await SendDiscordMessageSafe(
                    $"✅ **APACHE REINICIADO COM SUCESSO** ✅\n" +
                    $"🔧 Método: {(detectedApacheServiceName == "httpd-process" ? "Processo httpd.exe" : $"Serviço {detectedApacheServiceName}")}\n" +
                    $"🎯 Tentativa: {restartAttempts}/{maxRestartAttempts}\n" +
                    $"⏰ {DateTime.Now:dd/MM/yyyy HH:mm:ss}\n" +
                    $"🔍 Aguardando próxima verificação para confirmar recuperação...");
            }
            else
            {
                _logger.LogError("❌ Falha ao reiniciar Apache - não está rodando");
                await SendDiscordMessageSafe($"❌ **FALHA NA REINICIALIZAÇÃO**: Apache não iniciou corretamente (Tentativa {restartAttempts}/{maxRestartAttempts})");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro durante reinicialização do Apache");
            await SendDiscordMessageSafe($"❌ **ERRO NA REINICIALIZAÇÃO**: {ex.Message} (Tentativa {restartAttempts}/{maxRestartAttempts})");
        }
    }

    private async Task RestartApacheProcess()
    {
        try
        {
            _logger.LogInformation("🔄 Reiniciando processo httpd.exe...");
            
            // Finalizar todos os processos httpd
            var processes = Process.GetProcessesByName("httpd");
            foreach (var proc in processes)
            {
                try
                {
                    _logger.LogInformation("🛑 Finalizando processo httpd PID: {ProcessId}", proc.Id);
                    proc.Kill();
                    proc.WaitForExit(5000); // Aguardar até 5 segundos
                }
                catch (Exception ex)
                {
                    _logger.LogWarning("⚠️ Erro ao finalizar processo httpd {ProcessId}: {Error}", proc.Id, ex.Message);
                }
            }

            // Aguardar um pouco após finalizar
            await Task.Delay(3000);
            
            // Tentar iniciar httpd novamente (isso vai depender de como o Apache está configurado)
            // Normalmente o httpd será reiniciado automaticamente pelo sistema ou por um monitor
            _logger.LogInformation("ℹ️ Processos httpd finalizados. O Apache deve reiniciar automaticamente.");
            
            // Aguardar e verificar se voltou
            await Task.Delay(5000);
            var newProcesses = Process.GetProcessesByName("httpd");
            
            if (newProcesses.Length > 0)
            {
                _logger.LogInformation("✅ Processo httpd reiniciado automaticamente");
            }
            else
            {
                _logger.LogWarning("⚠️ Processo httpd não reiniciou automaticamente");
                
                // Aqui você poderia tentar iniciar manualmente se souber o caminho
                // Por exemplo: C:\Apache24\bin\httpd.exe -k start
                // Mas isso depende da instalação específica
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao reiniciar processo httpd");
            throw;
        }
    }

    private async Task StopApacheService()
    {
        try
        {
            _logger.LogInformation("🛑 Parando serviço Apache: {ServiceName}", detectedApacheServiceName);
            
            var stopProcess = new ProcessStartInfo
            {
                FileName = "net",
                Arguments = $"stop \"{detectedApacheServiceName}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(stopProcess);
            await process.WaitForExitAsync();
            
            string output = await process.StandardOutput.ReadToEndAsync();
            string error = await process.StandardError.ReadToEndAsync();

            if (process.ExitCode == 0)
            {
                _logger.LogInformation("✅ Apache parado com sucesso");
            }
            else
            {
                _logger.LogWarning("⚠️ Comando stop retornou código {ExitCode}. Output: {Output}, Erro: {Error}", 
                    process.ExitCode, output, error);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao parar Apache");
            throw;
        }
    }

    private async Task StartApacheService()
    {
        try
        {
            _logger.LogInformation("🚀 Iniciando serviço Apache: {ServiceName}", detectedApacheServiceName);
            
            var startProcess = new ProcessStartInfo
            {
                FileName = "net",
                Arguments = $"start \"{detectedApacheServiceName}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startProcess);
            await process.WaitForExitAsync();
            
            string output = await process.StandardOutput.ReadToEndAsync();
            string error = await process.StandardError.ReadToEndAsync();

            if (process.ExitCode == 0)
            {
                _logger.LogInformation("✅ Apache iniciado com sucesso");
            }
            else
            {
                _logger.LogError("❌ Falha ao iniciar Apache. Código: {ExitCode}, Output: {Output}, Erro: {Error}", 
                    process.ExitCode, output, error);
                throw new InvalidOperationException($"Falha ao iniciar Apache: {error}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao iniciar Apache");
            throw;
        }
    }

    private async Task<bool> CheckApacheServiceStatus()
    {
        try
        {
            // Se for processo direto, verificar processo httpd
            if (detectedApacheServiceName == "httpd-process")
            {
                var processes = Process.GetProcessesByName("httpd");
                bool isRunning = processes.Length > 0;
                
                _logger.LogInformation("📊 Status do Apache (processo): {Status} ({ProcessCount} processos)", 
                    isRunning ? "RUNNING" : "NOT RUNNING", processes.Length);
                
                return isRunning;
            }
            else
            {
                // Verificar serviço Windows
                var queryProcess = new ProcessStartInfo
                {
                    FileName = "sc",
                    Arguments = $"query \"{detectedApacheServiceName}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var process = Process.Start(queryProcess);
                await process.WaitForExitAsync();
                
                string output = await process.StandardOutput.ReadToEndAsync();
                
                // Verificar se o serviço está em estado "RUNNING"
                bool isRunning = output.Contains("RUNNING");
                
                _logger.LogInformation("📊 Status do Apache (serviço): {Status}", isRunning ? "RUNNING" : "NOT RUNNING");
                
                return isRunning;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao verificar status do Apache");
            return false;
        }
    }

    private async Task SendDiscordMessageSafe(string message)
    {
        // Rate limiting para evitar spam
        if (DateTime.Now - lastDiscordMessage < TimeSpan.FromMilliseconds(discordRateLimit))
        {
            _logger.LogInformation("📱 Mensagem Discord ignorada (rate limit)");
            return;
        }

        if (string.IsNullOrEmpty(webhookDiscord))
        {
            _logger.LogWarning("📱 Webhook Discord não configurado - mensagem não enviada");
            return;
        }

        lastDiscordMessage = DateTime.Now;
        await SendDiscordMessage(message);
    }

    private async Task SendDiscordMessage(string message)
    {
        try
        {
            using HttpClient client = new HttpClient();
            client.Timeout = TimeSpan.FromSeconds(10);

            var payload = new { content = message };
            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await client.PostAsync(webhookDiscord, content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("📱 Notificação Discord enviada!");
            }
            else
            {
                _logger.LogWarning("❌ Falha Discord - Status: {Status}", response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao enviar mensagem Discord");
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("🛑 Serviço Monitor K2Web parando...");
        await SendDiscordMessageSafe($"🛑 **SERVIÇO MONITOR K2 PARADO** - {DateTime.Now:dd/MM/yyyy HH:mm:ss}");
        await base.StopAsync(cancellationToken);
    }

    // === MÉTODOS DO APACHE (resto do código mantido igual) ===
}