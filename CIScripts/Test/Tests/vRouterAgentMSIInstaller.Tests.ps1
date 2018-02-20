Param (
    [Parameter(Mandatory=$true)] [string] $TestbedAddr,
    [Parameter(Mandatory=$true)] [string] $TestConfigurationFile
)

. $PSScriptRoot\..\Utils\CommonTestCode.ps1
. $PSScriptRoot\..\Utils\ComponentsInstallation.ps1
. $PSScriptRoot\..\TestConfigurationUtils.ps1
. $PSScriptRoot\..\..\Common\Aliases.ps1
. $PSScriptRoot\..\..\Common\VMUtils.ps1
. $PSScriptRoot\..\PesterHelpers\PesterHelpers.ps1

. $TestConfigurationFile
$TestConf = Get-TestConfiguration
$Session = New-PSSession -ComputerName $TestbedAddr -Credential (Get-VMCreds)

Describe "vRouter Agent MSI installer" {

    function Test-AgentMSIBehaviourCorrect {
        Install-Agent -Session $Session
        Eventually {
            Get-AgentServiceStatus -Session $Session | Should Be "Stopped"
        } -Duration 3

        Uninstall-Agent -Session $Session
        Eventually {
            Get-AgentServiceStatus -Session $Session | Should Throw
        } -Duration 3
    }

    Context "when vRouter Forwarding Extension is not running" {
        It "registers/unregisters Agent service and never enables" {
            Test-AgentMSIBehaviourCorrect
        }
    }

    Context "when vRouter Forwarding Extension is running" {
        It "registers/unregisters Agent service and never enables" {
            Test-AgentMSIBehaviourCorrect
        }

        BeforeEach {
            Install-Extension -Session $Session
            Enable-VRouterExtension -Session $Session -AdapterName $TestConf.AdapterName `
                -VMSwitchName $TestConf.VMSwitchName `
                -ForwardingExtensionName $TestConf.ForwardingExtensionName
        }

        AfterEach {
            Clear-TestConfiguration -Session $Session -TestConfiguration $TestConf
            Uninstall-Extension -Session $Session
        }
    }

    AfterEach {
        # Clear-TestConfiguration -Session $Session -TestConfiguration $TestConf
    }
}
