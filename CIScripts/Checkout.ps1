. $PSScriptRoot\Common\Job.ps1
. $PSScriptRoot\Checkout\Zuul.ps1
. $PSScriptRoot\Checkout\NonZuul.ps1

$Job = [Job]::new("Checkout")

# TODO This is a temporary condition to enable smooth phase in of
# Juniper/contrail-windows repository. Once the code is actually
# working, we should eventually switch to that repository.
$WindowsStubsRepositoryPath = "https://github.com/codilime/contrail-windowsstubs.git"
$WindowsStubsBranch = "master"
if (Test-Path Env:JUNIPER_WINDOWSSTUBS) {
    $WindowsStubsRepositoryPath = "contrail-windows.github.com:Juniper/contrail-windows.git"
    if (Test-Path Env:ghprbSourceBranch) {
        $WindowsStubsBranch = $Env:ghprbSourceBranch
    }
}

Get-ZuulRepos -GerritUrl $Env:GERRIT_URL `
              -ZuulProject $Env:ZUUL_PROJECT `
              -ZuulRef $Env:ZUUL_REF `
              -ZuulUrl $Env:ZUUL_URL `
              -ZuulBranch $Env:ZUUL_BRANCH

Get-NonZuulRepos -DriverSrcPath $Env:DRIVER_SRC_PATH `
                 -WindowsStubsRepositoryPath $WindowsStubsRepositoryPath `
                 -WindowsStubsBranch $WindowsStubsBranch

$Job.Done()