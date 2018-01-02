class TestFrame {
    [System.Collections.ArrayList] $Tests

    TestFrame() {
        $this.Tests = @()
    }

    SetUp() {}
    TearDown() {}

    Run() {
        if(!$this.Tests) {
            throw "No tests found!"
        }
        ForEach($Test in $this.Tests) {
            Write-Host "=> [Running test case: $Test]"

            Write-Host "==> [Setting up...]"
            $this.SetUp()

            Write-host "==> [Executing...]"
            $WarnVar = ""
            $ErrVar = ""
            Invoke-Method -InputObject $this -MethodName $Test `
                          -WarningVariable WarnVar -ErrorVariable ErrVar

            Write-Host "==> [Tearing down...]"
            $this.TearDown()

            if($WarnVar -ne "") {
                throw $WarnVar
            } elseif ($ErrVar -ne "") {
                throw $ErrVar
            }
        }
    }
}