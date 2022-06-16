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
        [switch]$SystemDefault,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [Version]$Version,
        [Parameter(Mandatory = $false)]
        [switch]$VersionDefault
    );

    if ([string]::IsNullOrEmpty($Value)) {
        throw ('Java path cannot be null or empty.');
    }

    [Environment]::SetEnvironmentVariable(('JAVA_HOME_{0}_{1}' -f $Version.Major, $Architecture.ToUpper()), $Value, [EnvironmentVariableTarget]::Machine);

    if ($SystemDefault) {
        $javaCommand = Get-Command `
            -ErrorAction ([Management.Automation.ActionPreference]::Ignore) `
            -Name 'java';
        $machinePath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine);

        if ($javaCommand) {
            $machinePath = $machinePath.Replace(('{0};' -f [IO.Path]::GetDirectoryName($javaCommand.Source)), '');
        }

        $machinePath = ('{0}\bin;{1}' -f $Value, $machinePath);

        [Environment]::SetEnvironmentVariable('JAVA_HOME', $Value, [EnvironmentVariableTarget]::Machine);
        [Environment]::SetEnvironmentVariable('Path', $machinePath, [EnvironmentVariableTarget]::Machine);
    }

    if ($VersionDefault) {
        if (8 -eq $Version.Major) {
            $registryKey = 'HKLM:\SOFTWARE\JavaSoft\Java Development Kit\1.8';
        }

        if (8 -lt $Version.Major) {
            $registryKey = ('HKLM:\SOFTWARE\JavaSoft\JDK\{0}' -f $Version.Major);
        }

        New-Item `
            -Force `
            -Path $registryKey |
            Out-Null;
        Set-ItemProperty `
            -Force `
            -Name 'JavaHome' `
            -Path $registryKey `
            -Value $Value |
            Out-Null;
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

    $javaPath = Join-Path `
        -ChildPath $Architecture `
        -Path $InstallationPath;
    $parsedVersion = ([Version]$Version.Substring(0, $Version.IndexOf('-')));

    if ('Temurin-Hotspot' -eq $VendorName) {
        $setJavaPathParams = @{
            Architecture = $Architecture;
            Value = $javaPath;
            Version = $parsedVersion;
            VersionDefault = $true;
        };

        if (8 -eq $parsedVersion.Major) {
            $setJavaPathParams.SystemDefault = $true;
        }

        Set-JavaPath @setJavaPathParams;
    }
}
finally {
    Pop-Location;
}
