function Invoke-NativeCommandImpl {
    Param (
        [Parameter(Mandatory = $true)] [ScriptBlock] $ScriptBlock
    )
    & {
        #$ErrorActionPreference = "SilentlyContinue"
        write-host $ErrorActionPreference
        write-host "kek"
        write-host $Error
        & $ScriptBlock
        write-host $ErrorActionPreference
        write-host "kek"
        write-host $Error

        $Error.Clear()
        $Global:Error.Clear()
    }
    return $LastExitCode
}

function Invoke-NativeCommand {
    Param (
        [Parameter(Mandatory = $true)] [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory = $false)] [Bool] $AllowNonZero = $false
    )
    # Utility wrapper.
    # We encountered issues when trying to run non-powershell commands in a script, when it's
    # called from Jenkinsfile.
    # Everything that is printed to stderr in those external commands immediately causes an
    # exception to be thrown (as well as kills the command).
    # We don't want this, but we also want to know whether the command was successful or not.
    # This is what this wrapper aims to do.
    # 
    # This wrapper will throw only if the whole command failed. It will suppress any exceptions
    # when the command is running.
    #
    # Also, **every** execution of any native command should use this wrapper,
    # because Jenkins misinterprets $LastExitCode variable.
    #
    # Note: The command has to return 0 exitcode to be considered successful.

    $Global:LastExitCode = $null

    $exitCode = Invoke-NativeCommandImpl -ScriptBlock $ScriptBlock -ErrorAction "Ignore"

    if ($AllowNonZero -eq $false -and $exitCode -ne 0) {
        throw "Command ``$block`` failed with exitcode: $LastExitCode"
    }

    $Global:LastExitCode = $null

    write-host "MC1"
    write-host $Error
    write-host $Global:Error
    $Error.Clear()
    write-host "MC2"
    write-host $Error
    write-host $Global:Error
    $Global:Error.Clear()
    write-host "MC3"
    write-host $Error
    write-host $Global:Error
}
