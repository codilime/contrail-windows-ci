. $PSScriptRoot\..\..\Common\Aliases.ps1

function Test-MultiEnableDisableExtension {
    Param ([Parameter(Mandatory = $true)] [PSSessionT] $Session,
           [Parameter(Mandatory = $true)] [int] $EnableDisableCount,
           [Parameter(Mandatory = $true)] [TestConfiguration] $TestConfiguration)

    . $PSScriptRoot\..\Utils\CommonTestCode.ps1

    $Job.StepQuiet($MyInvocation.MyCommand.Name, {
        Write-Host "===> Running Multi Enable-Disable Extension Test ($EnableDisableCount times)..."

        foreach ($I in 1..$EnableDisableCount) {
            Initialize-TestConfiguration -Session $Session -TestConfiguration $TestConfiguration
            Clear-TestConfiguration -Session $Session -TestConfiguration $TestConfiguration
        }

        Write-Host "===> Success!"
    })
}
