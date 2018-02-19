Param (
    [Parameter(Mandatory=$true)] [string] $TestbedAddr
)

. $PSScriptRoot\..\Utils\CommonTestCode.ps1
. $PSScriptRoot\..\TestConfigurationUtils.ps1
. $PSScriptRoot\..\..\Common\Aliases.ps1
. $PSScriptRoot\..\..\Common\VMUtils.ps1
. $PSScriptRoot\..\PesterHelpers\PesterHelpers.ps1

. $PSScriptRoot\..\GetTestConfigurationCodiLegacy.ps1
$TestConf = Get-TestConfiguration
$Session = New-PSSession -ComputerName $TestbedAddr -Credential (Get-VMCreds)

Describe "vRouter Agent service" {
    Context "enabling" {
        It "is enabled" {
            Get-AgentServiceStatus -Session $Session `
                | Should Be "Running"
        }

        BeforeEach {
            Enable-AgentService -Session $Session
        }
    }
    
    Context "disabling" {
        It "is disabled" {
            Get-AgentServiceStatus -Session $Session `
                | Should Be "Stopped"
        }

        It "does not restart" {
            Consistently {
                Get-AgentServiceStatus -Session $Session | Should Be "Stopped"
            } -Duration 3
        }

        BeforeEach {
            Enable-AgentService -Session $Session
            Disable-AgentService -Session $Session
        }
    }

    Context "given vRouter Forwarding Extension is NOT running" {
        It "crashes" {
            Eventually {
                Read-SyslogForAgentCrash -Session $Session -After $BeforeCrash `
                    | Should Not BeNullOrEmpty
            } -Duration 60
        }

        BeforeEach {
            Disable-VRouterExtension -Session $Session `
                -AdapterName $TestConf.AdapterName `
                -VMSwitchName $TestConf.VMSwitchName `
                -ForwardingExtensionName $TestConf.ForwardingExtensionName
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",
                "", Justification="Issue #804 from PSScriptAnalyzer GitHub")]
            $BeforeCrash = Invoke-Command -Session $Session -ScriptBlock { Get-Date }
            Enable-AgentService -Session $Session
        }
    }

    Context "given vRouter Forwarding Extension is running" {
        It "runs correctly" {
            Get-AgentServiceStatus -Session $Session `
                | Should Be "Running"
        }

        BeforeEach {
            Enable-AgentService -Session $Session
        }
    }
    
    Context "vRouter Forwarding Extension was disabled while Agent was running" {
        It "crashes" {
            Eventually {
                Read-SyslogForAgentCrash -Session $Session -After $BeforeCrash `
                    | Should Not BeNullOrEmpty
            } -Duration 30
        }

        BeforeEach {
            Enable-AgentService -Session $Session
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",
                "", Justification="Issue #804 from PSScriptAnalyzer GitHub")]
            $BeforeCrash = Invoke-Command -Session $Session -ScriptBlock { Get-Date }
            Disable-VRouterExtension -Session $Session `
                -AdapterName $TestConf.AdapterName `
                -VMSwitchName $TestConf.VMSwitchName `
                -ForwardingExtensionName $TestConf.ForwardingExtensionName
        }
    }

    BeforeEach {
        Initialize-DriverAndExtension -Session $Session -TestConfiguration $TestConf
        Install-Agent -Session $Session
        New-AgentConfigFile -Session $Session -TestConfiguration $TestConf
    }

    AfterEach {
        Clear-TestConfiguration -Session $Session -TestConfiguration $TestConf
        if ((Get-AgentServiceStatus -Session $Session) -eq "Running") {
            Disable-AgentService -Session $Session
        }
        Uninstall-Agent -Session $Session
    }
}
