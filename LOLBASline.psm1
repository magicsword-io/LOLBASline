<#
.SYNOPSIS
LOLBASline - A PowerShell tool for checking the presence and execution status of Living Off The Land Binaries and Scripts (LOLBAS).

.DESCRIPTION
LOLBASline checks for the existence of specified binaries and attempts to execute commands from the LOLBAS project definitions. It provides insights into which LOLBAS items are present and executable on a Windows system. Use this tool in controlled environments to assess system exposure to threats that use LOLBAS.

.PARAMETER Path
Specifies the path to an existing LOLBAS repository YAML directory (yml/OSBinaries). If not provided, the module will clone the repository automatically.

.PARAMETER Output
Specifies the output file path for the CSV results. Default is "results.csv".

.PARAMETER Verbose
Enables verbose output showing detailed progress information.

.PARAMETER Help
Displays help information about the command usage.

.EXAMPLE
Invoke-LOLBASline -Verbose
Runs LOLBASline with verbose output, automatically cloning the LOLBAS repository if needed.

.EXAMPLE
Invoke-LOLBASline -Path "C:\LOLBAS\yml\OSBinaries" -Output "scan_results.csv"
Uses an existing LOLBAS repository at the specified path and outputs results to a custom file.

.AUTHOR
Name: Jose E Hernandez
Organization: MagicSword
Email: jose@magicsword.io

.NOTES
Version:        1.1.0
Last Updated:   02/02/2026
License:        Apache 2.0
GitHub:         https://github.com/magicsword-io/LOLBASline
PowerShell:     Compatible with PowerShell 5.1+ and PowerShell Core 7.0+

.LINK
LOLBAS Project - https://github.com/LOLBAS-Project/LOLBAS
#>

function Invoke-LOLBASline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$Output = "results.csv",
        
        [Parameter(Mandatory = $false)]
        [switch]$Verbose,
        
        [Parameter(Mandatory = $false)]
        [switch]$Help
    )

    # Check if the Help flag is used and display help information
    if ($Help) {
        Write-Host "Usage of Invoke-LOLBASline:" -ForegroundColor Cyan
        Write-Host "  -Path [string]: Specify the path to an existing LOLBAS YAML directory (yml/OSBinaries)." -ForegroundColor Gray
        Write-Host "                  If not provided, the module will clone the repository automatically." -ForegroundColor Gray
        Write-Host "  -Output [string]: Specify the output file for results. Default is 'results.csv'." -ForegroundColor Gray
        Write-Host "  -Verbose: Enable verbose output." -ForegroundColor Gray
        Write-Host "  -Help: Display this help message." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  Invoke-LOLBASline -Verbose" -ForegroundColor Yellow
        Write-Host "  Invoke-LOLBASline -Path 'C:\LOLBAS\yml\OSBinaries' -Output 'scan.csv'" -ForegroundColor Yellow
        return
    }

    # Import powershell-yaml module with better error handling
    try {
        Import-Module powershell-yaml -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import powershell-yaml module. Please install it using: Install-Module -Name powershell-yaml" -ErrorAction Stop
        return
    }

    function Clone-LOLBASRepo {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$Destination
        )

        # Check if git is available
        $gitInstalled = Get-Command "git" -ErrorAction SilentlyContinue
        if (-not $gitInstalled) {
            Write-Warning "Git is not installed. Please install Git to use this module."
            Write-Host "You can download Git from https://git-scm.com/downloads" -ForegroundColor Yellow
            return $null
        }

        if (-not (Test-Path $Destination)) {
            $RepoURL = "https://github.com/LOLBAS-Project/LOLBAS.git"
            Write-Host "Cloning LOLBAS project to $Destination..." -ForegroundColor Cyan
            try {
                git clone $RepoURL $Destination 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Failed to clone LOLBAS repository. Git returned exit code $LASTEXITCODE."
                    return $null
                }
            }
            catch {
                Write-Error "Error cloning repository: $_"
                return $null
            }
        }
        else {
            Write-Host "$Destination already exists. Using existing repository." -ForegroundColor Green
        }
        
        $yamlPath = Join-Path $Destination "yml" "OSBinaries"
        if (-not (Test-Path $yamlPath)) {
            Write-Warning "Expected YAML directory not found at: $yamlPath"
            return $null
        }
        
        return $yamlPath
    }

    function Load-YAMLFiles {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$DirectoryPath
        )

        if (-not (Test-Path $DirectoryPath)) {
            Write-Error "Directory path does not exist: $DirectoryPath"
            return @()
        }

        $YamlFiles = Get-ChildItem -Path $DirectoryPath -Filter *.yml -Recurse -ErrorAction SilentlyContinue
        if (-not $YamlFiles) {
            Write-Warning "No YAML files found in directory: $DirectoryPath"
            return @()
        }

        $YamlObjects = [System.Collections.ArrayList]::new()
        $errorCount = 0

        foreach ($File in $YamlFiles) {
            try {
                $YamlContent = Get-Content $File.FullName -Raw -ErrorAction Stop
                if ([string]::IsNullOrWhiteSpace($YamlContent)) {
                    if ($Verbose) {
                        Write-Warning "Skipping empty YAML file: $($File.FullName)"
                    }
                    continue
                }
                
                $YamlObject = ConvertFrom-Yaml $YamlContent -ErrorAction Stop
                if ($YamlObject) {
                    [void]$YamlObjects.Add($YamlObject)
                }
            }
            catch {
                $errorCount++
                if ($Verbose) {
                    Write-Warning "Failed to parse YAML file '$($File.FullName)': $_"
                }
            }
        }

        if ($errorCount -gt 0) {
            Write-Warning "Failed to parse $errorCount YAML file(s). Continuing with successfully parsed files."
        }

        Write-Host "Loaded $($YamlObjects.Count) YAML files from $DirectoryPath" -ForegroundColor Green
        return $YamlObjects
    }

    function Check-Binaries {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [System.Collections.ArrayList]$YamlData,
            
            [Parameter(Mandatory = $false)]
            [switch]$Verbose
        )

        $Results = [System.Collections.ArrayList]::new()
        $totalItems = 0
        $processedItems = 0

        # Count total items for progress tracking
        foreach ($Data in $YamlData) {
            if ($Data.Commands) {
                $totalItems += $Data.Commands.Count
            }
        }

        # Detect platform for execution method
        $isWindows = $IsWindows
        if (-not $isWindows -and $PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell 5.1 doesn't have $IsWindows, use alternative method
            $isWindows = ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
        }

        foreach ($Data in $YamlData) {
            if (-not $Data.Commands) {
                continue
            }

            # Validate Full_Path exists and has elements
            if (-not $Data.Full_Path -or $Data.Full_Path.Count -eq 0) {
                if ($Verbose) {
                    Write-Warning "Skipping '$($Data.Name)': No Full_Path defined"
                }
                continue
            }

            # Get first valid path
            $ExecutablePath = $null
            foreach ($pathEntry in $Data.Full_Path) {
                if ($pathEntry -and $pathEntry.Path) {
                    $ExecutablePath = $pathEntry.Path
                    break
                }
            }

            if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
                if ($Verbose) {
                    Write-Warning "Skipping '$($Data.Name)': No valid path found in Full_Path"
                }
                continue
            }

            foreach ($CommandInfo in $Data.Commands) {
                $processedItems++
                
                if ($Verbose -and $totalItems -gt 0) {
                    $percentComplete = [math]::Round(($processedItems / $totalItems) * 100, 1)
                    Write-Progress -Activity "Checking LOLBAS binaries" -Status "Processing $($Data.Name)" -PercentComplete $percentComplete
                }

                # Check binary presence
                $Presence = "No"
                try {
                    if (Test-Path $ExecutablePath -ErrorAction Stop) {
                        $Presence = "Yes"
                    }
                }
                catch {
                    $Presence = "Error in Path"
                    if ($Verbose) {
                        Write-Host "Error testing path '$ExecutablePath': $_" -ForegroundColor Red
                    }
                }

                $ExecutableCommand = $CommandInfo.Command
                $executionResult = "Not Executed"

                # Only attempt execution on Windows systems and if binary is present
                if ($Presence -eq "Yes" -and $isWindows) {
                    try {
                        # Use cmd.exe on Windows, but with better error handling
                        $processArgs = @{
                            FilePath = "cmd.exe"
                            ArgumentList = "/c $ExecutableCommand"
                            PassThru = $true
                            WindowStyle = "Hidden"
                            ErrorAction = "Stop"
                        }
                        
                        $process = Start-Process @processArgs
                        Start-Sleep -Seconds 2
                        
                        if (-not $process.HasExited) {
                            $process.Kill()
                            $executionResult = "Executed"
                        }
                        else {
                            $executionResult = "Failed"
                        }
                    }
                    catch {
                        $executionResult = "Error"
                        if ($Verbose) {
                            Write-Warning "Execution test failed for '$ExecutablePath': $_"
                        }
                    }
                }
                elseif ($Presence -eq "Yes" -and -not $isWindows) {
                    $executionResult = "Skipped (Non-Windows)"
                }

                $Result = [PSCustomObject]@{
                    Name            = $Data.Name
                    Path            = $ExecutablePath
                    Presence        = $Presence
                    ExecutionResult = $executionResult
                    Command         = $ExecutableCommand
                    Description     = if ($CommandInfo.Description) { $CommandInfo.Description } else { "" }
                    Usecase         = if ($CommandInfo.Usecase) { $CommandInfo.Usecase } else { "" }
                    Category        = if ($CommandInfo.Category) { $CommandInfo.Category } else { "" }
                }

                [void]$Results.Add($Result)

                if ($Verbose) {
                    $color = switch ($executionResult) {
                        "Executed" { "Green" }
                        "Failed"   { "Red" }
                        "Error"    { "Red" }
                        Default    { "Yellow" }
                    }
                    Write-Host "$($Data.Name): Presence = $($Presence), Execution result = $($executionResult)" -ForegroundColor $color
                }
            }
        }

        if ($Verbose) {
            Write-Progress -Activity "Checking LOLBAS binaries" -Completed
        }

        return $Results
    }

    # Main execution logic
    $yamlDirectoryPath = $null

    # Use provided Path if specified, otherwise clone repository
    if ($Path) {
        if (Test-Path $Path) {
            $yamlDirectoryPath = $Path
            Write-Host "Using provided path: $Path" -ForegroundColor Cyan
        }
        else {
            Write-Error "The specified path does not exist: $Path"
            return
        }
    }
    else {
        $defaultRepoPath = Join-Path (Get-Location) "lolbas_repo"
        $yamlDirectoryPath = Clone-LOLBASRepo -Destination $defaultRepoPath
        if (-not $yamlDirectoryPath) {
            Write-Error "Unable to continue without a valid LOLBAS repository path. Exiting."
            return
        }
    }

    # Load YAML files
    $YamlData = Load-YAMLFiles -DirectoryPath $yamlDirectoryPath
    if ($YamlData.Count -eq 0) {
        Write-Error "No YAML data loaded. Cannot proceed."
        return
    }

    # Check binaries
    $Results = Check-Binaries -YamlData $YamlData -Verbose:$Verbose
    
    if ($Results.Count -eq 0) {
        Write-Warning "No results generated. Check your YAML files and paths."
        return
    }

    # Export results
    try {
        $Results | Export-Csv -Path $Output -NoTypeInformation -ErrorAction Stop
        Write-Host "Results written to $Output ($($Results.Count) entries)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to write results to $Output : $_"
    }
}
