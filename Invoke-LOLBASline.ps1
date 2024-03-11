<#
.SYNOPSIS
LOLBASline - A PowerShell tool for checking the presence and execution status of Living Off The Land Binaries and Scripts (LOLBAS).

.DESCRIPTION
LOLBASline checks for the existence of specified binaries and attempts to execute commands from the LOLBAS project definitions. It provides insights into which LOLBAS items are present and executable on a Windows system. Use this tool in controlled environments to assess system exposure to threats that use LOLBAS.

.AUTHOR
Name: Jose E Hernandez
Organization: MagicSword
Email: jose@magicsword.io

.NOTES
Version:        1
Last Updated:   03/11/2024
License:        Apache 2.0
GitHub:         https://github.com/magicsword-io/LOLBASline

.LINK
LOLBAS Project - https://github.com/LOLBAS-Project/LOLBAS
#>

param (
    [string]$Path = $null,
    [string]$Output = "results.csv",
    [switch]$Verbose
)

# Import required module
Import-Module powershell-yaml -ErrorAction Stop

function Clone-LOLBASRepo {
    param (
        [string]$Destination
    )
    
    if (-not (Test-Path $Destination)) {
        $RepoURL = "https://github.com/LOLBAS-Project/LOLBAS.git"
        Write-Host "Cloning LOLBAS project to $Destination..."
        git clone $RepoURL $Destination
    } else {
        Write-Host "$Destination already exists. Using existing repository."
    }
    return "$Destination/yml/OSBinaries"
}

function Load-YAMLFiles {
    param (
        [string]$DirectoryPath
    )

    $YamlFiles = Get-ChildItem -Path $DirectoryPath -Filter *.yml -Recurse
    $YamlObjects = @()

    foreach ($File in $YamlFiles) {
        $YamlContent = Get-Content $File.FullName -Raw
        $YamlObject = ConvertFrom-Yaml $YamlContent
        $YamlObjects += $YamlObject
    }

    return $YamlObjects
}

function Check-And-Execute-Binaries {
    param (
        [System.Collections.ArrayList]$YamlData,
        [switch]$Verbose
    )

    $Results = @()

    foreach ($Data in $YamlData) {
        if ($Data.Commands) {
            foreach ($CommandInfo in $Data.Commands) {
                $ExecutableCommand = $CommandInfo.Command
                try {
                    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $ExecutableCommand" -PassThru -WindowStyle Hidden
                    Start-Sleep -Seconds 2 # Give the command a moment to execute; adjust as needed
                    if ($process.HasExited -eq $false) {
                        $process.Kill()
                        $executionResult = "Executed"
                    } else {
                        $executionResult = "Failed"
                    }
                } catch {
                    $executionResult = "Error"
                }

                $Result = [PSCustomObject]@{
                    Name            = $Data.Name
                    Command         = $ExecutableCommand
                    ExecutionResult = $executionResult
                    Description     = $CommandInfo.Description
                    Usecase         = $CommandInfo.Usecase
                    Category        = $CommandInfo.Category
                }

                $Results += $Result

                if ($Verbose) {
                    $color = switch ($executionResult) {
                        "Executed" { "Green" }
                        "Failed"   { "Red" }
                        Default    { "Yellow" }
                    }
                    Write-Host "$($Data.Name): Command execution result = $($executionResult)" -ForegroundColor $color
                }
            }
        }
    }

    return $Results
}

if (-not $Path) {
    $Path = Clone-LOLBASRepo -Destination "lolbas_repo"
}

$YamlData = Load-YAMLFiles -DirectoryPath $Path
$Results = Check-And-Execute-Binaries -YamlData $YamlData -Verbose:$Verbose
$Results | Export-Csv -Path $Output -NoTypeInformation
Write-Host "Results written to $Output"
