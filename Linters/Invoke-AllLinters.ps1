. $PSScriptRoot\..\CIScripts\Common\Job.ps1
. $PSScriptRoot\Invoke-PowershellLinter.ps1

function Invoke-AllLinters {
    Param([Parameter(Mandatory = $true)] [string] $RootDir,
          [Parameter(Mandatory = $true)] [string] $ConfigDir)

    $Job.Step("Running linters", {
        $Job.Step("Running Powershell linter (PSScriptAnalyzer)", {
            Write-Host $PSScriptRoot
            $SettingsPath = "$ConfigDir/PSScriptAnalyzerSettings.psd1"
            Invoke-PowershellLinter -RootDir $RootDir -Config $SettingsPath
        })
    })
}