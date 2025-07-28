@echo off
title Monitor K2Web - Instalador
cls

echo.
echo ============================================
echo    MONITOR K2WEB - INSTALADOR RAPIDO
echo ============================================
echo.

REM Verificar se esta rodando como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Executando como administrador
) else (
    echo [ERRO] Este instalador precisa ser executado como Administrador!
    echo.
    echo Como executar como administrador:
    echo 1. Clique direito neste arquivo
    echo 2. Escolha "Executar como administrador"
    echo.
    pause
    exit /b 1
)

echo.
echo Iniciando instalacao automatica...
echo.

REM Executar script PowerShell
PowerShell -ExecutionPolicy Bypass -File "%~dp0InstalarServico.ps1" -Action install

echo.
echo Instalacao concluida!
pause