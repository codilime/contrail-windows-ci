# Build builds all Windows Compute components.

using module ".\SCM\Checkout\CheckoutStrategy.psm1"

. $PSScriptRoot\Common\Init.ps1
. $PSScriptRoot\Common\Job.ps1
. $PSScriptRoot\Build\BuildFunctions.ps1
. $PSScriptRoot\SCM\SCM.ps1

$Job = [Job]::new("Build")

$CheckoutStrat, $Repos = DetermineSCMFromEnv

$Job.Step("Checking out source code tree", {
    $CheckoutStrat.Checkout($Repos)
})

$IsReleaseMode = [bool]::Parse($Env:BUILD_IN_RELEASE_MODE)
Prepare-BuildEnvironment -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH

$DockerDriverOutputDir = "output/docker_driver"
$vRouterOutputDir = "output/vrouter"
$AgentOutputDir = "output/agent"
$LogsDir = "logs"

New-Item -ItemType directory -Path $DockerDriverOutputDir
New-Item -ItemType directory -Path $vRouterOutputDir
New-Item -ItemType directory -Path $AgentOutputDir
New-Item -ItemType directory -Path $LogsDir

Invoke-DockerDriverBuild -DriverSrcPath $Env:DRIVER_SRC_PATH `
                         -SigntoolPath $Env:SIGNTOOL_PATH `
                         -CertPath $Env:CERT_PATH `
                         -CertPasswordFilePath $Env:CERT_PASSWORD_FILE_PATH `
                         -OutputPath $DockerDriverOutputDir `
                         -LogsPath $LogsDir

Invoke-ExtensionBuild -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH `
                      -SigntoolPath $Env:SIGNTOOL_PATH `
                      -CertPath $Env:CERT_PATH `
                      -CertPasswordFilePath $Env:CERT_PASSWORD_FILE_PATH `
                      -ReleaseMode $IsReleaseMode `
                      -OutputPath $vRouterOutputDir `
                      -LogsPath $LogsDir

Invoke-AgentBuild -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH `
                  -SigntoolPath $Env:SIGNTOOL_PATH `
                  -CertPath $Env:CERT_PATH `
                  -CertPasswordFilePath $Env:CERT_PASSWORD_FILE_PATH `
                  -ReleaseMode $IsReleaseMode `
                  -OutputPath $AgentOutputDir `
                  -LogsPath $LogsDir

$Job.Done()
