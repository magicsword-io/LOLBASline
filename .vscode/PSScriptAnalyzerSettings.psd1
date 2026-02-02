@{
    # Only report on rules that are enabled
    IncludeDefaultRules = $true
    
    # Customize rules
    Rules = @{
        PSProvideCommentHelp = @{
            Enable = $true
            ExportOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'begin'
        }
        
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $false
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false
            CheckCase = $false
            CheckForStatement = $true
        }
        
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        
        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }
        
        PSAvoidUsingPositionalParameters = @{
            Enable = $false
        }
        
        PSAvoidGlobalVars = @{
            Enable = $true
        }
        
        PSAvoidNullOrEmptyHelpMessageAttribute = @{
            Enable = $true
        }
        
        PSAvoidUsingWriteHost = @{
            Enable = $false
        }
        
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }
        
        PSAvoidTrailingWhitespace = @{
            Enable = $true
        }
        
        PSShouldProcess = @{
            Enable = $false
        }
    }
}
