using module ".\TestFrame.psm1"

$ShouldRegisterTestFrames = $true
[System.Collections.ArrayList] $TestFrameList = @()

function RunFrameworkTests() {

    #. $PSScriptRoot/../SCM/Checkout/Test/TestSimpleCheckoutStrategy.ps1
    . $PSScriptRoot/../SCM/Checkout/Test/TestZuulRefCheckoutStrategy.ps1

    ForEach($TestFrame in $TestFrameList) {
        Write-Host "> [Running test frame: $TestFrame]"
        $TestFrame.Run()
    }
}