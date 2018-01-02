. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class Repo {
    [string] $Url
    [string] $Branch
    [string] $Dir

    Repo ([string] $Url, [string] $Branch, [string] $Dir) {
        $this.Url = $Url
        $this.Branch = $Branch
        $this.Dir = $Dir
    }

    Repo([Repo] $Other) {
        $this.Url = $Other.Url
        $this.Branch = $Other.Branch
        $this.Dir = $Other.Dir
    }

    Clone() {
        DeferExcept({
            Write-Host "Cloning branch $($this.Branch) from $($this.Url)" `
                       "into $($this.Dir)"
            git clone -q -b $this.Branch $this.Url $this.Dir
        })
    }
}