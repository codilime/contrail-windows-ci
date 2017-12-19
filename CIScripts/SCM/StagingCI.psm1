using module ".\Repository\FeatureBranchRepo.psm1"

function Get-StagingRepos {
    Param ([Parameter(Mandatory = $true)] [string] $FeatureBranch)

    $Repos = @{
        "contrail-windows-docker" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-windows-docker/",
                                     "master", $FeatureBranch, "src/github.com/codilime/contrail-windows-docker");
        "contrail-windowsstubs" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-windowsstubs/",
                                     "windows", $FeatureBranch, "windows/");
        "contrail-build" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-build",
                                     "windows", $FeatureBranch, "tools/build/");
        "contrail-sandesh" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-sandesh",
                                     "windows", $FeatureBranch, "tools/sandesh/");
        "contrail-generateDS" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-generateDS",
                                     "windows", $FeatureBranch, "tools/generateDS/");
        "contrail-vrouter" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-vrouter",
                                     "windows", $FeatureBranch, "vrouter/");
        "contrail-controller" = `
            [FeatureBranchRepo]::new("https://github.com/CodiLime/contrail-controller",
                                     "windows3.1", $FeatureBranch, "controller/")
    }
    return $Repos
}
