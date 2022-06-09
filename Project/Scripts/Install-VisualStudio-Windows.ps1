[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('BuildTools', 'Enterprise', 'Professional')]
    [string]$Edition,
    [Parameter(Mandatory = $false)]
    [string]$TemporaryPath = '',
    [Parameter(Mandatory = $false)]
    [string]$Version = '17.2.3'
);

$localDirectoryPath = Join-Path `
    -ChildPath 'bytrc' `
    -Path (Get-PSDrive -Name 'Temp').Root;
$visualStudioInstallerName = ('vs_{0}_{1}' -f $Edition, $Version)

if (-not([string]::IsNullOrEmpty($TemporaryPath))) {
    $localDirectoryPath = $TemporaryPath;
};

Expand-Archive `
    -DestinationPath $localDirectoryPath `
    -Path ('./{0}.zip' -f $visualStudioInstallerName);

$configurationFilePath = (
    Join-Path `
        -AdditionalChildPath ('Configuration.json' -f $visualStudioInstallerName) `
        -ChildPath $visualStudioInstallerName `
        -Path $localDirectoryPath
);
$configurationFileValue = ConvertFrom-Json `
    -InputObject (
        Get-Content `
            -Path (
                Join-Path `
                    -AdditionalChildPath ('Layout.json' -f $visualStudioInstallerName) `
                    -ChildPath $visualStudioInstallerName `
                    -Path $localDirectoryPath
            ) `
            -Raw
    );

New-Item `
    -ItemType 'File' `
    -Path $configurationFilePath `
    -Value (
        ConvertTo-Json -InputObject @{
            components = $configurationFileValue.add;
            version = '1.0';
        }
    ) |
    Out-Null;

$installerArguments = @(
    '--config'
    $configurationFilePath,
    '--norestart',
    '--noWeb',
    '--quiet'
);
$installerCommand = Get-Command `
    -Name (
        Join-Path `
            -AdditionalChildPath ('{0}.exe' -f $visualStudioInstallerName) `
            -ChildPath $visualStudioInstallerName `
            -Path $localDirectoryPath
        );

& $installerCommand $installerArguments;
