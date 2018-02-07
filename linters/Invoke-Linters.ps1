# Invoke-ScriptAnalyzer . -Recurse -Settings "$pwd\linters\PSScriptAnalyzerSettings.psd1"

function Invoke-Linters {
    Write-Host "asfd"
    Write-Host $PSScriptRoot, "asdf"
    $Output = Invoke-ScriptAnalyzer . -Recurse `
        -Setting "./PSScriptAnalyzerSettings.psd1" -WarningVariable WarnVar
    if ($WarnVar) {
        throw "Linter failed: $WarnVar"
    }
    return "asf"
}