# Changelog

All notable changes to LOLBASline will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-02

### Fixed
- **Critical Bug**: Fixed `-Path` parameter being ignored - now properly uses provided path instead of always cloning
- **Crash Prevention**: Added null checks for `Full_Path` array access to prevent IndexOutOfRangeException
- **Error Handling**: Improved error handling for YAML parsing failures with graceful degradation
- **Git Clone**: Added error handling for git clone failures with proper exit code checking

### Added
- **Progress Indicators**: Added progress bar for verbose mode showing scan progress
- **Platform Detection**: Added cross-platform support detection (Windows vs non-Windows)
- **Better Error Messages**: Enhanced error messages with actionable information
- **Test Suite**: Created comprehensive Pester test suite foundation
- **Code Quality**: Added PSScriptAnalyzer configuration for consistent code style

### Changed
- **Performance**: Replaced inefficient array concatenation (`+=`) with `ArrayList` for better performance
- **PowerShell 7**: Improved PowerShell 7+ compatibility with platform detection
- **Execution Logic**: Enhanced execution testing with better error handling and non-Windows platform support
- **Module Manifest**: Updated to version 1.1.0 with detailed release notes
- **Code Style**: Improved code consistency with proper indentation and formatting

### Improved
- **YAML Loading**: Better handling of empty or invalid YAML files
- **Path Validation**: Enhanced path validation and error reporting
- **Verbose Output**: Improved verbose output with color coding and progress tracking
- **Documentation**: Enhanced function documentation with examples and parameter descriptions

## [1.0.2] - 2024-03-12

### Added
- Initial release
- Basic LOLBAS binary checking functionality
- CSV output support
- Verbose mode
- Help parameter
