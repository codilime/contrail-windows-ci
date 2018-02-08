# Write-Log

## Problem statement

Currently, `Write-Host` Powershell cmdlet is used all over test code.
This is done because previously used `Write-Output` messes with return values of 
nested functions.

However, the side effect of using `Write-Host` is that we have no control over
where it prints. It always prints to console - but it interferes with nice
formating of e.g. Pester.

Also, default rules of PSScriptAnalyzer recommend against using `Write-Host`
(https://github.com/PowerShell/PSScriptAnalyzer/blob/3dc995d7a9eaf259077c469ad8468aefb8eed133/RuleDocumentation/AvoidUsingWriteHost.md)

Recommendation is to use `Write-Output` or `Write-Verbose`.

`Write-Output` is problematic, for the reasons stated above.

`Write-Verbose` is nice, but it's hard to redirect its output to e.g. a file.

## Proposal

Implement a `Write-Log` function and replace every instance of `Write-Host` with it.

## Requirements

* By default, prints everything to a `log-detailed.txt` file.
* Prepends the message with location (file/line/class) of where `Write-Log` was called from.
* Can change the global filepath to the logfile.
* Ability to specify verbosity levels: `Error`, `Warn`, `Info`, `Debug`. This just prepends the message with a tag, so that it's easier to grep.
* Default verbosity level is `Debug`.
* `log-detailed.txt` is rsync'ed to the log server in Jenkinsfile amongside other logs.

Example fragment of `log-detailed.txt`:

```
[Error] [BuildFunctions:294]         Failed (exit code: 1).
...
[Info] [VTestScenariosTest:8] ===> Running vtest scenarios
[Info] [VTestScenariosTest:24] ===> Success!
...

