Param([Parameter(Mandatory = $true)] [string] $RootDir,
      [Parameter(Mandatory = $true)] [string] $ConfigDir)

$PSLinterConfig = "$ConfigDir/PSScriptAnalyzerSettings.psd1"
Write-Host "Running PSScriptAnalyzer... (config from $PSLinterConfig)"

$Output = Invoke-ScriptAnalyzer $RootDir -Recurse -Setting $PSLinterConfig `
      -ErrorAction Continue -WarningAction Continue
if ($Output) {
      Write-Host ($Output | Format-Table | Out-String)
      exit 1
}

# test
$a = 0

exit 0