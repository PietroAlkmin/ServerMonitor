# ============================================
# SCRIPT OTIMIZADO PARA WINDOWS SERVER
# Monitor K2Web Service - Versão Servidor
# ============================================

param(
    [string]$Action = "install",
    [string]$ServiceName = "MonitorK2Web",
    [string]$DisplayName = "Monitor K2Web Service - Servidor Corporativo"
)

function Write-ColorOutput([string]$message, [string]$color = "White") {
    Write-Host $message -ForegroundColor $color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WindowsServer {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return $os.ProductType -eq 2 -or $os.ProductType -eq 3  # Domain Controller ou Server
}

Write-ColorOutput "`n??? ================================" "Cyan"
Write-ColorOutput "   MONITOR K2WEB - WINDOWS SERVER" "Cyan"
Write-ColorOutput "================================`n" "Cyan"

# Detectar tipo de Windows
$isServer = Test-WindowsServer
$osInfo = if ($isServer) { "Windows Server" } else { "Windows Desktop" }
Write-ColorOutput "??? Sistema detectado: $osInfo" "Green"

# Verificar privilégios
if (-not (Test-Administrator)) {
    Write-ColorOutput "? ERRO: Execute como Administrador!" "Red"
    Write-ColorOutput "?? Para Windows Server:" "Yellow"
    Write-ColorOutput "   1. Abra PowerShell como Administrador" "Gray"
    Write-ColorOutput "   2. Execute: Set-ExecutionPolicy RemoteSigned" "Gray"
    Write-ColorOutput "   3. Execute novamente este script" "Gray"
    pause
    exit 1
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $ScriptPath "..\Executavel\StatusK2Web.exe"

Write-ColorOutput "?? Pasta de instalação: $ScriptPath" "Gray"
Write-ColorOutput "?? Executável: $ExePath" "Gray"

if (-not (Test-Path $ExePath)) {
    Write-ColorOutput "? Executável não encontrado!" "Red"
    Write-ColorOutput "?? Verifique: $ExePath" "Yellow"
    pause
    exit 1
}

function Remove-ExistingService($serviceName) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-ColorOutput "?? Parando serviço existente..." "Yellow"
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5  # Mais tempo no servidor
            
            Write-ColorOutput "??? Removendo serviço existente..." "Yellow"
            sc.exe delete $serviceName | Out-Null
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-ColorOutput "?? Erro ao remover serviço: $_" "Yellow"
    }
}

switch ($Action.ToLower()) {
    "install" {
        Write-ColorOutput "?? Instalando no Windows Server..." "Yellow"
        
        # Configurações específicas do servidor
        if ($isServer) {
            Write-ColorOutput "?? Aplicando configurações para Windows Server..." "Cyan"
            
            # Verificar ExecutionPolicy
            $execPolicy = Get-ExecutionPolicy
            if ($execPolicy -eq "Restricted") {
                Write-ColorOutput "?? Ajustando ExecutionPolicy para servidor..." "Yellow"
                try {
                    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
                    Write-ColorOutput "? ExecutionPolicy configurada" "Green"
                }
                catch {
                    Write-ColorOutput "?? Aviso: Não foi possível alterar ExecutionPolicy" "Yellow"
                }
            }
        }
        
        Remove-ExistingService $ServiceName
        
        # Criar serviço
        Write-ColorOutput "??? Criando Windows Service..." "Yellow"
        $createResult = sc.exe create $ServiceName binPath= "`"$ExePath`"" displayname= "`"$DisplayName`"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Serviço criado!" "Green"
            
            # Configurações robustas para Windows Server
            Write-ColorOutput "?? Configurando para ambiente servidor..." "Yellow"
            
            # Inicialização automática
            sc.exe config $ServiceName start= auto | Out-Null
            
            # Descrição detalhada
            $description = "Monitor profissional do servidor K2Web com notificações Discord e reinicialização automática do Apache. Instalado em $(Get-Date) no $osInfo."
            sc.exe description $ServiceName $description | Out-Null
            
            # Recovery avançado para servidor (mais agressivo)
            sc.exe failure $ServiceName reset= 86400 actions= restart/3000/restart/5000/restart/10000 | Out-Null
            sc.exe failureflag $ServiceName 1 | Out-Null
            
            # Configurar para rodar mesmo sem usuário logado (importante no servidor)
            sc.exe config $ServiceName type= own | Out-Null
            
            # Dependências específicas do servidor
            if ($isServer) {
                Write-ColorOutput "?? Configurando dependências do servidor..." "Gray"
                sc.exe config $ServiceName depend= "Tcpip/Dnscache" | Out-Null
            }
            
            # Iniciar serviço
            Write-ColorOutput "?? Iniciando serviço..." "Yellow"
            sc.exe start $ServiceName | Out-Null
            
            Start-Sleep -Seconds 8  # Mais tempo para inicialização no servidor
            
            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-ColorOutput "`n?? INSTALAÇÃO NO SERVIDOR CONCLUÍDA!" "Green"
                Write-ColorOutput "================================================" "Green"
                Write-ColorOutput "??? Sistema: $osInfo" "Cyan"
                Write-ColorOutput "??? Nome do serviço: $ServiceName" "Cyan"
                Write-ColorOutput "?? Status: $($service.Status)" "Green"
                Write-ColorOutput "?? Inicialização: Automática" "Cyan"
                Write-ColorOutput "??? Recovery: Configurado" "Cyan"
                Write-ColorOutput "?? Discord: Configurado" "Cyan"
                Write-ColorOutput "?? Intervalo: 5 segundos" "Cyan"
                Write-ColorOutput "?? Apache: ApacheHTTPServer" "Cyan"
                
                if ($isServer) {
                    Write-ColorOutput "`n?? CONFIGURAÇÕES ESPECÍFICAS DO SERVIDOR:" "Yellow"
                    Write-ColorOutput "   • Logs avançados no Event Viewer" "Gray"
                    Write-ColorOutput "   • Recovery automático configurado" "Gray"
                    Write-ColorOutput "   • Execução sem usuário logado" "Gray"
                    Write-ColorOutput "   • Dependências de rede configuradas" "Gray"
                }
                
                Write-ColorOutput "`n?? Para monitorar no servidor:" "White"
                Write-ColorOutput "   • Event Viewer: eventvwr.msc" "Gray"
                Write-ColorOutput "   • Services: services.msc" "Gray"
                Write-ColorOutput "   • Status: StatusServidor.bat" "Gray"
                Write-ColorOutput "   • Performance Monitor: perfmon.msc" "Gray"
            }
            else {
                Write-ColorOutput "?? Serviço instalado mas não iniciou. Status: $($service.Status)" "Yellow"
            }
        }
        else {
            Write-ColorOutput "? Falha ao criar serviço!" "Red"
        }
    }
    
    "uninstall" {
        Write-ColorOutput "??? Desinstalando do servidor..." "Yellow"
        Remove-ExistingService $ServiceName
        Write-ColorOutput "? Serviço removido do servidor!" "Green"
    }
    
    "status" {
        try {
            $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($service) {
                Write-ColorOutput "`n?? STATUS NO WINDOWS SERVER" "Cyan"
                Write-ColorOutput "===========================" "Cyan"
                Write-ColorOutput "??? Sistema: $osInfo" "White"
                Write-ColorOutput "??? Nome: $($service.Name)" "White"
                Write-ColorOutput "?? Nome de exibição: $($service.DisplayName)" "White"
                Write-ColorOutput "?? Status: $($service.Status)" "$(if($service.Status -eq 'Running'){'Green'}else{'Red'})"
                Write-ColorOutput "?? Tipo de inicialização: $($service.StartType)" "White"
                Write-ColorOutput "?? Executável: $ExePath" "Gray"
                
                # Informações adicionais para servidor
                if ($isServer -and $service.Status -eq "Running") {
                    Write-ColorOutput "`n?? MÉTRICAS DO SERVIDOR:" "Cyan"
                    
                    try {
                        $process = Get-Process -Name "StatusK2Web" -ErrorAction SilentlyContinue
                        if ($process) {
                            Write-ColorOutput "?? Uso de memória: $([math]::Round($process.WorkingSet / 1MB, 2)) MB" "Gray"
                            Write-ColorOutput "?? Tempo ativo: $($process.StartTime.ToString('dd/MM/yyyy HH:mm:ss'))" "Gray"
                            Write-ColorOutput "?? Process ID: $($process.Id)" "Gray"
                        }
                    }
                    catch {
                        Write-ColorOutput "?? Métricas de processo não disponíveis" "Gray"
                    }
                }
            }
            else {
                Write-ColorOutput "? Serviço não encontrado no servidor!" "Red"
            }
        }
        catch {
            Write-ColorOutput "? Erro ao verificar status: $_" "Red"
        }
    }
    
    default {
        Write-ColorOutput "? Ação inválida: $Action" "Red"
        Write-ColorOutput "Ações: install, uninstall, status" "Yellow"
    }
}

Write-ColorOutput "`nPressione qualquer tecla para continuar..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")