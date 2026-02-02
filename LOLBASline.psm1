<#
.SYNOPSIS
LOLBASline - A PowerShell tool for checking the presence and execution status of Living Off The Land Binaries and Scripts (LOLBAS).

.DESCRIPTION
LOLBASline checks for the existence of specified binaries and attempts to execute commands from the LOLBAS project definitions. It provides insights into which LOLBAS items are present and executable on a Windows system. Use this tool in controlled environments to assess system exposure to threats that use LOLBAS.

.PARAMETER Path
Specifies the path to an existing LOLBAS repository YAML directory (yml/OSBinaries). If not provided, the module will use the JSON API (no dependencies required).

.PARAMETER Output
Specifies the output file path for the CSV results. Default is "results.csv".

.PARAMETER Verbose
Enables verbose output showing detailed progress information.

.PARAMETER Help
Displays help information about the command usage.

.EXAMPLE
Invoke-LOLBASline -Verbose
Runs LOLBASline with verbose output, automatically fetching LOLBAS data from JSON API (no dependencies required).

.EXAMPLE
Invoke-LOLBASline -Path "C:\LOLBAS\yml\OSBinaries" -Output "scan_results.csv"
Uses an existing LOLBAS repository at the specified path and outputs results to a custom file.

.AUTHOR
Name: Jose E Hernandez
Organization: MagicSword
Email: jose@magicsword.io

.NOTES
Version:        1.2.0
Last Updated:   02/02/2026
License:        Apache 2.0
GitHub:         https://github.com/magicsword-io/LOLBASline
PowerShell:     Compatible with PowerShell 5.1+ and PowerShell Core 7.0+
Dependencies:   None! Uses JSON API - no git or powershell-yaml required.

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
        Write-Host "                  If not provided, the module will use the JSON API (no dependencies)." -ForegroundColor Gray
        Write-Host "  -Output [string]: Specify the output file for results. Default is 'results.csv'." -ForegroundColor Gray
        Write-Host "  -Verbose: Enable verbose output." -ForegroundColor Gray
        Write-Host "  -Help: Display this help message." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  Invoke-LOLBASline -Verbose" -ForegroundColor Yellow
        Write-Host "  Invoke-LOLBASline -Path 'C:\LOLBAS\yml\OSBinaries' -Output 'scan.csv'" -ForegroundColor Yellow
        return
    }

    function Download-LOLBASRepo {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$Destination
        )

        if (-not (Test-Path $Destination)) {
            $ZipURL = "https://github.com/LOLBAS-Project/LOLBAS/archive/refs/heads/master.zip"
            $ZipPath = Join-Path (Get-Location) "LOLBAS.zip"
            $ExtractPath = Join-Path (Get-Location) "LOLBAS"
            
            Write-Host "Downloading LOLBAS repository as ZIP..." -ForegroundColor Cyan
            try {
                # Download the ZIP file
                Invoke-WebRequest -Uri $ZipURL -OutFile $ZipPath -ErrorAction Stop
                Write-Host "Extracting ZIP archive..." -ForegroundColor Cyan
                
                # Extract the ZIP file
                Expand-Archive -LiteralPath $ZipPath -DestinationPath (Get-Location) -Force -ErrorAction Stop
                
                # Move extracted folder to destination
                $ExtractedFolder = Join-Path (Get-Location) "LOLBAS-master"
                if (Test-Path $ExtractedFolder) {
                    Move-Item -Path $ExtractedFolder -Destination $Destination -Force -ErrorAction Stop
                }
                
                # Clean up ZIP file
                Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue
                
                Write-Host "Successfully downloaded and extracted LOLBAS repository." -ForegroundColor Green
            }
            catch {
                Write-Error "Error downloading repository: $_"
                # Clean up on error
                if (Test-Path $ZipPath) { Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue }
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

    function Load-LOLBASJSON {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $false)]
            [string]$JsonURL = "https://lolbas-project.github.io/api/lolbas.json"
        )

        Write-Host "Fetching LOLBAS data from JSON API..." -ForegroundColor Cyan
        try {
            $response = Invoke-WebRequest -Uri $JsonURL -UseBasicParsing -ErrorAction Stop
            $jsonContent = $response.Content
            $LOLBASData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            if (-not $LOLBASData -or $LOLBASData.Count -eq 0) {
                Write-Warning "No data received from JSON API"
                return @()
            }

            # Filter to only OSBinaries (items with Full_Path)
            $OSBinaries = [System.Collections.ArrayList]::new()
            foreach ($Item in $LOLBASData) {
                if ($Item.Full_Path -and $Item.Full_Path.Count -gt 0) {
                    [void]$OSBinaries.Add($Item)
                }
            }

            Write-Host "Loaded $($OSBinaries.Count) LOLBAS binaries from JSON API" -ForegroundColor Green
            return $OSBinaries
        }
        catch {
            Write-Error "Failed to load LOLBAS data from JSON API: $_"
            return @()
        }
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
    # Always use JSON API - no git or powershell-yaml dependencies required!
    if ($Path) {
        Write-Warning "The -Path parameter is deprecated. Using JSON API instead (no dependencies required)."
        Write-Host "Fetching LOLBAS data from JSON API..." -ForegroundColor Cyan
    }
    
    $LOLBASData = Load-LOLBASJSON

    if (-not $LOLBASData -or $LOLBASData.Count -eq 0) {
        Write-Error "No LOLBAS data loaded. Cannot proceed."
        return
    }

    # Check binaries
    $Results = Check-Binaries -YamlData $LOLBASData -Verbose:$Verbose
    
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
