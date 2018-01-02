. $PSScriptRoot\..\..\..\Common\DeferExcept.ps1

class TestRepo {
    [string] $Name

    TestRepo([string] $Name) {
        $this.Name = $Name
        New-Item -Type directory $this.Name
        Push-Location $this.Name
            DeferExcept({ git init })
            New-Item -Type file dummy.txt
            DeferExcept({ git add . })
            DeferExcept({ git commit -q -m "TestCommit" })
        Pop-Location
    }

    [TestRepo] CreateBranch([string] $Branch) {
        Push-Location $this.Name
            DeferExcept({ git checkout -q -b $Branch })
            DeferExcept({ git checkout -q master })
        Pop-Location
        return $this
    }

    [TestRepo] CreateFileOnBranch([string] $Filename, [string] $Branch) {
        Push-Location $this.Name
            DeferExcept({ git checkout -q $Branch })
            New-Item -Type file $Filename
            DeferExcept({ git add . })
            DeferExcept({ git commit -m "TestCommit2" })
            DeferExcept({ git checkout -q master })
        Pop-Location
        return $this
    }
}
