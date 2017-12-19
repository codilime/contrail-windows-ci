. $PSScriptRoot\..\..\Common\DeferExcept.ps1
. $PSScriptRoot\Repo.ps1

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
            git clone -q -b $this.FeatureBranch $this.Url $this.Dir
            if ($LASTEXITCODE -ne 0) {
                git clone -q -b $this.Branch $this.Url $this.Dir
            }
        })
    }
}