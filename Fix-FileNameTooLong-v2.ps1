# Tag: EnableLongPathsGit

# Ensure the script is running with administrative privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Please run this script as an Administrator."
    exit
}

# Enable long path support in Git
try {
    git config --global core.longPaths true
    Write-Host "Git is now configured to support long paths."
} catch {
    Write-Error "Failed to configure Git: $_"
}



# Check if the LongPathsEnabled registry entry exists and create it if it doesn't
if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled")) {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
    Write-Host "LongPathsEnabled registry entry created and set to 1."
} else {
    # Set the LongPathsEnabled registry entry to 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
    Write-Host "LongPathsEnabled registry entry already exists and has been set to 1."
}

# Confirm the change
$longPathsEnabled = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled"
Write-Host "LongPathsEnabled is set to:" $longPathsEnabled.LongPathsEnabled


# git config --system core.longpaths true


#Then try cloing with GitHub Desktop, GitHub CLI or Git.exe 

#First trying cloing using the following example

git clone https://github.com/aollivierre/CaaC.git C:\CaaC

# Expected Output
# Cloning into 'C:\CaaC'...
# remote: Enumerating objects: 22458, done.
# remote: Counting objects: 100% (22458/22458), done.
# remote: Compressing objects: 100% (11487/11487), done.
# remote: Total 22458 (delta 11325), reused 21847 (delta 10732), pack-reused 0 (from 0)
# Receiving objects: 100% (22458/22458), 11.96 MiB | 5.51 MiB/s, done.
# Resolving deltas: 100% (11325/11325), done.
# Updating files: 100% (17732/17732), done.