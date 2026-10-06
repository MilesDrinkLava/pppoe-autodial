# PPPoE auto-dial configuration (EXAMPLE).
# install.ps1 generates the real config.ps1 automatically.
# Manual setup: copy this file to config.ps1 and fill in your values, then run register-task.ps1.

$connName = 'Broadband'        # name of your PPPoE connection (run `rasdial` to list them)
$userName = 'your-account'     # your PPPoE account
$reconnectSeconds = 15         # reconnect check interval in seconds (applies when reconnect is enabled; min 10)
