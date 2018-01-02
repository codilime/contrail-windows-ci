using module ".\StagingCI.psm1"
using module ".\ProdCI.psm1"
using module ".\Checkout\CheckoutStrategy.psm1"
using module ".\Checkout\SimpleCheckoutStrategy.psm1"

function DetermineSCMFromEnv() {
    $IsTriggeredByGerrit = Test-Path Env:GERRIT_CHANGE_ID
    if($IsTriggeredByGerrit) {
        # Build is triggered by Jenkins Gerrit plugin, when someone submits a pull
        # request to review.opencontrail.org.

        $TriggeredProject = Get-GerritProjectName -ProjectString $ENV:GERRIT_PROJECT
        $TriggeredBranch = $ENV:GERRIT_BRANCH
        $Repos = Get-ProductionRepos -TriggeredProject $TriggeredProject `
                                     -TriggeredBranch $TriggeredBranch `
                                     -GerritHost $Env:GERRIT_HOST
        $CheckoutStrat = [RefspecCheckoutStrategy]::new( `
            $TriggeredProject, $TriggeredBranch, $Env:GERRIT_REFSPEC)
    } else {
        # Build is triggered by Jenkins GitHub plugin, when someone submits a pull
        # request to select github.com/codilime/* repos.

        $Repos = Get-StagingRepos -DriverBranch $ENV:DRIVER_BRANCH `
                                  -WindowsstubsBranch $ENV:WINDOWSSTUBS_BRANCH `
                                  -ToolsBranch $Env:TOOLS_BRANCH `
                                  -SandeshBranch $Env:SANDESH_BRANCH `
                                  -GenerateDSBranch $Env:GENERATEDS_BRANCH `
                                  -VRouterBranch $Env:VROUTER_BRANCH `
                                  -ControllerBranch $Env:CONTROLLER_BRANCH
        $CheckoutStrat = [SimpleCheckoutStrategy]::new()
    }
    return $CheckoutStrat, $Repos
}