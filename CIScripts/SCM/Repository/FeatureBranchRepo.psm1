using module ".\Repo.psm1"
. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class FeatureBranchRepo : Repo {
    [string] $FeatureBranch

    FeatureBranchRepo([string] $Url, [string] $Branch, [string] $FeatureBranch,
                      [string] $Dir)
            : base([string] $Url, [string] $Branch, [string] $Dir) {
        $this.FeatureBranch = $FeatureBranch
    }

    FeatureBranchRepo([Repo] $Other) : base($Other) {
        $this.FeatureBranch = $Other.Branch
    }

    Clone() {
        DeferExcept({
            Write-Host "Cloning branch $($this.FeatureBranch) from $($this.Url)" `
                       "into $($this.Dir)"
            git clone -q -b $this.FeatureBranch $this.Url $this.Dir
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Cloning branch $($this.Branch) from $($this.Url)" `
                           "into $($this.Dir)"
                git clone -q -b $this.Branch $this.Url $this.Dir
            }
        })
    }
}