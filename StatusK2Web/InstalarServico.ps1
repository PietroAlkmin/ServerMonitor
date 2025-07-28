# ============================================
# SCRIPT DE INSTALAÇÃO AUTOMÁTICA
# Monitor K2Web Service - Windows Service
# ============================================

param(
    [string]$Action = "install",  # install, uninstall, reinstall, status
    [string]$ServiceName = "MonitorK2Web",
    [string]$DisplayName = "Monitor K2Web Service"
)

# Cores para output
function Write-ColorOutput([string]$message, [string]$color = "White") {
    Write-Host $message -ForegroundColor $color
}

# Verificar se está rodando como administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Caminhos do projeto
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = $ScriptPath
$ExePath = Join-Path $ProjectPath "bin\Release\net8.0\win-x64\publish\StatusK2Web.exe"

Write-ColorOutput "`n?? ================================" "Cyan"
Write-ColorOutput "   MONITOR K2WEB - INSTALADOR" "Cyan"
Write-ColorOutput "================================`n" "Cyan"

# Verificar privilégios de administrador
if (-not (Test-Administrator)) {
    Write-ColorOutput "? ERRO: Este script precisa ser executado como Administrador!" "Red"
    Write-ColorOutput "?? Clique direito no PowerShell e escolha 'Executar como administrador'" "Yellow"
    Write-ColorOutput "`nPressione qualquer tecla para sair..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-ColorOutput "? Executando com privilégios de administrador" "Green"
Write-ColorOutput "?? Pasta do projeto: $ProjectPath" "Gray"

# Função para verificar se serviço existe
function Test-ServiceExists($serviceName) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        return $service -ne $null
    }
    catch {
        return $false
    }
}

# Função para parar e remover serviço existente
function Remove-ExistingService($serviceName) {
    if (Test-ServiceExists $serviceName) {
        Write-ColorOutput "?? Parando serviço existente..." "Yellow"
        try {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }
        catch {
            Write-ColorOutput "?? Serviço já estava parado" "Yellow"
        }

        Write-ColorOutput "??? Removendo serviço existente..." "Yellow"
        sc.exe delete $serviceName | Out-Null
        Start-Sleep -Seconds 2
        
        if (-not (Test-ServiceExists $serviceName)) {
            Write-ColorOutput "? Serviço removido com sucesso" "Green"
        }
    }
}

# Função para publicar aplicação
function Publish-Application {
    Write-ColorOutput "`n?? Publicando aplicação..." "Yellow"
    
    Set-Location $ProjectPath
    
    try {
        # Limpar builds anteriores
        if (Test-Path "bin") {
            Remove-Item "bin" -Recurse -Force
        }
        if (Test-Path "obj") {
            Remove-Item "obj" -Recurse -Force
        }
        
        # Restaurar pacotes
        Write-ColorOutput "?? Restaurando pacotes NuGet..." "Gray"
        dotnet restore --verbosity quiet
        
        # Publicar aplicação
        Write-ColorOutput "?? Compilando e publicando..." "Gray"
        dotnet publish -c Release --verbosity quiet --no-restore
        
        if (Test-Path $ExePath) {
            Write-ColorOutput "? Aplicação publicada com sucesso!" "Green"
            Write-ColorOutput "?? Executável: $ExePath" "Gray"
            
            # Mostrar tamanho do arquivo
            $fileSize = [math]::Round((Get-Item $ExePath).Length / 1MB, 2)
            Write-ColorOutput "?? Tamanho: $fileSize MB" "Gray"
            
            return $true
        }
        else {
            Write-ColorOutput "? Falha na publicação - executável não encontrado!" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro durante publicação: $_" "Red"
        return $false
    }
}

# Função para instalar serviço
function Install-Service {
    Write-ColorOutput "`n?? Instalando Windows Service..." "Yellow"
    
    try {
        # Criar o serviço
        $createResult = sc.exe create $ServiceName binPath= $ExePath displayname= $DisplayName
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Serviço criado com sucesso!" "Green"
            
            # Configurar para iniciar automaticamente
            Write-ColorOutput "?? Configurando inicialização automática..." "Gray"
            sc.exe config $ServiceName start= auto | Out-Null
            
            # Configurar descrição
            sc.exe description $ServiceName "Monitora servidor K2Web e envia notificações via Discord em caso de problemas" | Out-Null
            
            # Configurar recuperação automática em caso de falha
            Write-ColorOutput "??? Configurando recuperação automática..." "Gray"
            sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/20000 | Out-Null
            
            return $true
        }
        else {
            Write-ColorOutput "? Falha ao criar serviço. Código de erro: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro durante instalação do serviço: $_" "Red"
        return $false
    }
}

# Função para iniciar serviço
function Start-MonitorService {
    Write-ColorOutput "`n?? Iniciando serviço..." "Yellow"
    
    try {
        sc.exe start $ServiceName | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Start-Sleep -Seconds 3
            
            # Verificar se realmente iniciou
            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-ColorOutput "? Serviço iniciado com sucesso!" "Green"
                return $true
            }
            else {
                Write-ColorOutput "?? Serviço criado mas não está rodando. Status: $($service.Status)" "Yellow"
                return $false
            }
        }
        else {
            Write-ColorOutput "? Falha ao iniciar serviço. Código de erro: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro ao iniciar serviço: $_" "Red"
        return $false
    }
}

# Função para mostrar status
function Show-ServiceStatus {
    Write-ColorOutput "`n?? STATUS DO SERVIÇO" "Cyan"
    Write-ColorOutput "==================" "Cyan"
    
    if (Test-ServiceExists $ServiceName) {
        $service = Get-Service -Name $ServiceName
        $config = sc.exe qc $ServiceName
        
        Write-ColorOutput "??? Nome: $($service.Name)" "White"
        Write-ColorOutput "?? Nome de exibição: $($service.DisplayName)" "White"
        Write-ColorOutput "?? Status: $($service.Status)" "$(if($service.Status -eq 'Running'){'Green'}else{'Red'})"
        Write-ColorOutput "?? Tipo de inicialização: $($service.StartType)" "White"
        Write-ColorOutput "?? Executável: $ExePath" "Gray"
        
        if ($service.Status -eq "Running") {
            Write-ColorOutput "`n? Serviço está funcionando corretamente!" "Green"
            Write-ColorOutput "?? Verifique seu Discord para mensagens de monitoramento" "Cyan"
        }
        else {
            Write-ColorOutput "`n?? Serviço não está rodando" "Yellow"
        }
    }
    else {
        Write-ColorOutput "? Serviço não está instalado" "Red"
    }
}

# Função principal de instalação
function Install-Complete {
    Write-ColorOutput "?? Iniciando instalação completa..." "Cyan"
    
    # 1. Remover serviço existente se houver
    Remove-ExistingService $ServiceName
    
    # 2. Publicar aplicação
    if (-not (Publish-Application)) {
        Write-ColorOutput "`n? FALHA NA INSTALAÇÃO - Não foi possível publicar a aplicação" "Red"
        return $false
    }
    
    # 3. Instalar serviço
    if (-not (Install-Service)) {
        Write-ColorOutput "`n? FALHA NA INSTALAÇÃO - Não foi possível criar o serviço" "Red"
        return $false
    }
    
    # 4. Iniciar serviço
    if (-not (Start-MonitorService)) {
        Write-ColorOutput "`n?? INSTALAÇÃO PARCIAL - Serviço instalado mas não iniciou automaticamente" "Yellow"
        Write-ColorOutput "?? Tente iniciar manualmente: sc start $ServiceName" "Yellow"
        return $false
    }
    
    # 5. Mostrar status final
    Show-ServiceStatus
    
    Write-ColorOutput "`n?? INSTALAÇÃO CONCLUÍDA COM SUCESSO!" "Green"
    Write-ColorOutput "================================================" "Green"
    Write-ColorOutput "?? Para gerenciar: services.msc" "Cyan"
    Write-ColorOutput "?? Para ver logs: Event Viewer ? Windows Logs ? Application" "Cyan"
    Write-ColorOutput "?? Para parar: sc stop $ServiceName" "Cyan"
    Write-ColorOutput "?? Para iniciar: sc start $ServiceName" "Cyan"
    Write-ColorOutput "??? Para desinstalar: Execute este script com -Action uninstall" "Cyan"
    
    return $true
}

# Função para desinstalar
function Uninstall-Service {
    Write-ColorOutput "??? Desinstalando serviço..." "Yellow"
    
    Remove-ExistingService $ServiceName
    
    if (-not (Test-ServiceExists $ServiceName)) {
        Write-ColorOutput "? Serviço desinstalado com sucesso!" "Green"
    }
    else {
        Write-ColorOutput "? Falha ao desinstalar serviço" "Red"
    }
}

# EXECUÇÃO PRINCIPAL
switch ($Action.ToLower()) {
    "install" {
        Install-Complete
    }
    "uninstall" {
        Uninstall-Service
    }
    "reinstall" {
        Write-ColorOutput "?? Reinstalando serviço..." "Cyan"
        Uninstall-Service
        Start-Sleep -Seconds 2
        Install-Complete
    }
    "status" {
        Show-ServiceStatus
    }
    default {
        Write-ColorOutput "? Ação inválida: $Action" "Red"
        Write-ColorOutput "Ações válidas: install, uninstall, reinstall, status" "Yellow"
    }
}

Write-ColorOutput "`nPressione qualquer tecla para continuar..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")