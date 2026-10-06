@echo off
title pppoe-autodial setup
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
    echo.
    echo Install failed - see messages above.
    pause
)
