# manage.ps1 - pause / resume the auto-dial task (double-click 暂停恢复.cmd).
# NOTE: keep this file saved as UTF-8 WITH BOM (contains Chinese UI text).
$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$App = 'pppoe-autodial 管理'

Add-Type -AssemblyName System.Windows.Forms

function Show-Info([string]$Text) {
    [void][System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
function Show-Err([string]$Text) {
    [void][System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}
function Ask-YesNo([string]$Text, [bool]$DefaultNo = $false) {
    $def = if ($DefaultNo) { [System.Windows.Forms.MessageBoxDefaultButton]::Button2 } else { [System.Windows.Forms.MessageBoxDefaultButton]::Button1 }
    $r = [System.Windows.Forms.MessageBox]::Show($Text, $App, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question, $def)
    return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
}

try {
    $configFile = Join-Path $scriptRoot 'config.ps1'
    if (-not (Test-Path $configFile)) {
        Show-Err "未检测到配置，自动拨号尚未安装。`n`n请先运行 安装.cmd。"
        exit 1
    }
    . $configFile
    $taskName = "AutoDial-$connName"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Show-Err "未找到自动拨号任务。`n`n可能已被完全卸载，请运行 安装.cmd 重新部署。"
        exit 1
    }

    if ($task.State -eq 'Disabled') {
        if (Ask-YesNo "自动拨号当前已【暂停】。`n`n是否立即恢复？" $false) {
            Enable-ScheduledTask -TaskName $taskName | Out-Null
            Show-Info "已恢复：以后开机将自动拨号。`n（双击暂停恢复.cmd 可随时再暂停）"
        }
    }
    else {
        if (Ask-YesNo "自动拨号当前【运行中】。`n`n是否暂停？（暂停后开机不再自动拨号，可随时恢复）" $false) {
            Disable-ScheduledTask -TaskName $taskName | Out-Null
            Show-Info "已暂停。`n（双击暂停恢复.cmd 可随时恢复）"
        }
    }
}
catch {
    Show-Err "操作失败：`n$($_.Exception.Message)"
    exit 1
}
