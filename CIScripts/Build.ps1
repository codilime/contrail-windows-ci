# Build builds selected Windows Compute components.

. $PSScriptRoot\Common\Init.ps1
. $PSScriptRoot\Common\Job.ps1
. $PSScriptRoot\Common\Components.ps1
. $PSScriptRoot\Build\BuildFunctions.ps1
. $PSScriptRoot\Build\StagingCI.ps1
. $PSScriptRoot\Build\Zuul.ps1

$Job = [Job]::new("Build")

$IsTriggeredByZuul = Test-Path Env:ZUUL_PROJECT

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

if($IsTriggeredByZuul) {
    # Build is triggered by Zuul, when someone submits a pull
    # request to review.opencontrail.org.

    Get-ZuulRepos -GerritUrl $Env:GERRIT_URL `
                    -ZuulProject $Env:ZUUL_PROJECT `
                    -ZuulRef $Env:ZUUL_REF `
                    -ZuulUrl $Env:ZUUL_URL `
                    -ZuulBranch $Env:ZUUL_BRANCH

    Get-NonZuulRepos -DriverSrcPath $Env:DRIVER_SRC_PATH `
                       -WindowsStubsRepositoryPath $WindowsStubsRepositoryPath `
                       -WindowsStubsBranch $WindowsStubsBranch
} else {
    # Build is triggered by Jenkins GitHub plugin, when someone submits a pull
    # request to select github.com/codilime/* repos.

    $Repos = Get-StagingRepos -DriverBranch $ENV:DRIVER_BRANCH `
                              -WindowsStubsRepositoryPath $WindowsStubsRepositoryPath `
                              -WindowsStubsDefaultBranch $WindowsStubsBranch `
                              -WindowsstubsBranch $Env:WINDOWSSTUBS_BRANCH `
                              -ToolsBranch $Env:TOOLS_BRANCH `
                              -SandeshBranch $Env:SANDESH_BRANCH `
                              -GenerateDSBranch $Env:GENERATEDS_BRANCH `
                              -VRouterBranch $Env:VROUTER_BRANCH `
                              -ControllerBranch $Env:CONTROLLER_BRANCH

    Get-Repos -Repos $Repos
}

$IsReleaseMode = [bool]::Parse($Env:BUILD_IN_RELEASE_MODE)
Initialize-BuildEnvironment -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH

$DockerDriverOutputDir = "output/docker_driver"
$vRouterOutputDir = "output/vrouter"
$AgentOutputDir = "output/agent"
$LogsDir = "logs"

New-Item -ItemType directory -Path $DockerDriverOutputDir | Out-Null
New-Item -ItemType directory -Path $vRouterOutputDir | Out-Null
New-Item -ItemType directory -Path $AgentOutputDir | Out-Null
New-Item -ItemType directory -Path $LogsDir | Out-Null

$ComponentsToBuild = Get-ComponentsToBuild

if ("DockerDriver" -In $ComponentsToBuild) {
    Invoke-DockerDriverBuild -DriverSrcPath $Env:DRIVER_SRC_PATH `
        -SigntoolPath $Env:SIGNTOOL_PATH `
        -CertPath $Env:CERT_PATH `
        -CertPasswdFilePath $Env:CERT_PASSWORD_FILE_PATH `
        -OutputPath $DockerDriverOutputDir `
        -LogsPath $LogsDir
}

if ("Extension" -In $ComponentsToBuild) {
    Invoke-ExtensionBuild -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH `
        -SigntoolPath $Env:SIGNTOOL_PATH `
        -CertPath $Env:CERT_PATH `
        -CertPasswdFilePath $Env:CERT_PASSWORD_FILE_PATH `
        -ReleaseMode $IsReleaseMode `
        -OutputPath $vRouterOutputDir `
        -LogsPath $LogsDir
}

if ("Agent" -In $ComponentsToBuild) {
    Invoke-AgentBuild -ThirdPartyCache $Env:THIRD_PARTY_CACHE_PATH `
        -SigntoolPath $Env:SIGNTOOL_PATH `
        -CertPath $Env:CERT_PATH `
        -CertPasswdFilePath $Env:CERT_PASSWORD_FILE_PATH `
        -ReleaseMode $IsReleaseMode `
        -OutputPath $AgentOutputDir `
        -LogsPath $LogsDir
}

if ("AgentTests" -In $ComponentsToBuild) {
    Invoke-AgentTestsBuild -LogsPath $LogsDir `
        -ReleaseMode $IsReleaseMode
}

$Job.Done()

exit 0
