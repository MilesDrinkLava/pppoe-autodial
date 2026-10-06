' Hidden launcher: runs dial.ps1 with no visible window (prevents console flash
' when triggered repeatedly by Task Scheduler).
Dim fso, sh, here
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & here & "\dial.ps1""", 0, False
