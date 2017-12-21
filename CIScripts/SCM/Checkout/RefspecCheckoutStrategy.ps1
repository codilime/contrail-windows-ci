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
        $Repos.Values.ForEach({
            $this.CloneZuulRepo($_)
            $this.FetchZuulRef($_)
            $this.TryMergePatchset($_)
        })
    }

    CloneZuulRepo() {
        DeferExcept({
            git clone --quiet $GIT_ORIGIN/$ZUUL_PROJECT .
        })
    }

    FetchZuulRef() {
        DeferExcept({
            git fetch $ZUUL_URL/$ZUUL_PROJECT $ZUUL_REF
        })
        DeferExcept({
            git checkout FETCH_HEAD
        })
        DeferExcept({
            git reset --hard FETCH_HEAD
        })
    }

    TryMergePatchset([Repo] $Repo) {
        Push-Location $Repo.Dir
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
