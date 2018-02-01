function Test-VTestScenarios {
    Param ([Parameter(Mandatory = $true)] [System.Management.Automation.Runspaces.PSSession] $Session,
           [Parameter(Mandatory = $true)] [TestConfiguration] $TestConfiguration)

    . $PSScriptRoot\..\Utils\CommonTestCode.ps1

    $Job.StepQuiet($MyInvocation.MyCommand.Name, {
        Write-Host "===> Running vtest scenarios"

        Install-Extension -Session $Session
        Install-Utils -Session $Session
        Enable-VRouterExtension -Session $Session -AdapterName $TestConfiguration.AdapterName `
            -VMSwitchName $TestConfiguration.VMSwitchName `
            -ForwardingExtensionName $TestConfiguration.ForwardingExtensionName

        $VMSwitchName = $TestConfiguration.VMSwitchName
        Invoke-Command -Session $Session -ScriptBlock {
            Push-Location C:\Artifacts\

            ls
            Write-Host ""
            ls .\vtest
            Write-Host ""

            # we don't need to check the exit code because this script raises an exception on failure
            .\vtest\all_tests_run.ps1 -VMSwitchName $Using:VMSwitchName -TestsFolder vtest\tests

            Pop-Location
        }

        Clear-TestConfiguration -Session $Session -TestConfiguration $TestConfiguration
        Uninstall-Utils -Session $Session
        Uninstall-Extension -Session $Session

        Write-Host "===> Success!"
    })
}
