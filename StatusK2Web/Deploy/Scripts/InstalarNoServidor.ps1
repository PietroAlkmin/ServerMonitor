# ============================================
# INSTALADOR PARA SERVIDOR DE PRODUÇÃO
# Monitor K2Web Service
# ============================================

param(
    [string]$Action = "install",
    [string]$ServiceName = "MonitorK2Web",
    [string]$DisplayName = "Monitor K2Web Service - Servidor-Producao"
)

function Write-ColorOutput([string]$message, [string]$color = "White") {
    Write-Host $message -ForegroundColor $color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-ColorOutput "
?? ================================" "Cyan"
Write-ColorOutput "   MONITOR K2WEB - SERVIDOR" "Cyan"
Write-ColorOutput "   Servidor-Producao" "Cyan"
Write-ColorOutput "================================
" "Cyan"

if (-not (Test-Administrator)) {
    Write-ColorOutput "? ERRO: Execute como Administrador!" "Red"
    Write-ColorOutput "?? Clique direito no PowerShell e escolha 'Executar como administrador'" "Yellow"
    pause
    exit 1
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $ScriptPath "..\Executavel\StatusK2Web.exe"

Write-ColorOutput "?? Pasta de instalação: $ScriptPath" "Gray"
Write-ColorOutput "?? Executável: $ExePath" "Gray"

if (-not (Test-Path $ExePath)) {
    Write-ColorOutput "? Executável não encontrado!" "Red"
    Write-ColorOutput "?? Verifique se o arquivo está em: $ExePath" "Yellow"
    pause
    exit 1
}

function Remove-ExistingService($serviceName) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-ColorOutput "?? Parando serviço existente..." "Yellow"
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            
            Write-ColorOutput "??? Removendo serviço existente..." "Yellow"
            sc.exe delete $serviceName | Out-Null
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-ColorOutput "?? Erro ao remover serviço: $_" "Yellow"
    }
}

switch ($Action.ToLower()) {
    "install" {
        Write-ColorOutput "?? Instalando serviço no servidor..." "Yellow"
        
        Remove-ExistingService $ServiceName
        
        # Criar serviço
        $createResult = sc.exe create $ServiceName binPath= "$ExePath" displayname= "$DisplayName"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Serviço criado!" "Green"
            
            # Configurações avançadas para servidor
            sc.exe config $ServiceName start= auto | Out-Null
            sc.exe description $ServiceName "Monitor do servidor K2Web com notificações Discord - Instalado em $(Get-Date)" | Out-Null
            sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/20000 | Out-Null
            
            # Iniciar serviço
            Write-ColorOutput "?? Iniciando serviço..." "Yellow"
            sc.exe start $ServiceName | Out-Null
            
            Start-Sleep -Seconds 5
            
            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-ColorOutput "
?? INSTALAÇÃO CONCLUÍDA COM SUCESSO!" "Green"
                Write-ColorOutput "================================================" "Green"
                Write-ColorOutput "??? Nome do serviço: $ServiceName" "Cyan"
                Write-ColorOutput "?? Status: $($service.Status)" "Green"
                Write-ColorOutput "?? Inicialização: Automática" "Cyan"
                Write-ColorOutput "?? Discord: Configurado" "Cyan"
                Write-ColorOutput "?? Intervalo: 5 minutos" "Cyan"
                Write-ColorOutput "
?? Para gerenciar:" "White"
                Write-ColorOutput "   • Ver status: sc query $ServiceName" "Gray"
                Write-ColorOutput "   • Parar: sc stop $ServiceName" "Gray"
                Write-ColorOutput "   • Iniciar: sc start $ServiceName" "Gray"
                Write-ColorOutput "   • Logs: Event Viewer ? Application" "Gray"
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
        Write-ColorOutput "??? Desinstalando serviço..." "Yellow"
        Remove-ExistingService $ServiceName
        Write-ColorOutput "? Serviço removido!" "Green"
    }
    
    "status" {
        try {
            $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($service) {
                Write-ColorOutput "
?? STATUS DO SERVIÇO" "Cyan"
                Write-ColorOutput "==================" "Cyan"
                Write-ColorOutput "??? Nome: $($service.Name)" "White"
                Write-ColorOutput "?? Nome de exibição: $($service.DisplayName)" "White"
                Write-ColorOutput "?? Status: $($service.Status)" "$(if($service.Status -eq 'Running'){'Green'}else{'Red'})"
                Write-ColorOutput "?? Tipo de inicialização: $($service.StartType)" "White"
                Write-ColorOutput "?? Executável: $ExePath" "Gray"
                Write-ColorOutput "??? Servidor: Servidor-Producao" "Cyan"
            }
            else {
                Write-ColorOutput "? Serviço não encontrado!" "Red"
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

Write-ColorOutput "
Pressione qualquer tecla para continuar..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
