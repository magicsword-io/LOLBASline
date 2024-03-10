param (
    [string]$Path = $null,
    [string]$Output = "results.csv",
    [switch]$Verbose
)

function Clone-LOLBASRepo {
    $RepoURL = "https://github.com/LOLBAS-Project/LOLBAS.git"
    $Destination = "lolbas_repo"
    Write-Host "Cloning LOLBAS project to $Destination..."
    git clone $RepoURL $Destination
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
        foreach ($Path in $Data.Full_Path) {
            $ExecutablePath = $Path.Path
            $Result = [PSCustomObject]@{
                Name       = $Data.Name
                Path       = $ExecutablePath
                Loaded     = "No"
                Command    = ""
                Usecase    = ""
                Category   = ""
            }

            if (Test-Path $ExecutablePath) {
                $Result.Loaded = "Yes"
                if ($Data.Commands) {
                    $CommandInfo = $Data.Commands[0]
                    $Result.Command = $CommandInfo.Command
                    $Result.Usecase = $CommandInfo.Usecase
                    $Result.Category = $CommandInfo.Category
                }
            }

            $Results += $Result

            if ($Verbose) {
                Write-Host "Checked $ExecutablePath: Loaded = $($Result.Loaded)"
            }
        }
    }

    return $Results
}

if (-not $Path) {
    $Path = Clone-LOLBASRepo
}

$YamlData = Load-YAMLFiles -DirectoryPath $Path
$Results = Check-Binaries -YamlData $YamlData -Verbose:$Verbose
$Results | Export-Csv -Path $Output -NoTypeInformation
Write-Host "Results written to $Output"
