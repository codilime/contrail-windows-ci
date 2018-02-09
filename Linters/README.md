# contrail-windows-ci

# Linters

To run all available linters, execute the following command in this directory:

```
Invoke-AllLinters -RootDir .. -ConfigDir $pwd
```

## Powershell Script Analyzer (PSSCriptAnalyzer)

To run using our settings:

```
Invoke-ScriptAnalyzer . -Recurse -Settings C:\Full\Path\To\contrail-windows-ci\linters\PSScriptAnalyzerSettings.psd1
```
