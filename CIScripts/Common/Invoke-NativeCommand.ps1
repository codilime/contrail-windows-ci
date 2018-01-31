function Invoke-NativeCommand {
    Param (
        [Parameter(Mandatory = $true)] [String] $Command,
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

    $Ret = "" | Select-Object -Property ExitCode, Output
    $Ret.Output = cmd.exe /c "$Command 2>&1"

    if ($AllowNonZero -eq $false -and $LastExitCode -ne 0) {
        throw "Command ``$block`` failed with exitcode: $LastExitCode"
    }

    $Ret.ExitCode = $Global:LastExitCode
    $Global:LastExitCode = $null

    return $Ret
}
