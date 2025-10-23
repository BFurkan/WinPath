# Windows Path Length Analyzer (WinPathScan) v2.0

A PowerShell tool for analyzing and reporting file path lengths in Windows environments, specifically designed to help with cloud migration readiness and OneDrive sync compatibility.

## 🆕 What's New in v2.0
- **Simplified Interface**: Consolidated from 6+ confusing batch files to just 3 clear options
- **Fixed Critical Bug**: Corrected module installation (PSWriteHTML vs PSHTML)
- **Professional Naming**: No more "copy 9" versions - clean, professional filenames
- **Standardized Experience**: Consistent menus and error messages across all tools
- **Better Documentation**: Comprehensive help and troubleshooting built-in

## 🚀 Quick Start (v2.0 - Simplified!)

### For Non-Technical Users (Recommended):
1. **Download and extract** WinPathScan to a folder
2. **Double-click** `WinPathScan-Setup.bat` (one-time setup)
3. **Double-click** `WinPathScan-Quick.bat` for instant Documents scan
4. **View Results**: HTML report opens automatically in your browser

### For Technical Users:
1. **Clone and Setup**:
   ```powershell
   git clone https://github.com/aollivierre/WinPathScan.git
   cd WinPathScan
   Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser
   ```

2. **Run PowerShell directly**:
   ```powershell
   # For OneDrive compatibility (260 char limit)
   .\WinPathScan.ps1 -Path "C:\Users" -Limit 260 -ExportFormat "Both"
   ```

## 📁 The 3 Core Files (v2.0)

| File | Purpose | When to Use |
|------|---------|-------------|
| `WinPathScan-Setup.bat` | One-time setup & module installation | **Run this first** (once per computer) |
| `WinPathScan-Quick.bat` | Quick Documents folder scan | **Daily use** - fast and simple |
| `WinPathScan-Advanced.bat` | Full menu with all options | **Power users** - custom paths and options |

## Overview

WinPathScan helps IT administrators and users identify and resolve long file path issues that commonly cause problems with:
- OneDrive sync
- SharePoint Online migration
- Teams file sync
- Windows system limitations

The tool provides detailed reports of files and folders that exceed specified path length limits, helping prevent sync issues before they occur.

## Features

- 🔍 Recursive path length analysis
- 📊 HTML and CSV reporting options
- 🎨 Color-coded length severity indicators
- 📝 Path remediation suggestions
- 📂 NTFS permissions analysis (optional)
- 📈 Detailed statistics and summaries

## Prerequisites

- Windows OS (Windows 10, Windows 11, or Windows Server)
- PowerShell 5.1 or PowerShell 7.x (tested with PS 7.4.6)
- Administrator privileges (for certain paths)

## Installation

### Step 1: Clone the Repository
```powershell
git clone https://github.com/aollivierre/WinPathScan.git
cd WinPathScan
```

### Step 2: Verify PowerShell Version
```powershell
$PSVersionTable.PSVersion
```
**Required**: PowerShell 5.1 or PowerShell 7.x

### Step 3: Install Required Modules

#### Option A: Automatic Installation (Requires Admin + PowerShell 5.1)
```powershell
.\0-Install-RequiredModules.ps1
```

#### Option B: Manual Installation (Recommended)
```powershell
# Install NuGet Package Provider (if not already installed)
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install PSWriteHTML module for current user
Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser
```

### Step 4: Verify Installation
```powershell
# Check if PSWriteHTML is installed
Get-Module -ListAvailable PSWriteHTML
```

### Step 5: Run PowerShell as Administrator
1. Press `Windows + X`
2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
3. Click "Yes" when prompted by UAC
4. Navigate to the WinPathScan directory:
   ```powershell
   cd "C:\path\to\WinPathScan"
   ```

## Usage

### Quick Start Commands

#### For OneDrive Migration Planning (260 character limit):
```powershell
.\WinPathScan.ps1 -Path "C:\Users" -Limit 260 -ExportFormat "Both"
```

#### For Teams File Sync (400 character limit):
```powershell
.\WinPathScan.ps1 -Path "C:\Users" -Limit 400 -ExportFormat "Both"
```

#### For Specific Directory:
```powershell
.\WinPathScan.ps1 -Path "C:\Documents" -Limit 260 -ExportFormat "HTML"
```

### Basic Usage Examples

```powershell
# Basic analysis with default settings
.\WinPathScan.ps1 -Path "C:\Users" -Limit 260

# Full analysis with HTML and CSV reports
.\WinPathScan.ps1 -Path "C:\Users" -Limit 260 -ExportFormat "Both"

# Include NTFS permissions analysis
.\WinPathScan.ps1 -Path "C:\Users" -Limit 260 -ExportFormat "Both" -IncludePermissions
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| Path | Directory to analyze | (Required) |
| Limit | Maximum path length to flag | 400 |
| ExportFormat | Output format (HTML/CSV/Both) | HTML |
| IncludePermissions | Include NTFS permissions | False |

## Output

### What Happens When You Run the Tool

1. **Scanning**: The tool recursively scans the specified directory
2. **Analysis**: Identifies files/folders with paths longer than the specified limit
3. **Report Generation**: Creates timestamped folder with reports
4. **Console Output**: Shows summary statistics and progress
5. **Browser Launch**: Automatically opens HTML report in your default browser

### Generated Reports

The tool creates a timestamped folder (e.g., `Reports_20241218_143022`) containing:

#### HTML Report (`LongPathsReport.html`)
- Interactive tables with sorting and filtering
- Color-coded severity indicators
- Export buttons (Copy, Excel, CSV)
- Detailed statistics and summaries

#### CSV Report (`LongPathsReport.csv`)
- Raw data for further analysis in Excel or other tools
- All identified long paths with metadata
- Path remediation suggestions

#### Console Summary
- Total items processed
- Items exceeding the limit
- Access errors encountered
- Analysis duration

### Report Contents
- Total items exceeding limit
- Path length statistics
- Access errors encountered
- Remediation suggestions
- File creation/modification dates
- NTFS permissions (if requested)

## Common Use Cases

1. **OneDrive Migration Planning**
   - Identify paths that would break OneDrive sync
   - Get suggestions for path restructuring

2. **SharePoint Online Readiness**
   - Verify compatibility with SharePoint path limits
   - Export reports for migration planning

3. **Teams File Sync Preparation**
   - Ensure file paths will sync properly with Teams
   - Identify problematic folder structures

## Known Limitations

- Requires appropriate permissions to access scanned directories
- Some features require administrator privileges
- Performance may vary with large directory structures
- HTML report generation requires Edge, Chrome or FireFox or Safari or any modern Chromium based browser

## Best Practices

- Start with smaller directory structures to understand the output
- Use the `-IncludePermissions` switch only when necessary (impacts performance)
- Review both HTML and CSV reports for different insights
- Address longest paths first for maximum impact

## Troubleshooting

### Common Issues and Solutions

#### 1. Module Installation Errors
```powershell
# If you get module installation errors, try:
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser
```

#### 2. Script Execution Policy Issues
```powershell
# If scripts are blocked, run:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 3. Administrator Privileges Required
- **Error**: "Script requires administrator privileges"
- **Solution**: Run PowerShell as Administrator (Right-click → "Run as administrator")

#### 4. Access Denied Errors
- **Error**: "UnauthorizedAccessException"
- **Solution**: This is normal for protected system folders. The tool will continue scanning accessible areas.

#### 5. Module Not Found
```powershell
# Verify PSWriteHTML is installed:
Get-Module -ListAvailable PSWriteHTML

# If not found, reinstall:
Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser
```

#### 6. "PowerShell script not found" Error
- **Error**: "ERROR: PowerShell script not found! Current directory: C:\Windows\System32"
- **Cause**: Batch files running from wrong directory (common when run with admin privileges)
- **Solution**: This has been fixed in version 1.1.1+ with automatic directory detection
- **Manual Fix**: Always navigate to the WinPathScan folder in Windows Explorer before double-clicking batch files

### Verification Checklist

Before running the tool, ensure:
- [ ] PowerShell 5.1+ is installed
- [ ] NuGet Package Provider is installed
- [ ] PSWriteHTML module is installed
- [ ] Running PowerShell as Administrator
- [ ] In the correct WinPathScan directory
- [ ] Execution policy allows script execution

### Performance Tips

- **Large Directories**: May take several minutes to scan
- **Network Paths**: Scan local paths first for better performance
- **Permissions**: Use `-IncludePermissions` only when necessary (slows down analysis)
- **Memory**: Large directory structures may require significant memory

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

- PSWriteHTML module for report generation
- PowerShell community for testing and feedback

## Author

[AOllivierre]

## Version History

- 2.0.0 - Major redesign: Consolidated batch files, fixed critical bugs, professional naming
- 1.1.1 - Fixed batch file working directory issue (cd /d "%~dp0")
- 1.1.0 - Enhanced reporting features
- 1.0.1 - Added PowerShell 7.x support
- 1.0.0 - Initial release