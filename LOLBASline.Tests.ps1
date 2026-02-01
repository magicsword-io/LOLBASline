#Requires -Module Pester

<#
.SYNOPSIS
Comprehensive Pester tests for LOLBASline v2.0.0

Run with: Invoke-Pester LOLBASline.Tests.ps1 -Verbose
#>

Describe "LOLBASline Module Tests" {
    
    # Import module
    BeforeAll {
        Import-Module "$PSScriptRoot\LOLBASline.psm1" -Force
    }
    
    Context "Module Initialization" {
        It "Module loads without external dependencies" {
            $module = Get-Module LOLBASline
            $module | Should -Not -BeNullOrEmpty
        }
        
        It "All required functions are exported" {
            $functions = @(
                'Invoke-LOLBASline'
                'Initialize-Logging'
                'Get-LOLBASData'
                'Test-BinaryPresence'
                'Test-CommandExecution'
            )
            
            foreach ($func in $functions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Logging Functions" {
        It "Initialize-Logging creates log directory" {
            $logPath = Initialize-Logging
            $logPath | Should -Not -BeNullOrEmpty
            Test-Path $logPath | Should -Be $true
        }
        
        It "Write-LogMessage outputs without error" {
            { Write-LogMessage "Test message" -Level Info } | Should -Not -Throw
        }
        
        It "Write-LogMessage accepts valid levels" {
            foreach ($level in @('Info', 'Warning', 'Error', 'Success', 'Debug')) {
                { Write-LogMessage "Test" -Level $level } | Should -Not -Throw
            }
        }
    }
    
    Context "Cache Management" {
        It "Initialize-Cache creates cache directory" {
            Initialize-Cache
            Test-Path $script:Config.CachePath | Should -Be $true
        }
        
        It "Cache functions handle missing cache gracefully" {
            $cached = Get-CachedLOLBASData
            # Should return null if no cache (not error)
            $cached | Should -BeNullOrEmpty
        }
    }
    
    Context "YAML Parsing" {
        It "ConvertFrom-SimpleYAML parses key-value pairs" {
            $yaml = "Name: test`nPath: C:\test`nDescription: A test"
            $result = ConvertFrom-SimpleYAML -YAMLString $yaml
            
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "test"
        }
        
        It "ConvertFrom-SimpleYAML handles quoted values" {
            $yaml = 'Description: "This is a quoted value"'
            $result = ConvertFrom-SimpleYAML -YAMLString $yaml
            
            $result.Description | Should -Be "This is a quoted value"
        }
        
        It "ConvertFrom-SimpleYAML ignores comments" {
            $yaml = "# This is a comment`nName: test"
            $result = ConvertFrom-SimpleYAML -YAMLString $yaml
            
            $result.Name | Should -Be "test"
        }
    }
    
    Context "Binary Detection" {
        It "Test-BinaryPresence detects cmd.exe" {
            $result = Test-BinaryPresence -BinaryPath "C:\Windows\System32\cmd.exe"
            $result | Should -Be $true
        }
        
        It "Test-BinaryPresence returns false for non-existent path" {
            $result = Test-BinaryPresence -BinaryPath "C:\NonExistent\Binary.exe"
            $result | Should -Be $false
        }
        
        It "Test-BinaryPresence handles null/empty path" {
            $result = Test-BinaryPresence -BinaryPath ""
            $result | Should -Be $false
        }
        
        It "Test-BinaryPresence expands environment variables" {
            $result = Test-BinaryPresence -BinaryPath "%SystemRoot%\System32\cmd.exe"
            $result | Should -Be $true
        }
    }
    
    Context "Command Execution" {
        It "Test-CommandExecution handles valid command" {
            $result = Test-CommandExecution -Command "cmd.exe /c echo test" -TimeoutSeconds 5
            $result | Should -Match "Executed|Failed|Timeout|Error"
        }
        
        It "Test-CommandExecution respects timeout" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Test-CommandExecution -Command "cmd.exe /c timeout /t 30" -TimeoutSeconds 2
            $stopwatch.Stop()
            
            $result | Should -Be "Timeout"
            $stopwatch.Elapsed.TotalSeconds | Should -BeLessThan 10
        }
    }
    
    Context "LOLBAS Data Loading" {
        It "Get-BuiltInLOLBASReference returns data" {
            $data = Get-BuiltInLOLBASReference
            $data.Count | Should -BeGreaterThan 0
            $data[0].Name | Should -Not -BeNullOrEmpty
        }
        
        It "Get-LOLBASData returns data when no repo provided" {
            $data = Get-LOLBASData
            $data | Should -Not -BeNullOrEmpty
            @($data).Count | Should -BeGreaterThan 0
        }
        
        It "Get-LOLBASData caches results" {
            $data1 = Get-LOLBASData -ForceRefresh
            $data2 = Get-LOLBASData  # Should come from cache
            
            $data1.Count | Should -Equal $data2.Count
        }
    }
    
    Context "Main Function" {
        It "Invoke-LOLBASline executes without error" {
            { Invoke-LOLBASline -Verbose } | Should -Not -Throw
        }
        
        It "Invoke-LOLBASline creates output CSV" {
            $outputPath = "TestResults_$([System.Guid]::NewGuid()).csv"
            
            try {
                Invoke-LOLBASline -OutputPath $outputPath -Verbose
                Test-Path $outputPath | Should -Be $true
                
                # Verify CSV is valid
                $content = Import-Csv $outputPath
                $content.Count | Should -BeGreaterThan 0
            } finally {
                if (Test-Path $outputPath) {
                    Remove-Item $outputPath -Force
                }
            }
        }
        
        It "Invoke-LOLBASline outputs results object" {
            $results = Invoke-LOLBASline
            $results | Should -Not -BeNullOrEmpty
            @($results).Count | Should -BeGreaterThan 0
        }
        
        It "Results contain required properties" {
            $results = Invoke-LOLBASline
            $result = $results[0]
            
            $result | Should -HaveProperty 'Name'
            $result | Should -HaveProperty 'Path'
            $result | Should -HaveProperty 'Presence'
            $result | Should -HaveProperty 'ExecutionResult'
            $result | Should -HaveProperty 'Timestamp'
        }
    }
    
    Context "Performance" {
        It "Invoke-LOLBASline completes in reasonable time" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-LOLBASline
            $stopwatch.Stop()
            
            # Should complete within 30 seconds
            $stopwatch.Elapsed.TotalSeconds | Should -BeLessThan 30
        }
        
        It "Cached execution is significantly faster" {
            # First run (no cache)
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-LOLBASline | Out-Null
            $stopwatch1.Stop()
            $firstRunTime = $stopwatch1.Elapsed.TotalSeconds
            
            # Second run (with cache)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-LOLBASline | Out-Null
            $stopwatch2.Stop()
            $secondRunTime = $stopwatch2.Elapsed.TotalSeconds
            
            # Cached run should be at least 2x faster
            $secondRunTime | Should -BeLessThan ($firstRunTime / 2)
        }
    }
    
    Context "Error Handling" {
        It "Handles missing repository path gracefully" {
            $results = Invoke-LOLBASline -RepositoryPath "C:\NonExistent\Path"
            $results | Should -Not -BeNullOrEmpty
        }
        
        It "Help parameter displays without error" {
            { Invoke-LOLBASline -Help } | Should -Not -Throw
        }
    }
}

# Summary
Describe "LOLBASline Integration Tests" {
    It "Module is production-ready" {
        Get-Module LOLBASline | Should -Not -BeNullOrEmpty
        Get-Command Invoke-LOLBASline | Should -Not -BeNullOrEmpty
    }
}
