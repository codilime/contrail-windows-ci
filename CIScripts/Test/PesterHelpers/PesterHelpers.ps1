﻿Import-Module Pester

. $PSScriptRoot\..\..\Common\Aliases.ps1
. $PSScriptRoot\..\..\Common\Invoke-UntilSucceeds.ps1

function Consistently {
    <#
    .SYNOPSIS
    Utility wrapper for Pester for making sure that the assert is consistently true.
    It works by retrying the assert every Interval seconds, up to Duration.
    .PARAMETER ScriptBlock
    ScriptBlock containing a Pester assertion.
    .PARAMETER Interval
    Interval (in seconds) between retries.
    .PARAMETER Duration
    Timeout (in seconds).
    #>
    Param (
        [Parameter(Mandatory=$true)] [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory=$false)] [int] $Interval = 1,
        [Parameter(Mandatory=$true)] [int] $Duration = 3
    )
    if ($Duration -lt $Interval) {
        throw [CITimeoutException] "Duration must be longer than interval"
    }
    if ($Interval -eq 0) {
        throw [CITimeoutException] "Interval must not be equal to zero"
    }
    $StartTime = Get-Date
    do {
        & $ScriptBlock
        Start-Sleep -s $Interval
    } while (((Get-Date) - $StartTime).Seconds -lt $Duration)
}

function Eventually {
    <#
    .SYNOPSIS
    Utility wrapper for Pester for making sure that the assert is eventually true.
    It works by retrying the assert every Interval seconds, up to Duration. If until then,
    the assert is not true, Eventually fails.
    .PARAMETER ScriptBlock
    ScriptBlock containing a Pester assertion.
    .PARAMETER Interval
    Interval (in seconds) between retries.
    .PARAMETER Duration
    Timeout (in seconds).
    #>
    Param (
        [Parameter(Mandatory=$true)] [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory=$false)] [int] $Interval = 1,
        [Parameter(Mandatory=$true)] [int] $Duration = 3
    )
    $ScriptBlock | Invoke-UntilSucceeds -Interval $Interval -Duration $Duration
}
