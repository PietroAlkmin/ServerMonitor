@echo off
title Monitor K2Web - Instalacao no Servidor
cls

echo.
echo ============================================
echo    MONITOR K2WEB - INSTALACAO SERVIDOR
echo    Servidor-Producao
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
