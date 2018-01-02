using module "..\..\..\FrameworkTests\TestFrame.psm1"

using module "..\SimpleCheckoutStrategy.psm1"
using module "..\..\Repository\Repo.psm1"
using module ".\TestRepo.psm1"

class TestSimpleCheckoutStrategy : TestFrame {

    TestSimpleCheckoutStrategy() {
        $this.Tests = @("TestEmptyReposMap",
                        "TestMultipleRepos")
    }

    SetUp() {
        if(Test-Path TmpTestDir) { throw "TmpTestDir already exists" }
        New-Item -Type directory TmpTestDir
        Push-Location TmpTestDir
    }

    TearDown() {
        Pop-Location
        Remove-Item -Recurse -Force TmpTestDir
        if(Test-Path TmpTestDir) { throw "TmpTestDir wasn't cleaned up" }
    }

    TestEmptyReposMap() {
        $Strat = [SimpleCheckoutStrategy]::new()
        $Strat.Checkout(@{})
    }

    TestMultipleRepos() {
        [TestRepo]::new("repo1")
        [TestRepo]::new("repo2")

        $CurrentDir = pwd
        $ReposMap = @{
            "repo1" = [Repo]::new("$CurrentDir\repo1", "master", "somedir1/");
            "repo2" = [Repo]::new("$CurrentDir\repo2", "master", "somedir2/")
        }
        $Strat = [SimpleCheckoutStrategy]::new()
        $Strat.Checkout($ReposMap)
        if(!(Test-Path somedir1/.git)) { throw "Expected repo1 to be cloned" }
        if(!(Test-Path somedir2/.git)) { throw "Expected repo2 to be cloned" }
    }
}

if($ShouldRegisterTestFrames) {
    $TestFrameList.Add([TestSimpleCheckoutStrategy]::new())
}