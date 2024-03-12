# LOLBASline 🛠️

LOLBASline is a PowerShell tool designed to assess the presence and execution capabilities of Living Off The Land Binaries and Scripts (LOLBAS) on Windows systems. It provides insights into which LOLBAS items are present on the system and tests their ability to execute specific commands.

## Features 🌟

- **Automated LOLBAS Repository Cloning:** If no local path is provided, LOLBASline will clone the latest LOLBAS project repository to retrieve the YAML files containing binary information.
- **Presence Verification:** Checks if the LOLBAS binaries exist on the system.
- **Execution Capability Test:** Attempts to execute a representative command for each binary to verify execution capabilities.
- **Detailed Reporting:** Outputs a comprehensive CSV report detailing the binaries checked, their presence, ability to execute commands, and additional metadata from the LOLBAS YAML definitions.

## Prerequisites 📋

Before installing and running LOLBASline, ensure you have PowerShell 5.1 or later and the `powershell-yaml` module installed on your Windows system.

## Installation 💾

To install LOLBASline, run the following command in your PowerShell session:

```powershell
Install-Module -Name LOLBASline
```

This command will automatically download and install LOLBASline and its dependencies from the PowerShell Gallery.

## Usage 🚀

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

## Contributing 🤝

We welcome contributions! If you have suggestions for improvements or encounter any issues, please feel free to open a pull request or report an issue on GitHub.

## License 📄

LOLBASline is released under the Apache License 2.0. See the `LICENSE` file for more details.

## Acknowledgements 🙏

- Thanks to the [LOLBAS Project](https://github.com/LOLBAS-Project/LOLBAS) for providing the comprehensive list of Living Off The Land Binaries and Scripts.
- This tool was inspired by the need for a streamlined, PowerShell-based solution for assessing LOLBAS exposure on Windows systems.
