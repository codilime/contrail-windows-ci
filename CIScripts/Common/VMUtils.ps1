. $PSScriptRoot\Aliases.ps1

function Get-VMCredential {
    $VMUsername = "WORKGROUP\{0}" -f $Env:TESTBED_USR
    $VMPassword = $Env:TESTBED_PSW | ConvertTo-SecureString -AsPlainText -Force
    return New-Object PSCredentialT($VMUsername, $VMPassword)
}

function New-RemoteSessions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Creds",
        Justification="Complains that it's plaintext. It's not.")]
    Param ([Parameter(Mandatory = $true)] [string[]] $VMNames,
           [Parameter(Mandatory = $true)] [PSCredentialT] $Creds)

    $Sessions = [System.Collections.ArrayList] @()
    $VMNames.ForEach({
        $Sess = New-PSSession -ComputerName $_ -Credential $Creds

        Invoke-Command -Session $Sess -ScriptBlock {
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"

            # Refresh PATH
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",
                "", Justification="We refresh PATH on remote machine, we don't use it here.")]
            $Env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        }

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments",
            "", Justification="PSA #804")]
        $Sessions += $Sess
    })
    return $Sessions
}

function New-RemoteSessionsToTestbeds {
    if(-not $Env:TESTBED_ADDRESSES) {
        throw "Cannot create remote sessions to testbeds: $Env:TESTBED_ADDRESSES not set"
    }

    $Creds = Get-VMCredential

    $Testbeds = Get-TestbedAddressesFromEnv
    return New-RemoteSessions -VMNames $Testbeds -Creds $Creds
}

function Get-TestbedAddressesFromEnv {
    return $Env:TESTBED_ADDRESSES.Split(",")
}
