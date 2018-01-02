using module "..\..\..\FrameworkTests\TestFrame.psm1"

using module "..\ZuulRefCheckoutStrategy.psm1"
using module "..\..\Repository\Repo.psm1"
using module ".\TestRepo.psm1"

class TestZuulRefCheckoutStrategy : TestFrame {
    [string] $CurrentDir

    TestZuulRefCheckoutStrategy() {
        $this.Tests = @("TestEmptyReposMap",
                        "TestMergesPatchsetFromRef")
        $this.CurrentDir = ""
    }

    SetUp() {
        if(Test-Path TmpTestDir) { throw "TmpTestDir already exists" }
        New-Item -Type directory TmpTestDir
        Push-Location TmpTestDir
        $this.CurrentDir = pwd
    }

    TearDown() {
        Pop-Location
        Remove-Item -Recurse -Force TmpTestDir
        if(Test-Path TmpTestDir) { throw "TmpTestDir wasn't cleaned up" }
    }

    TestEmptyReposMap() {
        $ZuulUrl = "bbb"
        $ZuulRef = "aaa"

        $Strat = $null
        $Strat = [ZuulRefCheckoutStrategy]::new("asdf", "xxx", "master")
        $Strat.Checkout(@{})
    }

    # TestFetchesRef() {
    #     [TestRepo]::new("repo").CreateBranch("some_ref"
    #                           ).CreateFileOnbranch("test.txt", "some_ref")

    #     $ReposMap = @{
    #         "repo" = [Repo]::new("$($this.CurrentDir)\repo",
    #                              "master", "somedir/");
    #     }

    #     $Strat = $null
    #     $Strat = [ZuulRefCheckoutStrategy]::new($this.CurrentDir, "some_ref")
    #     $Strat.Checkout($ReposMap)

    #     if(!(Test-Path somedir/test.txt)) {
    #         throw "Expected branch with test.txt to be fetched"
    #     }
    # }

    TestMergesPatchsetFromRef() {
        [TestRepo]::new("repo").CreateBranch("some_ref"
                              ).CreateFileOnBranch("on_feature.txt", "some_ref"
                              ).CreateFileOnBranch("on_master.txt", "master")

        $ReposMap = @{
            "repo" = [Repo]::new("$($this.CurrentDir)\repo",
                                 "master", "somedir/");
        }

        $Strat = $null
        $Strat = [ZuulRefCheckoutStrategy]::new($this.CurrentDir, `
                                                "some_ref", "master")
        $Strat.Checkout($ReposMap)

        if(!(Test-Path somedir/on_feature.txt) -or 
           !(Test-Path somedir/on_master.txt)) {
            throw "Expected merged branch containing both test files."
        }
    }
}

if($ShouldRegisterTestFrames) {
    $TestFrameList.Add([TestZuulRefCheckoutStrategy]::new())
}