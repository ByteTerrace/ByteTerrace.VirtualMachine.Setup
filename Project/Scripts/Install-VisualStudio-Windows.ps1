[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('BuildTools', 'Enterprise', 'Professional')]
    [string]$Edition,
    [Parameter(Mandatory = $false)]
    [string]$Nickname = '',
    [Parameter(Mandatory = $false)]
    [string]$ProductKey = '',
    [Parameter(Mandatory = $false)]
    [string]$TemporaryPath = '',
    [Parameter(Mandatory = $false)]
    [string]$Version = '17.2.3'
);

$localDirectoryPath = Join-Path `
    -ChildPath 'bytrc' `
    -Path (Get-PSDrive -Name 'Temp').Root;
$visualStudioInstallerName = ('vs_{0}_{1}' -f $Edition, $Version)

if ([string]::IsNullOrEmpty($Nickname)) {
    $Nickname = ('BYTRC{0}{1}' -f $Version.Split('.')[0], $Edition[0]);
}

if (-not([string]::IsNullOrEmpty($TemporaryPath))) {
    $localDirectoryPath = $TemporaryPath;
};

Expand-Archive `
    -DestinationPath $localDirectoryPath `
    -Path ('./{0}.zip' -f $visualStudioInstallerName);

$installerArguments = @(
    '--in'
    (Join-Path `
        -AdditionalChildPath ('Response.json' -f $visualStudioInstallerName) `
        -ChildPath $visualStudioInstallerName `
        -Path $localDirectoryPath),
    '--nickname'
    $Nickname,
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

if (-not [string]::IsNullOrEmpty($ProductKey)) {
    $installerArguments += ('--productKey', $ProductKey);
}

& $installerCommand $installerArguments;
