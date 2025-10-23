# Admin and PS version checks
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$isPS5 = $PSVersionTable.PSVersion.Major -eq 5

function Install-RequiredModule {
    param($ModuleName)
    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        if ($isPS5 -and $isAdmin) {
            $installParams = @{
                Name = $ModuleName
                Force = $true
                AllowClobber = $true
                Scope = 'AllUsers'
            }
            Install-Module @installParams
        } else {
            throw "PowerShell 5 and admin rights required for module installation"
        }
    }
}

$requiredModules = @(
    'PSWriteHTML'
)

$requiredModules | ForEach-Object { Install-RequiredModule $_ }
Import-Module $requiredModules