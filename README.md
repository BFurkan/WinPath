## WinPathScan (PowerShell)

Fast, low-requirements Windows long-path analyzer that scans directories, finds items exceeding a length threshold, and exports CSV/HTML reports. No external modules required.

### Features
- Long-path safe via `\\?\` prefix handling
- Streams filesystem entries using .NET for speed
- Skips reparse points (junctions) by default
- Optional inclusion of directories, hidden, and system items
- CSV and minimal HTML reports
- Console summary with top-N longest

### Requirements
- Windows 10/11 or Windows Server
- PowerShell 5.1 or PowerShell 7.x

### Quick Start
Simplest (non-technical) usage:
- Double-click `START-HERE.bat`
- Choose the folder when prompted (or type a path if prompted in console)
- When asked, enter a limit:
  - 120 = quick test (guarantees results in most folders)
  - 260 = OneDrive/legacy Windows safe threshold
  - 400 = Teams/SharePoint Online planning threshold
- Wait for the report to open

Common scenarios:
- OneDrive/SharePoint planning (260 limit):
```powershell
.\u005cWinPathScan.ps1 -Path "C:\Users" -Limit 260 -ExportFormat Both
```
- Teams file sync (400 limit):
```powershell
.\u005cWinPathScan.ps1 -Path "C:\Users" -Limit 400 -ExportFormat Both
```

### Parameters
- `-Path` (string, required): Root directory to analyze
- `-Limit` (int, default 400): Threshold length to flag
- `-ExportFormat` (HTML|CSV|Both|None, default HTML)
- `-IncludeDirectories` (switch): Also flag directories over limit
- `-IncludeJunctions` (switch): Include reparse points/junctions
- `-IncludeHidden` (switch): Include hidden items
- `-IncludeSystem` (switch): Include system items
- `-Top` (int, default 10): Show top-N in console
- `-ReportDir` (string): Custom output folder (default: `Reports_yyyyMMdd_HHmmss` under script dir)

### Outputs
- CSV: `LongPathsReport.csv`
- HTML: `LongPathsReport.html` (auto-opens when generated)
- Console summary with counts and top-N longest items

### Notes
- Long paths are compared using the standard path (without the extended prefix). The `\\?\` prefix is used internally to traverse paths beyond traditional limits.
- Access-denied locations are skipped and counted as errors; this is expected in protected folders.
 - If the folder picker does not appear, you can type/paste the folder path into the console prompt.

### Credits
Inspired by the approach documented in WinPath repositories like `BFurkan/WinPath` and designed for minimal dependencies and quick deployment.


