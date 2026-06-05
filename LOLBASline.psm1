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

function Invoke-LOLBASline {
    param (
        [string]$Path = $null,
        [string]$Output = "results.csv",
        [switch]$Verbose,
        [switch]$Help  # Add a help flag parameter
    )

    # Check if the Help flag is used and display help information
    if ($Help) {
        Write-Host "Usage of Invoke-LOLBASline:"
        Write-Host "  -Path [string]: Specify the path to clone the LOLBAS repository."
        Write-Host "  -Output [string]: Specify the output file for results. Default is 'results.csv'."
        Write-Host "  -Verbose: Enable verbose output."
        Write-Host "  -Help: Display this help message."
        return
    }

    Import-Module powershell-yaml -ErrorAction Stop

    function Clone-LOLBASRepo {
        param (
            [string]$Destination
        )

        if (-not (Test-Path $Destination)) {
            $gitInstalled = Get-Command "git" -ErrorAction SilentlyContinue
            if ($gitInstalled) {
                Write-Output "Git is installed. Proceeding with cloning the repository."
                $RepoURL = "https://github.com/LOLBAS-Project/LOLBAS.git"
                Write-Output "Cloning LOLBAS project to $Destination..."
                git clone --depth 1 $RepoURL $Destination
            }
            else {
                Write-Warning "Git is not installed. Proceeding to download the repository as a ZIP file."
                $zipFile = 'LOLBAS.zip'
                try {
                    Invoke-WebRequest -Uri 'https://github.com/LOLBAS-Project/LOLBAS/archive/refs/heads/master.zip' -OutFile $zipFile -ErrorAction Stop
                    Expand-Archive -Path $zipFile -DestinationPath . -ErrorAction Stop
                    Move-Item -Path 'LOLBAS-master' -Destination $Destination -ErrorAction Stop
                }
                catch {
                    Write-Error "Failed to download and extract LOLBAS repository. Error: $_"
                }
                finally {
                    if (Test-Path $zipFile) {
                        Remove-Item $zipFile -Force
                    }
                }
            }
        }
        else {
            Write-Output "$Destination already exists. Using existing repository."
        }

        $finalPath = "$Destination/yml/OSBinaries"
        if (Test-Path $finalPath) {
            return $finalPath
        }
        else {
            Write-Error "Failed to obtain LOLBAS repository files."
            return $null
        }
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

    function Check-Binaries {
        param (
            [System.Collections.ArrayList]$YamlData,
            [switch]$Verbose
        )

        $Results = @()

        $i = 0
        $total = $YamlData.Count

        foreach ($Data in $YamlData) {
            $i++
            $percent = [math]::Round(($i / $total) * 100)
            Write-Progress -Activity "Checking Binaries" -Status "Processing $($Data.Name) ($i of $total)" -PercentComplete $percent

            if ($Data.Commands) {
                foreach ($CommandInfo in $Data.Commands) {
                    $ExecutablePath = $Data.Full_Path[0].Path
                    try {
                        $Presence = Test-Path $ExecutablePath -ErrorAction Stop
                    }
                    catch {
                        $Presence = $null
                        if ($Verbose) {
                            Write-Host "Error testing path '$ExecutablePath': $_" -ForegroundColor Red
                        }
                    }
                    $ExecutableCommand = $CommandInfo.Command
                    $executionResult = "Not Executed"

                    if ($Presence) {
                        Write-Verbose "Attempting to execute command: $ExecutableCommand"
                        try {
                            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $ExecutableCommand" -PassThru -WindowStyle Hidden
                            if ($process.WaitForExit(2000)) {
                                $executionResult = if ($process.ExitCode -eq 0) { "Executed" } else { "Failed" }
                            } else {
                                $process.Kill()
                                $executionResult = "Executed"
                            }
                        }
                        catch {
                            $executionResult = "Error"
                        }
                    }

                    $Result = [PSCustomObject]@{
                        Name            = $Data.Name
                        Path            = $ExecutablePath
                        Presence        = $Presence
                        ExecutionResult = $executionResult
                        Command         = $ExecutableCommand
                        Description     = $CommandInfo.Description
                        Usecase         = $CommandInfo.Usecase
                        Category        = $CommandInfo.Category
                    }

                    $Results += $Result

                    if ($Verbose) {
                        $color = switch ($executionResult) {
                            "Executed" { "Green" }
                            "Failed" { "Red" }
                            Default { "Yellow" }
                        }
                        Write-Host "$($Data.Name): Presence = $($Presence), Execution result = $($executionResult)" -ForegroundColor $color
                    }
                }
            }
        }
        Write-Progress -Activity "Checking Binaries" -Completed

        return $Results
    }

    $Path = Clone-LOLBASRepo -Destination "lolbas_repo"
    if (-not $Path) {
        Write-Warning "Failed to obtain LOLBAS repository files. Unable to continue."
        return
    }

    $YamlData = Load-YAMLFiles -DirectoryPath $Path
    $Results = Check-Binaries -YamlData $YamlData -Verbose:$Verbose
    $Results | Export-Csv -Path $Output -NoTypeInformation
    Write-Output "Results written to $Output"
}