using module ".\CheckoutStrategy.psm1"
using module "..\Repository\Repo.psm1"
. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class ZuulRefCheckoutStrategy : CheckoutStrategy {
    [string] $ZuulUrl
    [string] $ZuulRef
    [string] $Target

    ZuulRefCheckoutStrategy([string] $ZuulUrl, [string] $ZuulRef, `
                            [string] $TargetBranch) {
        $this.ZuulUrl = $ZuulUrl
        $this.ZuulRef = $ZuulRef
        $this.Target = $TargetBranch
    }

    Checkout([System.Collections.Hashtable] $Repos) {
        $Repos.Keys.ForEach({
            $this.CloneZuulRepo($_, $Repos[$_].Dir)
            $this.FetchZuulRef($_, $Repos[$_].Dir)
            $this.TryMergePatchset($Repos[$_].Dir)
        })
    }

    CloneZuulRepo([string] $ProjectName, [string] $Dir) {
        Write-Host "Cloning $($this.ZuulUrl)\$ProjectName into $Dir"
        DeferExcept({ git clone --quiet "$($this.ZuulUrl)\$ProjectName" $Dir })
    }

    FetchZuulRef([string] $ProjectName, [string] $Dir) {
        Push-Location $Dir
        Write-Host "Fetching refspec: $($this.ZuulRef)"
        DeferExcept({ git fetch "$($this.ZuulUrl)\$ProjectName" $this.ZuulRef })
        Write-Host "Checking out FETCH_HEAD"
        DeferExcept({ git checkout FETCH_HEAD })
        DeferExcept({ git reset --hard FETCH_HEAD })
        Pop-Location
    }

    TryMergePatchset([string] $Dir) {
        Push-Location $Dir
        Write-Host "Fetching refspec: $($this.ZuulRef)"
        DeferExcept({ git config user.email "juniper.jenkins@codilime.com" })
        DeferExcept({ git config user.name "Codilime Juniper Jenkins bot" })
        DeferExcept({ git fetch origin })
        DeferExcept({ git merge -m oc-ci-merge "(origin\$($this.Target))" })
        # if ($LastExitCode -ne 0) {
        #     throw "Patchset merging failed."
        # }
        Pop-Location
    }
}
