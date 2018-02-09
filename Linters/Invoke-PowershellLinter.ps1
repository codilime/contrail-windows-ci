. $PSScriptRoot\..\CIScripts\Common\Exceptions.ps1

function Invoke-PowershellLinter {
    Param([Parameter(Mandatory = $true)] [string] $RootDir,
          [Parameter(Mandatory = $true)] [string] $ConfigDir)
    $Output = Invoke-ScriptAnalyzer $RootDir -Recurse -Setting $ConfigDir `
        -ErrorAction Continue -WarningAction Continue
    if ($Output) {
        Write-Host ($Output | Format-Table | Out-String)
        throw [CILinterException] "PSScriptAnalyzer failed."
    }
}