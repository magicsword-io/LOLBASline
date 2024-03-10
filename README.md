# LOLBASline

LOLBASline is a PowerShell tool designed to help security professionals and system administrators check the presence and status of Living Off The Land Binaries and Scripts (LOLBAS) on Windows systems. It automates the process of verifying these binaries against a predefined list from the LOLBAS project, streamlining the assessment of a system's exposure to these potentially risky binaries.

## Features

- **Automatic LOLBAS Repository Cloning:** If no local path is provided, LOLBASline will clone the latest LOLBAS project repository to retrieve the YAML files that contain the binaries information.
- **Verbose Output Mode:** For detailed insights during the checking process, including the paths checked and the outcome.
- **CSV Report Generation:** Outputs a comprehensive CSV report detailing the binaries checked, their presence, and additional metadata as specified in the LOLBAS YAML definitions.

## Prerequisites

Before installing and running LOLBASline, ensure that you have PowerShell 5.1 or later installed on your Windows system. Additionally, LOLBASline requires the `powershell-yaml` module for YAML file processing.

## Installation

To install LOLBASline, run the following command in your PowerShell session:

```powershell
Install-Module -Name LOLBASline
```

This command will automatically download and install LOLBASline and its dependencies from the PowerShell Gallery.

## Usage

To use LOLBASline, you can run it directly from your PowerShell session. Here are some common usage scenarios:

- **Default Usage (Auto-clone and Check):**

  ```powershell
  Invoke-LOLBASline
  ```

- **Specifying a Path to LOLBAS YAML Files:**

  ```powershell
  Invoke-LOLBASline -Path "path\to\your\LOLBAS\yml\files"
  ```

- **Verbose Mode and Custom Output File:**

  ```powershell
  Invoke-LOLBASline -Verbose -Output "path\to\your\output.csv"
  ```

Replace `"path\to\your\LOLBAS\yml\files"` and `"path\to\your\output.csv"` with the actual paths on your system.

## Contributing

Contributions to LOLBASline are welcome! Whether it's feature suggestions, bug reports, or pull requests, all forms of contributions help make LOLBASline better for everyone. Please ensure you follow our contribution guidelines outlined in `CONTRIBUTING.md`.

## License

LOLBASline is released under the MIT License. See the `LICENSE` file for more details.

## Acknowledgements

- Thanks to the [LOLBAS Project](https://github.com/LOLBAS-Project/LOLBAS) for providing the comprehensive list of Living Off The Land Binaries and Scripts.
- This tool was inspired by the need for a streamlined, PowerShell-based solution for assessing LOLBAS exposure on Windows systems.
