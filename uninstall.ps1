# uninstall.ps1 - remove auto-dial task(s), encrypted credentials and config.
# NOTE: keep this file saved as UTF-8 WITH BOM (contains Chinese UI text).
$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$App = 'pppoe-autodial 卸载程序'

Add-Type -AssemblyName System.Windows.Forms

function Show-Info([string]$Text) {
    [void][System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
function Show-Err([string]$Text) {
    [void][System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}
function Ask-YesNo([string]$Text, [bool]$DefaultNo = $true) {
    $def = if ($DefaultNo) { [System.Windows.Forms.MessageBoxDefaultButton]::Button2 } else { [System.Windows.Forms.MessageBoxDefaultButton]::Button1 }
    $r = [System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question, $def)
    return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
}

try {
    $taskNames = @()
    $configFile = Join-Path $scriptRoot 'config.ps1'
    $hasConfig = Test-Path $configFile
    if ($hasConfig) {
        . $configFile
        if ($connName) { $taskNames += "AutoDial-$connName" }
    }
    $found = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'AutoDial-*' }
    foreach ($t in $found) { if ($taskNames -notcontains $t.TaskName) { $taskNames += $t.TaskName } }

    if ($taskNames.Count -eq 0 -and -not $hasConfig) {
        Show-Info '未找到需要卸载的内容（任务和配置文件都不存在）。'
        exit 0
    }

    if ($taskNames.Count -gt 0) {
        $msg = "将删除以下自动拨号任务：`n`n$($taskNames -join '、')`n`n并清除加密凭据与配置文件。是否继续？"
    }
    else {
        $msg = "未找到相关任务，但存在配置文件。`n`n是否清除加密凭据与配置文件？"
    }
    if (-not (Ask-YesNo $msg $true)) { exit 0 }

    foreach ($t in $taskNames) {
        Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
    }
    foreach ($f in 'cred.dat', 'config.ps1') {
        $p = Join-Path $scriptRoot $f
        if (Test-Path $p) { Remove-Item $p -Force }
    }

    Show-Info "卸载完成：任务与凭据已删除，开机将不再自动拨号。`n`n如需再次启用，双击 安装.cmd 即可；脚本目录可保留或整个手动删除。"
}
catch {
    Show-Err "卸载失败：`n$($_.Exception.Message)"
    exit 1
}
