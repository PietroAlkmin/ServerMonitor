@echo off
title Monitor K2Web - Status do Servico
cls

echo.
echo ============================================
echo    MONITOR K2WEB - STATUS DO SERVICO
echo ============================================
echo.

REM Executar script PowerShell para mostrar status
PowerShell -ExecutionPolicy Bypass -File "%~dp0InstalarServico.ps1" -Action status

echo.
pause