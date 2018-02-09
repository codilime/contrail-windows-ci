. $PSScriptRoot\..\CIScripts\Common\Job.ps1
. $PSScriptRoot\Invoke-PowershellLinter.ps1

function Invoke-AllLinters {
    Param([Parameter(Mandatory = $true)] [string] $RootDir,
          [Parameter(Mandatory = $true)] [string] $ConfigDir)

    $SettingsPath = "$ConfigDir/PSScriptAnalyzerSettings.psd1"
    Invoke-PowershellLinter -RootDir $RootDir -Config $SettingsPath
}