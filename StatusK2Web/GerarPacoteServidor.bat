@echo off
title Criar Pacote para Servidor
cls

echo.
echo ============================================
echo    GERAR PACOTE PARA SERVIDOR
echo ============================================
echo.

REM Verificar se esta rodando como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Executando como administrador
    echo.
) else (
    echo [AVISO] Recomendado executar como administrador para melhor funcionamento
    echo.
)

echo Criando pacote completo para instalacao no servidor...
echo.

REM Executar script PowerShell
PowerShell -ExecutionPolicy Bypass -File "%~dp0CriarPacoteServidor.ps1"

if %errorLevel% == 0 (
    echo.
    echo ? Pacote criado com sucesso! Verifique a pasta 'Deploy'
    echo.
    echo Para usar no servidor:
    echo 1. Copie a pasta 'Deploy' para o servidor
    echo 2. Execute 'InstalarServidor.bat' como administrador
    echo.
) else (
    echo.
    echo ? Erro na criacao do pacote
    echo.
)

pause