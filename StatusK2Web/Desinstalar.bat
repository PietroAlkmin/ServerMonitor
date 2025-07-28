@echo off
title Monitor K2Web - Desinstalador
cls

echo.
echo ============================================
echo    MONITOR K2WEB - DESINSTALADOR
echo ============================================
echo.

REM Verificar se esta rodando como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Executando como administrador
) else (
    echo [ERRO] Este desinstalador precisa ser executado como Administrador!
    echo.
    pause
    exit /b 1
)

echo.
echo Desinstalando servico...
echo.

REM Executar script PowerShell para desinstalar
PowerShell -ExecutionPolicy Bypass -File "%~dp0InstalarServico.ps1" -Action uninstall

echo.
echo Desinstalacao concluida!
pause