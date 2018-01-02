using module ".\Repository\FeatureBranchRepo.psm1"

function Get-StagingRepos {
    Param ([Parameter(Mandatory = $true)] [string] $DriverBranch,
           [Parameter(Mandatory = $true)] [string] $WindowsstubsBranch,
           [Parameter(Mandatory = $true)] [string] $ToolsBranch,
           [Parameter(Mandatory = $true)] [string] $SandeshBranch,
           [Parameter(Mandatory = $true)] [string] $GenerateDSBranch,
           [Parameter(Mandatory = $true)] [string] $VRouterBranch,
           [Parameter(Mandatory = $true)] [string] $ControllerBranch)

    $Repos = @{
        "contrail-windows-docker" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-windows-docker/",
                                     "master", $DriverBranch, "src/github.com/codilime/contrail-windows-docker");
        "contrail-windowsstubs" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-windowsstubs/",
                                     "windows", $WindowsstubsBranch, "windows/");
        "contrail-build" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-build",
                                     "windows", $ToolsBranch, "tools/build/");
        "contrail-sandesh" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-sandesh",
                                     "windows", $SandeshBranch, "tools/sandesh/");
        "contrail-generateDS" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-generateDS",
                                     "windows", $GenerateDSBranch, "tools/generateDS/");
        "contrail-vrouter" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-vrouter",
                                     "windows", $VRouterBranch, "vrouter/");
        "contrail-controller" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-controller",
                                     "windows3.1", $ControllerBranch, "controller/")
    }
    return $Repos
}
