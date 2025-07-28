@echo off
PowerShell -ExecutionPolicy Bypass -File "%~dp0Scripts\InstalarNoServidor.ps1" -Action status
pause
