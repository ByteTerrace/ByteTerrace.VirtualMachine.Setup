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
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [Version]$Version
    );

    if ([string]::IsNullOrEmpty($Value)) {
        throw ('Java path cannot be null or empty.');
    }

    [System.Environment]::SetEnvironmentVariable(('JAVA_HOME_{0}_{1}' -f $Version.Major, $Architecture.ToUpper()), $Value, 'Machine');

    if ($Default) {
        $javaCommand = Get-Command `
            -ErrorAction ([Management.Automation.ActionPreference]::Ignore) `
            -Name 'java';
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine');

        if ($javaCommand) {
            $machinePath = $machinePath.Replace(('{0};' -f [IO.Path]::GetDirectoryName($javaCommand.Source)), '');
        }

        $machinePath = ('{0}\bin;{1}' -f $Value, $machinePath);

        [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $Value, 'Machine');
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

    $javaPath = Join-Path `
        -ChildPath $Architecture `
        -Path $InstallationPath;
    $parsedVersion = ([Version]$Version.Substring(0, $Version.IndexOf('-')));

    if ('Temurin-Hotspot' -eq $VendorName) {
        $setJavaPathParams = @{
            Architecture = $Architecture;
            Value = $javaPath;
            Version = $parsedVersion;
        };

        if (8 -eq $parsedVersion.Major) {
            $setJavaPathParams.Default = $true;
        }

        Set-JavaPath @setJavaPathParams;
    }
}
finally {
    Pop-Location;
}
