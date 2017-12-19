using module ".\Repository\Repo.psm1"
. $PSScriptRoot\..\Common\DeferExcept.ps1

function Get-ProductionRepos {
    Param ([Parameter(Mandatory = $true)] [string] $TriggeredProject,
           [Parameter(Mandatory = $true)] [string] $TriggeredBranch,
           [Parameter(Mandatory = $true)] [string] $GerritHost)

    $ToolsBranch =      Get-GerritBranch -RepoName "contrail-build" `
                                         -TriggeredProject $TriggeredProject `
                                         -TriggeredBranch $TriggeredBranch
    $SandeshBranch =    Get-GerritBranch -RepoName "contrail-sandesh" `
                                         -TriggeredProject $TriggeredProject `
                                         -TriggeredBranch $TriggeredBranch
    $GenerateDSBranch = Get-GerritBranch -RepoName "contrail-generateDS" `
                                         -TriggeredProject $TriggeredProject `
                                         -TriggeredBranch $TriggeredBranch
    $VRouterBranch =    Get-GerritBranch -RepoName "contrail-vrouter" `
                                         -TriggeredProject $TriggeredProject `
                                         -TriggeredBranch $TriggeredBranch
    $ControllerBranch = Get-GerritBranch -RepoName "contrail-controller" `
                                         -TriggeredProject $TriggeredProject `
                                         -TriggeredBranch $TriggeredBranch

    $Repos = @{
        # Windows docker driver is not on gerrit (yet)
        "contrail-windows-docker" = [Repo]::new("https://github.com/Juniper/contrail-windows-docker-driver/",
                                                "master", "src/github.com/codilime/contrail-windows-docker");

        # Use staging repo for windowsstubs until merge is done.
        "contrail-windowsstubs" = [Repo]::new("https://github.com/CodiLime/contrail-windowsstubs/",
                                              "windows", "windows/");

        "contrail-build" = [Repo]::new("https://$GerritHost/Juniper/contrail-build",
                                       $ToolsBranch, "tools/build/");
        "contrail-sandesh" = [Repo]::new("https://$GerritHost/Juniper/contrail-sandesh",
                                         $SandeshBranch, "tools/sandesh/");
        "contrail-generateDS" = [Repo]::new("https://$GerritHost/Juniper/contrail-generateDS",
                                            $GenerateDSBranch, "tools/generateDS/");
        "contrail-vrouter" = [Repo]::new("https://$GerritHost/Juniper/contrail-vrouter",
                                         $VRouterBranch, "vrouter/");
        "contrail-controller" = [Repo]::new("https://$GerritHost/Juniper/contrail-controller",
                                            $ControllerBranch, "controller/")
    }
    return $Repos
}
function Get-GerritProjectName {
    Param ([Parameter(Mandatory = $true)] [string] $ProjectString)
    if ($ProjectString.StartsWith('Juniper/')) {
        $Proj = $ProjectString.split('/')[1]
    } else {
        $Proj = $ProjectString
    }
    return $Proj
}

function Get-GerritBranch {
    Param ([Parameter(Mandatory = $true)] [string] $RepoName,
           [Parameter(Mandatory = $true)] [string] $TriggeredProject,
           [Parameter(Mandatory = $true)] [string] $TriggeredBranch)
    return $(if($TriggeredProject -eq $RepoName) { $TriggeredBranch } else { "master" })
}
