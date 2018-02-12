Param([Parameter(Mandatory = $true)] [string] $RootDir,
      [Parameter(Mandatory = $true)] [string] $ConfigDir)

Write-Host "Running PSScriptAnalyzer..."

$PSLinterConfig = "$ConfigDir/PSScriptAnalyzerSettings.psd1"
$Output = Invoke-ScriptAnalyzer $RootDir -Recurse -Setting $PSLinterConfig `
      -ErrorAction Continue -WarningAction Continue
if ($Output) {
      Write-Host ($Output | Format-Table | Out-String)
      exit 1
}

exit 0