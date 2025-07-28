# ============================================
# SCRIPT OTIMIZADO PARA WINDOWS SERVER
# Monitor K2Web Service - Vers�o Servidor
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

# Verificar privil�gios
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

Write-ColorOutput "?? Pasta de instala��o: $ScriptPath" "Gray"
Write-ColorOutput "?? Execut�vel: $ExePath" "Gray"

if (-not (Test-Path $ExePath)) {
    Write-ColorOutput "? Execut�vel n�o encontrado!" "Red"
    Write-ColorOutput "?? Verifique: $ExePath" "Yellow"
    pause
    exit 1
}

function Remove-ExistingService($serviceName) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-ColorOutput "?? Parando servi�o existente..." "Yellow"
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5  # Mais tempo no servidor
            
            Write-ColorOutput "??? Removendo servi�o existente..." "Yellow"
            sc.exe delete $serviceName | Out-Null
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-ColorOutput "?? Erro ao remover servi�o: $_" "Yellow"
    }
}

switch ($Action.ToLower()) {
    "install" {
        Write-ColorOutput "?? Instalando no Windows Server..." "Yellow"
        
        # Configura��es espec�ficas do servidor
        if ($isServer) {
            Write-ColorOutput "?? Aplicando configura��es para Windows Server..." "Cyan"
            
            # Verificar ExecutionPolicy
            $execPolicy = Get-ExecutionPolicy
            if ($execPolicy -eq "Restricted") {
                Write-ColorOutput "?? Ajustando ExecutionPolicy para servidor..." "Yellow"
                try {
                    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
                    Write-ColorOutput "? ExecutionPolicy configurada" "Green"
                }
                catch {
                    Write-ColorOutput "?? Aviso: N�o foi poss�vel alterar ExecutionPolicy" "Yellow"
                }
            }
        }
        
        Remove-ExistingService $ServiceName
        
        # Criar servi�o
        Write-ColorOutput "??? Criando Windows Service..." "Yellow"
        $createResult = sc.exe create $ServiceName binPath= "`"$ExePath`"" displayname= "`"$DisplayName`"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Servi�o criado!" "Green"
            
            # Configura��es robustas para Windows Server
            Write-ColorOutput "?? Configurando para ambiente servidor..." "Yellow"
            
            # Inicializa��o autom�tica
            sc.exe config $ServiceName start= auto | Out-Null
            
            # Descri��o detalhada
            $description = "Monitor profissional do servidor K2Web com notifica��es Discord e reinicializa��o autom�tica do Apache. Instalado em $(Get-Date) no $osInfo."
            sc.exe description $ServiceName $description | Out-Null
            
            # Recovery avan�ado para servidor (mais agressivo)
            sc.exe failure $ServiceName reset= 86400 actions= restart/3000/restart/5000/restart/10000 | Out-Null
            sc.exe failureflag $ServiceName 1 | Out-Null
            
            # Configurar para rodar mesmo sem usu�rio logado (importante no servidor)
            sc.exe config $ServiceName type= own | Out-Null
            
            # Depend�ncias espec�ficas do servidor
            if ($isServer) {
                Write-ColorOutput "?? Configurando depend�ncias do servidor..." "Gray"
                sc.exe config $ServiceName depend= "Tcpip/Dnscache" | Out-Null
            }
            
            # Iniciar servi�o
            Write-ColorOutput "?? Iniciando servi�o..." "Yellow"
            sc.exe start $ServiceName | Out-Null
            
            Start-Sleep -Seconds 8  # Mais tempo para inicializa��o no servidor
            
            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-ColorOutput "`n?? INSTALA��O NO SERVIDOR CONCLU�DA!" "Green"
                Write-ColorOutput "================================================" "Green"
                Write-ColorOutput "??? Sistema: $osInfo" "Cyan"
                Write-ColorOutput "??? Nome do servi�o: $ServiceName" "Cyan"
                Write-ColorOutput "?? Status: $($service.Status)" "Green"
                Write-ColorOutput "?? Inicializa��o: Autom�tica" "Cyan"
                Write-ColorOutput "??? Recovery: Configurado" "Cyan"
                Write-ColorOutput "?? Discord: Configurado" "Cyan"
                Write-ColorOutput "?? Intervalo: 5 segundos" "Cyan"
                Write-ColorOutput "?? Apache: ApacheHTTPServer" "Cyan"
                
                if ($isServer) {
                    Write-ColorOutput "`n?? CONFIGURA��ES ESPEC�FICAS DO SERVIDOR:" "Yellow"
                    Write-ColorOutput "   � Logs avan�ados no Event Viewer" "Gray"
                    Write-ColorOutput "   � Recovery autom�tico configurado" "Gray"
                    Write-ColorOutput "   � Execu��o sem usu�rio logado" "Gray"
                    Write-ColorOutput "   � Depend�ncias de rede configuradas" "Gray"
                }
                
                Write-ColorOutput "`n?? Para monitorar no servidor:" "White"
                Write-ColorOutput "   � Event Viewer: eventvwr.msc" "Gray"
                Write-ColorOutput "   � Services: services.msc" "Gray"
                Write-ColorOutput "   � Status: StatusServidor.bat" "Gray"
                Write-ColorOutput "   � Performance Monitor: perfmon.msc" "Gray"
            }
            else {
                Write-ColorOutput "?? Servi�o instalado mas n�o iniciou. Status: $($service.Status)" "Yellow"
            }
        }
        else {
            Write-ColorOutput "? Falha ao criar servi�o!" "Red"
        }
    }
    
    "uninstall" {
        Write-ColorOutput "??? Desinstalando do servidor..." "Yellow"
        Remove-ExistingService $ServiceName
        Write-ColorOutput "? Servi�o removido do servidor!" "Green"
    }
    
    "status" {
        try {
            $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($service) {
                Write-ColorOutput "`n?? STATUS NO WINDOWS SERVER" "Cyan"
                Write-ColorOutput "===========================" "Cyan"
                Write-ColorOutput "??? Sistema: $osInfo" "White"
                Write-ColorOutput "??? Nome: $($service.Name)" "White"
                Write-ColorOutput "?? Nome de exibi��o: $($service.DisplayName)" "White"
                Write-ColorOutput "?? Status: $($service.Status)" "$(if($service.Status -eq 'Running'){'Green'}else{'Red'})"
                Write-ColorOutput "?? Tipo de inicializa��o: $($service.StartType)" "White"
                Write-ColorOutput "?? Execut�vel: $ExePath" "Gray"
                
                # Informa��es adicionais para servidor
                if ($isServer -and $service.Status -eq "Running") {
                    Write-ColorOutput "`n?? M�TRICAS DO SERVIDOR:" "Cyan"
                    
                    try {
                        $process = Get-Process -Name "StatusK2Web" -ErrorAction SilentlyContinue
                        if ($process) {
                            Write-ColorOutput "?? Uso de mem�ria: $([math]::Round($process.WorkingSet / 1MB, 2)) MB" "Gray"
                            Write-ColorOutput "?? Tempo ativo: $($process.StartTime.ToString('dd/MM/yyyy HH:mm:ss'))" "Gray"
                            Write-ColorOutput "?? Process ID: $($process.Id)" "Gray"
                        }
                    }
                    catch {
                        Write-ColorOutput "?? M�tricas de processo n�o dispon�veis" "Gray"
                    }
                }
            }
            else {
                Write-ColorOutput "? Servi�o n�o encontrado no servidor!" "Red"
            }
        }
        catch {
            Write-ColorOutput "? Erro ao verificar status: $_" "Red"
        }
    }
    
    default {
        Write-ColorOutput "? A��o inv�lida: $Action" "Red"
        Write-ColorOutput "A��es: install, uninstall, status" "Yellow"
    }
}

Write-ColorOutput "`nPressione qualquer tecla para continuar..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")