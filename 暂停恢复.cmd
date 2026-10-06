@echo off
title pppoe-autodial manage
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0manage.ps1"
if errorlevel 1 pause
