# ============================================
# SCRIPT DE CRIA��O DE PACOTE PARA SERVIDOR
# Cria um pacote completo para deploy no servidor
# ============================================

param(
    [string]$OutputPath = "Deploy",
    [string]$ServerName = "Servidor-Producao"
)

function Write-ColorOutput([string]$message, [string]$color = "White") {
    Write-Host $message -ForegroundColor $color
}

Write-ColorOutput "`n?? ================================" "Cyan"
Write-ColorOutput "   CRIANDO PACOTE PARA SERVIDOR" "Cyan"
Write-ColorOutput "================================`n" "Cyan"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = $ScriptPath

# Garantir que estamos no diret�rio correto
Set-Location $ProjectPath

# Definir caminho absoluto para Deploy
$OutputPath = Join-Path $ProjectPath $OutputPath

Write-ColorOutput "?? Pasta do projeto: $ProjectPath" "Gray"
Write-ColorOutput "?? Pasta de deploy: $OutputPath" "Gray"

# ETAPA 1: Parar servi�o se estiver rodando
Write-ColorOutput "?? Verificando se servi�o est� rodando..." "Yellow"
try {
    $service = Get-Service -Name "MonitorK2Web" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-ColorOutput "?? Parando servi�o para liberar arquivos..." "Yellow"
        Stop-Service -Name "MonitorK2Web" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        Write-ColorOutput "? Servi�o parado temporariamente" "Green"
        $serviceStopped = $true
    }
    else {
        Write-ColorOutput "?? Servi�o n�o est� rodando" "Gray"
        $serviceStopped = $false
    }
}
catch {
    Write-ColorOutput "?? Servi�o n�o encontrado" "Gray"
    $serviceStopped = $false
}

# ETAPA 2: Limpar pasta de deploy anterior
if (Test-Path $OutputPath) {
    Write-ColorOutput "??? Limpando deploy anterior..." "Yellow"
    try {
        Remove-Item $OutputPath -Recurse -Force
        Write-ColorOutput "? Deploy anterior removido" "Green"
    }
    catch {
        Write-ColorOutput "?? Aviso: N�o foi poss�vel remover alguns arquivos: $($_.Exception.Message)" "Yellow"
    }
}

# ETAPA 3: Criar estrutura de pastas
Write-ColorOutput "?? Criando estrutura de deploy..." "Yellow"
try {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    New-Item -Path "$OutputPath\Scripts" -ItemType Directory -Force | Out-Null
    New-Item -Path "$OutputPath\Executavel" -ItemType Directory -Force | Out-Null
    Write-ColorOutput "? Estrutura criada com sucesso" "Green"
}
catch {
    Write-ColorOutput "? Erro ao criar estrutura: $($_.Exception.Message)" "Red"
    exit 1
}

# ETAPA 4: Limpar builds anteriores de forma segura
Write-ColorOutput "?? Limpando builds anteriores..." "Yellow"
try {
    # Usar dotnet clean primeiro
    dotnet clean --verbosity quiet
    
    # Remover pastas espec�ficas se existirem
    @("bin", "obj") | ForEach-Object {
        if (Test-Path $_) {
            try {
                Remove-Item $_ -Recurse -Force
                Write-ColorOutput "? Pasta $_ removida" "Gray"
            }
            catch {
                Write-ColorOutput "?? N�o foi poss�vel remover $_`: $($_.Exception.Message)" "Yellow"
                # Tentar matar processos que podem estar usando os arquivos
                Get-Process | Where-Object { $_.Name -like "*StatusK2Web*" } | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                try {
                    Remove-Item $_ -Recurse -Force
                    Write-ColorOutput "? Pasta $_ removida ap�s finalizar processos" "Gray"
                }
                catch {
                    Write-ColorOutput "?? Continuando apesar do erro de limpeza..." "Yellow"
                }
            }
        }
    }
}
catch {
    Write-ColorOutput "?? Erro durante limpeza: $($_.Exception.Message)" "Yellow"
}

# ETAPA 5: Publicar aplica��o
Write-ColorOutput "?? Publicando aplica��o para produ��o..." "Yellow"
try {
    # Restaurar pacotes
    Write-ColorOutput "?? Restaurando pacotes..." "Gray"
    dotnet restore --verbosity quiet
    
    # Publicar aplica��o
    Write-ColorOutput "?? Compilando e publicando..." "Gray"
    $publishResult = dotnet publish -c Release --self-contained true --runtime win-x64 -o "$OutputPath\Executavel" --verbosity minimal 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$OutputPath\Executavel\StatusK2Web.exe")) {
        Write-ColorOutput "? Aplica��o publicada com sucesso!" "Green"
        
        $fileSize = [math]::Round((Get-Item "$OutputPath\Executavel\StatusK2Web.exe").Length / 1MB, 2)
        Write-ColorOutput "?? Tamanho do execut�vel: $fileSize MB" "Gray"
    }
    else {
        Write-ColorOutput "? Erro na publica��o:" "Red"
        Write-ColorOutput $publishResult "Red"
        
        # Tentar reiniciar servi�o se parou
        if ($serviceStopped) {
            Write-ColorOutput "?? Reiniciando servi�o..." "Yellow"
            Start-Service -Name "MonitorK2Web" -ErrorAction SilentlyContinue
        }
        exit 1
    }
}
catch {
    Write-ColorOutput "? Erro durante publica��o: $($_.Exception.Message)" "Red"
    
    # Tentar reiniciar servi�o se parou
    if ($serviceStopped) {
        Write-ColorOutput "?? Reiniciando servi�o..." "Yellow"
        Start-Service -Name "MonitorK2Web" -ErrorAction SilentlyContinue
    }
    exit 1
}

# ETAPA 6: Reiniciar servi�o se foi parado
if ($serviceStopped) {
    Write-ColorOutput "?? Reiniciando servi�o..." "Yellow"
    try {
        Start-Service -Name "MonitorK2Web"
        Write-ColorOutput "? Servi�o reiniciado" "Green"
    }
    catch {
        Write-ColorOutput "?? Erro ao reiniciar servi�o: $($_.Exception.Message)" "Yellow"
    }
}

# ETAPA 7: Copiar scripts de instala��o
Write-ColorOutput "?? Copiando scripts de instala��o..." "Yellow"

# Script de instala��o para servidor
$InstallScript = @"
# ============================================
# INSTALADOR PARA SERVIDOR DE PRODU��O
# Monitor K2Web Service
# ============================================

param(
    [string]`$Action = "install",
    [string]`$ServiceName = "MonitorK2Web",
    [string]`$DisplayName = "Monitor K2Web Service - $ServerName"
)

function Write-ColorOutput([string]`$message, [string]`$color = "White") {
    Write-Host `$message -ForegroundColor `$color
}

function Test-Administrator {
    `$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$currentUser)
    return `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-ColorOutput "`n?? ================================" "Cyan"
Write-ColorOutput "   MONITOR K2WEB - SERVIDOR" "Cyan"
Write-ColorOutput "   $ServerName" "Cyan"
Write-ColorOutput "================================`n" "Cyan"

if (-not (Test-Administrator)) {
    Write-ColorOutput "? ERRO: Execute como Administrador!" "Red"
    Write-ColorOutput "?? Clique direito no PowerShell e escolha 'Executar como administrador'" "Yellow"
    pause
    exit 1
}

`$ScriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$ExePath = Join-Path `$ScriptPath "..\Executavel\StatusK2Web.exe"

Write-ColorOutput "?? Pasta de instala��o: `$ScriptPath" "Gray"
Write-ColorOutput "?? Execut�vel: `$ExePath" "Gray"

if (-not (Test-Path `$ExePath)) {
    Write-ColorOutput "? Execut�vel n�o encontrado!" "Red"
    Write-ColorOutput "?? Verifique se o arquivo est� em: `$ExePath" "Yellow"
    pause
    exit 1
}

function Remove-ExistingService(`$serviceName) {
    try {
        `$service = Get-Service -Name `$serviceName -ErrorAction SilentlyContinue
        if (`$service) {
            Write-ColorOutput "?? Parando servi�o existente..." "Yellow"
            Stop-Service -Name `$serviceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            
            Write-ColorOutput "??? Removendo servi�o existente..." "Yellow"
            sc.exe delete `$serviceName | Out-Null
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-ColorOutput "?? Erro ao remover servi�o: `$_" "Yellow"
    }
}

switch (`$Action.ToLower()) {
    "install" {
        Write-ColorOutput "?? Instalando servi�o no servidor..." "Yellow"
        
        Remove-ExistingService `$ServiceName
        
        # Criar servi�o
        `$createResult = sc.exe create `$ServiceName binPath= `"`$ExePath`" displayname= `"`$DisplayName`"
        
        if (`$LASTEXITCODE -eq 0) {
            Write-ColorOutput "? Servi�o criado!" "Green"
            
            # Configura��es avan�adas para servidor
            sc.exe config `$ServiceName start= auto | Out-Null
            sc.exe description `$ServiceName "Monitor do servidor K2Web com notifica��es Discord - Instalado em `$(Get-Date)" | Out-Null
            sc.exe failure `$ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/20000 | Out-Null
            
            # Iniciar servi�o
            Write-ColorOutput "?? Iniciando servi�o..." "Yellow"
            sc.exe start `$ServiceName | Out-Null
            
            Start-Sleep -Seconds 5
            
            `$service = Get-Service -Name `$ServiceName
            if (`$service.Status -eq "Running") {
                Write-ColorOutput "`n?? INSTALA��O CONCLU�DA COM SUCESSO!" "Green"
                Write-ColorOutput "================================================" "Green"
                Write-ColorOutput "??? Nome do servi�o: `$ServiceName" "Cyan"
                Write-ColorOutput "?? Status: `$(`$service.Status)" "Green"
                Write-ColorOutput "?? Inicializa��o: Autom�tica" "Cyan"
                Write-ColorOutput "?? Discord: Configurado" "Cyan"
                Write-ColorOutput "?? Intervalo: 5 minutos" "Cyan"
                Write-ColorOutput "`n?? Para gerenciar:" "White"
                Write-ColorOutput "   � Ver status: sc query `$ServiceName" "Gray"
                Write-ColorOutput "   � Parar: sc stop `$ServiceName" "Gray"
                Write-ColorOutput "   � Iniciar: sc start `$ServiceName" "Gray"
                Write-ColorOutput "   � Logs: Event Viewer ? Application" "Gray"
            }
            else {
                Write-ColorOutput "?? Servi�o instalado mas n�o iniciou. Status: `$(`$service.Status)" "Yellow"
            }
        }
        else {
            Write-ColorOutput "? Falha ao criar servi�o!" "Red"
        }
    }
    
    "uninstall" {
        Write-ColorOutput "??? Desinstalando servi�o..." "Yellow"
        Remove-ExistingService `$ServiceName
        Write-ColorOutput "? Servi�o removido!" "Green"
    }
    
    "status" {
        try {
            `$service = Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue
            if (`$service) {
                Write-ColorOutput "`n?? STATUS DO SERVI�O" "Cyan"
                Write-ColorOutput "==================" "Cyan"
                Write-ColorOutput "??? Nome: `$(`$service.Name)" "White"
                Write-ColorOutput "?? Nome de exibi��o: `$(`$service.DisplayName)" "White"
                Write-ColorOutput "?? Status: `$(`$service.Status)" "`$(if(`$service.Status -eq 'Running'){'Green'}else{'Red'})"
                Write-ColorOutput "?? Tipo de inicializa��o: `$(`$service.StartType)" "White"
                Write-ColorOutput "?? Execut�vel: `$ExePath" "Gray"
                Write-ColorOutput "??? Servidor: $ServerName" "Cyan"
            }
            else {
                Write-ColorOutput "? Servi�o n�o encontrado!" "Red"
            }
        }
        catch {
            Write-ColorOutput "? Erro ao verificar status: `$_" "Red"
        }
    }
    
    default {
        Write-ColorOutput "? A��o inv�lida: `$Action" "Red"
        Write-ColorOutput "A��es: install, uninstall, status" "Yellow"
    }
}

Write-ColorOutput "`nPressione qualquer tecla para continuar..." "Gray"
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$InstallScript | Out-File -FilePath "$OutputPath\Scripts\InstalarNoServidor.ps1" -Encoding UTF8

# Scripts batch
$BatchScript = @"
@echo off
title Monitor K2Web - Instalacao no Servidor
cls

echo.
echo ============================================
echo    MONITOR K2WEB - INSTALACAO SERVIDOR
echo    $ServerName
echo ============================================
echo.

REM Verificar administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Executando como administrador
) else (
    echo [ERRO] Execute como Administrador!
    pause
    exit /b 1
)

echo.
echo Instalando no servidor...
echo.

PowerShell -ExecutionPolicy Bypass -File "%~dp0Scripts\InstalarNoServidor.ps1" -Action install

echo.
pause
"@

$BatchScript | Out-File -FilePath "$OutputPath\InstalarServidor.bat" -Encoding ASCII

# Scripts de gerenciamento
@"
@echo off
PowerShell -ExecutionPolicy Bypass -File "%~dp0Scripts\InstalarNoServidor.ps1" -Action uninstall
pause
"@ | Out-File -FilePath "$OutputPath\DesinstalarServidor.bat" -Encoding ASCII

@"
@echo off
PowerShell -ExecutionPolicy Bypass -File "%~dp0Scripts\InstalarNoServidor.ps1" -Action status
pause
"@ | Out-File -FilePath "$OutputPath\StatusServidor.bat" -Encoding ASCII

# Criar README para servidor
$ServerReadme = @"
# ?? Monitor K2Web - Deploy para Servidor

## ?? Conte�do do Pacote

- **InstalarServidor.bat** - Instalador principal (execute como admin)
- **DesinstalarServidor.bat** - Remove o servi�o 
- **StatusServidor.bat** - Verifica status do servi�o
- **Executavel/** - Aplica��o compilada
- **Scripts/** - Scripts PowerShell de instala��o

## ?? Instala��o no Servidor

### Pr�-requisitos
- ? Windows Server 2016+ ou Windows 10+
- ? Privil�gios de Administrador
- ? Conex�o com internet para Discord
- ? .NET 8 Runtime (inclu�do no pacote)

### Passos de Instala��o

1. **Copie esta pasta completa** para o servidor
2. **Clique direito** em `InstalarServidor.bat`  
3. **Escolha** "Executar como administrador"
4. **Aguarde** a instala��o autom�tica
5. **Verifique** se recebeu mensagem no Discord

### Verifica��o da Instala��o
# Ver se est� rodando
sc query "MonitorK2Web"

# Ver logs
Event Viewer ? Windows Logs ? Application ? Procurar "K2MonitoringService"

# Gerenciador de Servi�os  
services.msc ? Procurar "Monitor K2Web Service"
## ?? Configura��es

### URLs e Configura��es Atuais
- **URL Monitorada:** https://k2datacenter.com.br/k2web.dll#
- **Intervalo:** 5 minutos
- **Timeout:** 30 segundos  
- **Discord:** Webhook configurado

### Para Alterar Configura��es
1. Edite o c�digo fonte no desenvolvimento
2. Gere novo pacote de deploy
3. Execute DesinstalarServidor.bat
4. Copie nova vers�o
5. Execute InstalarServidor.bat

## ?? Troubleshooting

### Servi�o n�o inicia
1. Verifique logs no Event Viewer
2. Execute StatusServidor.bat
3. Teste conectividade com a URL
4. Verifique firewall/antiv�rus

### Discord n�o recebe mensagens  
1. Teste webhook manualmente
2. Verifique conectividade com internet
3. Confirme URL do webhook no c�digo

## ?? Suporte

- **Logs:** Event Viewer ? Application ? K2MonitoringService
- **Status:** StatusServidor.bat
- **Reinstalar:** DesinstalarServidor.bat + InstalarServidor.bat

---
**Pacote gerado em:** $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
**Servidor de destino:** $ServerName
"@

$ServerReadme | Out-File -FilePath "$OutputPath\README-SERVIDOR.md" -Encoding UTF8

# Informa��es finais
Write-ColorOutput "`n?? PACOTE CRIADO COM SUCESSO!" "Green"
Write-ColorOutput "===============================================" "Green"
Write-ColorOutput "?? Localiza��o: $((Get-Item $OutputPath).FullName)" "Cyan"
Write-ColorOutput "?? Tamanho total: $([math]::Round((Get-ChildItem $OutputPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" "Cyan"

Write-ColorOutput "`n?? PR�XIMOS PASSOS:" "Yellow"
Write-ColorOutput "1. Copie a pasta '$((Get-Item $OutputPath).Name)' completa para o servidor" "White"
Write-ColorOutput "2. No servidor, execute 'InstalarServidor.bat' como admin" "White"
Write-ColorOutput "3. Verifique se recebeu mensagem no Discord" "White"
Write-ColorOutput "4. Use 'StatusServidor.bat' para monitorar" "White"

Write-ColorOutput "`n?? Arquivos inclu�dos:" "Cyan"
Get-ChildItem $OutputPath -Recurse | ForEach-Object {
    if (-not $_.PSIsContainer) {
        $relativePath = $_.FullName.Replace($OutputPath, "")
        Write-ColorOutput "   $relativePath" "Gray"
    }
}

Write-ColorOutput "`nPacote pronto para deploy!" "Green"