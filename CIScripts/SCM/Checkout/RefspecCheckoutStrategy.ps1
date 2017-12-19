using module ".\CheckoutStrategy.psm1"
. $PSScriptRoot\..\Repository\Repo.ps1
. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class RefspecCheckoutStrategy : CheckoutStrategy {
    [string] $TriggeredProject
    [string] $TriggeredBranch
    [string] $Refspec

    RefspecCheckoutStrategy([string] $TriggeredProject,
                            [string] $TriggeredBranch,
                            [string] $Refspec) {
        $this.TriggeredProject = $TriggeredProject
        $this.TriggeredBranch = $TriggeredBranch
        $this.Refspec = $Refspec
    }

    Checkout([System.Collections.Hashtable] $Repos) {
        $this.CloneRepos($Repos)
        $this.TryMergePatchset($Repos)
    }

    CloneRepos([System.Collections.Hashtable] $Repos) {
        $Repos.Values.ForEach({ $_.Clone() })
    }

    TryMergePatchset([System.Collections.Hashtable] $Repos) {
        Push-Location $Repos[$this.TriggeredProject].Dir
        DeferExcept({
            git fetch -q origin $this.Refspec
        })
        DeferExcept({
            git config user.email "you@example.com"
        })
        DeferExcept({
            git config --global user.name "Your Name"
        })
        DeferExcept({
            git merge FETCH_HEAD
        })
        if ($LastExitCode -ne 0) {
            throw "Patchset merging failed."
        }
        Pop-Location
    }
}
