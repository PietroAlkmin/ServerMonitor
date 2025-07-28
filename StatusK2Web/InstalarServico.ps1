# ============================================
# SCRIPT DE INSTALA��O AUTOM�TICA
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

# Verificar se est� rodando como administrador
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

# Verificar privil�gios de administrador
if (-not (Test-Administrator)) {
    Write-ColorOutput "? ERRO: Este script precisa ser executado como Administrador!" "Red"
    Write-ColorOutput "?? Clique direito no PowerShell e escolha 'Executar como administrador'" "Yellow"
    Write-ColorOutput "`nPressione qualquer tecla para sair..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-ColorOutput "? Executando com privil�gios de administrador" "Green"
Write-ColorOutput "?? Pasta do projeto: $ProjectPath" "Gray"

# Fun��o para verificar se servi�o existe
function Test-ServiceExists($serviceName) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        return $service -ne $null
    }
    catch {
        return $false
    }
}

# Fun��o para parar e remover servi�o existente
function Remove-ExistingService($serviceName) {
    if (Test-ServiceExists $serviceName) {
        Write-ColorOutput "?? Parando servi�o existente..." "Yellow"
        try {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }
        catch {
            Write-ColorOutput "?? Servi�o j� estava parado" "Yellow"
        }

        Write-ColorOutput "??? Removendo servi�o existente..." "Yellow"
        sc.exe delete $serviceName | Out-Null
        Start-Sleep -Seconds 2
        
        if (-not (Test-ServiceExists $serviceName)) {
            Write-ColorOutput "? Servi�o removido com sucesso" "Green"
        }
    }
}

# Fun��o para publicar aplica��o
function Publish-Application {
    Write-ColorOutput "`n?? Publicando aplica��o..." "Yellow"
    
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
        
        # Publicar aplica��o
        Write-ColorOutput "?? Compilando e publicando..." "Gray"
        dotnet publish -c Release --verbosity quiet --no-restore
        
        if (Test-Path $ExePath) {
            Write-ColorOutput "? Aplica��o publicada com sucesso!" "Green"
            Write-ColorOutput "?? Execut�vel: $ExePath" "Gray"
            
            # Mostrar tamanho do arquivo
            $fileSize = [math]::Round((Get-Item $ExePath).Length / 1MB, 2)
            Write-ColorOutput "?? Tamanho: $fileSize MB" "Gray"
            
            return $true
        }
        else {
            Write-ColorOutput "? Falha na publica��o - execut�vel n�o encontrado!" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro durante publica��o: $_" "Red"
        return $false
    }
}

# Fun��o para instalar servi�o
function Install-Service {
    Write-ColorOutput "`n?? Instalando Windows Service..." "Yellow"
    
    try {
        # Criar o servi�o
        $createResult = sc.exe create $ServiceName binPath= $ExePath displayname= $DisplayName
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Servi�o criado com sucesso!" "Green"
            
            # Configurar para iniciar automaticamente
            Write-ColorOutput "?? Configurando inicializa��o autom�tica..." "Gray"
            sc.exe config $ServiceName start= auto | Out-Null
            
            # Configurar descri��o
            sc.exe description $ServiceName "Monitora servidor K2Web e envia notifica��es via Discord em caso de problemas" | Out-Null
            
            # Configurar recupera��o autom�tica em caso de falha
            Write-ColorOutput "??? Configurando recupera��o autom�tica..." "Gray"
            sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/20000 | Out-Null
            
            return $true
        }
        else {
            Write-ColorOutput "? Falha ao criar servi�o. C�digo de erro: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro durante instala��o do servi�o: $_" "Red"
        return $false
    }
}

# Fun��o para iniciar servi�o
function Start-MonitorService {
    Write-ColorOutput "`n?? Iniciando servi�o..." "Yellow"
    
    try {
        sc.exe start $ServiceName | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Start-Sleep -Seconds 3
            
            # Verificar se realmente iniciou
            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-ColorOutput "? Servi�o iniciado com sucesso!" "Green"
                return $true
            }
            else {
                Write-ColorOutput "?? Servi�o criado mas n�o est� rodando. Status: $($service.Status)" "Yellow"
                return $false
            }
        }
        else {
            Write-ColorOutput "? Falha ao iniciar servi�o. C�digo de erro: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "? Erro ao iniciar servi�o: $_" "Red"
        return $false
    }
}

# Fun��o para mostrar status
function Show-ServiceStatus {
    Write-ColorOutput "`n?? STATUS DO SERVI�O" "Cyan"
    Write-ColorOutput "==================" "Cyan"
    
    if (Test-ServiceExists $ServiceName) {
        $service = Get-Service -Name $ServiceName
        $config = sc.exe qc $ServiceName
        
        Write-ColorOutput "??? Nome: $($service.Name)" "White"
        Write-ColorOutput "?? Nome de exibi��o: $($service.DisplayName)" "White"
        Write-ColorOutput "?? Status: $($service.Status)" "$(if($service.Status -eq 'Running'){'Green'}else{'Red'})"
        Write-ColorOutput "?? Tipo de inicializa��o: $($service.StartType)" "White"
        Write-ColorOutput "?? Execut�vel: $ExePath" "Gray"
        
        if ($service.Status -eq "Running") {
            Write-ColorOutput "`n? Servi�o est� funcionando corretamente!" "Green"
            Write-ColorOutput "?? Verifique seu Discord para mensagens de monitoramento" "Cyan"
        }
        else {
            Write-ColorOutput "`n?? Servi�o n�o est� rodando" "Yellow"
        }
    }
    else {
        Write-ColorOutput "? Servi�o n�o est� instalado" "Red"
    }
}

# Fun��o principal de instala��o
function Install-Complete {
    Write-ColorOutput "?? Iniciando instala��o completa..." "Cyan"
    
    # 1. Remover servi�o existente se houver
    Remove-ExistingService $ServiceName
    
    # 2. Publicar aplica��o
    if (-not (Publish-Application)) {
        Write-ColorOutput "`n? FALHA NA INSTALA��O - N�o foi poss�vel publicar a aplica��o" "Red"
        return $false
    }
    
    # 3. Instalar servi�o
    if (-not (Install-Service)) {
        Write-ColorOutput "`n? FALHA NA INSTALA��O - N�o foi poss�vel criar o servi�o" "Red"
        return $false
    }
    
    # 4. Iniciar servi�o
    if (-not (Start-MonitorService)) {
        Write-ColorOutput "`n?? INSTALA��O PARCIAL - Servi�o instalado mas n�o iniciou automaticamente" "Yellow"
        Write-ColorOutput "?? Tente iniciar manualmente: sc start $ServiceName" "Yellow"
        return $false
    }
    
    # 5. Mostrar status final
    Show-ServiceStatus
    
    Write-ColorOutput "`n?? INSTALA��O CONCLU�DA COM SUCESSO!" "Green"
    Write-ColorOutput "================================================" "Green"
    Write-ColorOutput "?? Para gerenciar: services.msc" "Cyan"
    Write-ColorOutput "?? Para ver logs: Event Viewer ? Windows Logs ? Application" "Cyan"
    Write-ColorOutput "?? Para parar: sc stop $ServiceName" "Cyan"
    Write-ColorOutput "?? Para iniciar: sc start $ServiceName" "Cyan"
    Write-ColorOutput "??? Para desinstalar: Execute este script com -Action uninstall" "Cyan"
    
    return $true
}

# Fun��o para desinstalar
function Uninstall-Service {
    Write-ColorOutput "??? Desinstalando servi�o..." "Yellow"
    
    Remove-ExistingService $ServiceName
    
    if (-not (Test-ServiceExists $ServiceName)) {
        Write-ColorOutput "? Servi�o desinstalado com sucesso!" "Green"
    }
    else {
        Write-ColorOutput "? Falha ao desinstalar servi�o" "Red"
    }
}

# EXECU��O PRINCIPAL
switch ($Action.ToLower()) {
    "install" {
        Install-Complete
    }
    "uninstall" {
        Uninstall-Service
    }
    "reinstall" {
        Write-ColorOutput "?? Reinstalando servi�o..." "Cyan"
        Uninstall-Service
        Start-Sleep -Seconds 2
        Install-Complete
    }
    "status" {
        Show-ServiceStatus
    }
    default {
        Write-ColorOutput "? A��o inv�lida: $Action" "Red"
        Write-ColorOutput "A��es v�lidas: install, uninstall, reinstall, status" "Yellow"
    }
}

Write-ColorOutput "`nPressione qualquer tecla para continuar..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")