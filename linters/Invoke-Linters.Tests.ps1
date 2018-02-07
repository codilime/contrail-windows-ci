$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Invoke-Linters" {
    Context "PSScriptAnalyzer" {
        It "if path to settings it good, doesn't throw" {
            { Invoke-Linters } | Should Not Throw
        }

        It "checked on itself, shows no warnings" {
            
        }
    }
}
