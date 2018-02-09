Param([Parameter(Mandatory = $true)] [string] $RootDir,
      [Parameter(Mandatory = $true)] [string] $ConfigDir)

. $PSScriptRoot\..\CIScripts\Common\Job.ps1
. $PSScriptRoot\Invoke-PowershellLinter.ps1

$SettingsPath = "$ConfigDir/PSScriptAnalyzerSettings.psd1"
Invoke-PowershellLinter -RootDir $RootDir -Config $SettingsPath
