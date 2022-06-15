[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Architecture = 'x64',
    [Parameter(Mandatory = $false)]
    [string]$InstallationPath = '',
    [Parameter(Mandatory = $true)]
    [string]$PackageName,
    [Parameter(Mandatory = $false)]
    [string]$VendorName = 'Temurin-Hotspot',
    [Parameter(Mandatory = $false)]
    [string]$Version = '8.0.332-9',
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = ''
);

function Set-JavaPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Architecture = "x64",
        [Parameter(Mandatory = $false)]
        [switch]$Default,
        [Parameter(Mandatory = $true)]
        [string]$VendorName,
        [Parameter(Mandatory = $true)]
        [Version]$Version
    );

    $javaPath = (Get-Item -Path (
        Join-Path `
            -ChildPath ('Java_{0}_jdk/{1}*/{2}' -f $VendorName, $Version, $Architecture) `
            -Path ${Env:AGENT_TOOLSDIRECTORY}
    )).FullName;

    if ([string]::IsNullOrEmpty($javaPath)) {
        throw ('Java installation not found for version: {0}' -f $Version);
    }

    [System.Environment]::SetEnvironmentVariable(('JAVA_HOME_{0}_{1}' -f $Version.Major, $Architecture.ToUpper()), $javaPath, 'Machine');

    if ($Default) {
        $javaCommand = Get-Command `
            -ErrorAction [Management.Automation.ActionPreference]::Ignore `
            -Name 'java';
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine');

        if ($javaCommand) {
            $machinePath = $machinePath.Replace(('{0};' -f [IO.Path]::GetDirectoryName($javaCommand.Source)), '');
        }

        $machinePath = ('{0};{1}' -f $javaPath, $machinePath);

        [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $javaPath, 'Machine');
        [System.Environment]::SetEnvironmentVariable('Path', $machinePath, "Machine");
    }
}

if ([string]::IsNullOrEmpty($InstallationPath)) {
    $InstallationPath = (
        Join-Path `
            -AdditionalChildPath @($Version) `
            -ChildPath ('Java_{0}_jdk' -f $VendorName) `
            -Path ${Env:AGENT_TOOLSDIRECTORY}
    );
}

if ([string]::IsNullOrEmpty($WorkingDirectory)) {
    $WorkingDirectory = Join-Path `
        -ChildPath 'bytrc' `
        -Path (Get-PSDrive -Name 'Temp').Root;
}

Push-Location -Path $WorkingDirectory;

try {
    Write-Debug 'Extracting Java SDK...';
    Expand-Archive `
        -DestinationPath $InstallationPath `
        -Path $PackageName;
    Get-ChildItem `
        -Path $InstallationPath |
        Rename-Item `
            -NewName $Architecture |
            Out-Null;
    New-Item `
        -ItemType 'File' `
        -Name ('{0}.complete' -f $Architecture) `
        -Path $InstallationPath |
        Out-Null;

    if ('Temurin-Hotspot' -eq $VendorName) {
        if (8 -eq $Version.Major) {
            Set-JavaPath `
                -Default `
                -VendorName $VendorName `
                -Version $Version.Substring(0, $Version.IndexOf('-'));
        } else {
            Set-JavaPath `
                -VendorName $VendorName `
                -Version $Version.Substring(0, $Version.IndexOf('-'));
        }
    }
}
finally {
    Pop-Location;
}
