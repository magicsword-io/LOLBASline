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

		# Check if git is available
		$gitInstalled = Get-Command "git" -ErrorAction SilentlyContinue
		if (-not $gitInstalled) {
			Write-Warning "Git is not installed. Please install Git to use this module."
			Write-Host "You can download Git from https://git-scm.com/downloads"
			# Exit the script if Git is not installed
			return $null
		}

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

    function Check-Binaries {
        param (
            [System.Collections.ArrayList]$YamlData,
            [switch]$Verbose
        )

        $Results = @()

        foreach ($Data in $YamlData) {
            if ($Data.Commands) {
                foreach ($CommandInfo in $Data.Commands) {
                    $ExecutablePath = $Data.Full_Path[0].Path
                    try {
                        $Presence = if (Test-Path $ExecutablePath) { "Yes" } else { "No" }
                    } catch {
                        $Presence = "Error in Path"
                        if ($Verbose) {
                            Write-Host "Error testing path '$ExecutablePath': $_" -ForegroundColor Red
                        }
                    }
                    $ExecutableCommand = $CommandInfo.Command
                    $executionResult = "Not Executed"
                    
                    if ($Presence -eq "Yes") {
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
                            "Failed"   { "Red" }
                            Default    { "Yellow" }
                        }
                        Write-Host "$($Data.Name): Presence = $($Presence), Execution result = $($executionResult)" -ForegroundColor $color
                    }
                }
            }
        }

        return $Results
    }

	$Path = Clone-LOLBASRepo -Destination "lolbas_repo"
	if (-not $Path) {
		Write-Host "Unable to continue without Git. Exiting script."
		return
	}

    $YamlData = Load-YAMLFiles -DirectoryPath $Path
    $Results = Check-Binaries -YamlData $YamlData -Verbose:$Verbose
    $Results | Export-Csv -Path $Output -NoTypeInformation
    Write-Host "Results written to $Output"
}