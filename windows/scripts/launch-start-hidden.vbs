Option Explicit

Dim shell, fileSystem, scriptDirectory, powershellPath, launcherScript, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
powershellPath = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
launcherScript = scriptDirectory & "\launch-start-dream-skin.ps1"
command = Chr(34) & powershellPath & Chr(34) & " -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File " & Chr(34) & launcherScript & Chr(34)

If WScript.Arguments.Count > 0 Then
  command = command & " -Port " & WScript.Arguments(0)
End If

shell.Run command, 0, False
