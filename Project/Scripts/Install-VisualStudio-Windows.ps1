[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigurationFilePath = '',
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

if ([string]::Empty -eq $Nickname) {
    $Nickname = ('BYTRC{0}{1}' -f $Version.Split('.')[0], $Edition[0]);
}

if ([string]::IsNullOrEmpty($TemporaryPath)) {
    $TemporaryPath = Join-Path `
        -ChildPath 'bytrc' `
        -Path (Get-PSDrive -Name 'Temp').Root;
}

$visualStudioInstallerName = ('vs_{0}_{1}' -f $Edition, $Version);
$visualStudioInstallerPath = Join-Path `
    -ChildPath $visualStudioInstallerName `
    -Path $TemporaryPath;

if ([string]::IsNullOrEmpty($ConfigurationFilePath)) {
    $ConfigurationFilePath = (Join-Path `
        -ChildPath 'Response.json' `
        -Path $visualStudioInstallerPath);
}

Write-Debug 'Extracting Visual Studio Build Tools installer...';

Expand-Archive `
    -DestinationPath $TemporaryPath `
    -Path (Join-Path `
        -ChildPath ('{0}.zip' -f $visualStudioInstallerName) `
        -Path (Get-Location));

$installerArguments = @(
    '--in'
    $ConfigurationFilePath,
    '--norestart',
    '--noWeb',
    '--quiet'
);
$installerCommand = Get-Command `
    -Name (Join-Path `
        -ChildPath ('{0}.exe' -f $visualStudioInstallerName) `
        -Path $visualStudioInstallerPath);

if ($null -ne $Nickname) {
    $installerArguments += ('--nickname', $Nickname);
}

if (-not [string]::IsNullOrEmpty($ProductKey)) {
    $installerArguments += ('--productKey', $ProductKey);
}

Write-Debug 'Running Visual Studio Build Tools installer...';

$installerProcess = Start-Process `
    -ArgumentList $installerArguments `
    -FilePath $installerCommand `
    -PassThru `
    -Wait;
$installerExitCode = $installerProcess.ExitCode;

Write-Debug 'Removing Visual Studio Build Tools installer...';

Remove-Item `
    -Force `
    -Path $visualStudioInstallerPath `
    -Recurse;

if ((0 -ne $installerExitCode) -and (3010 -ne $installerExitCode)) {
    throw ('Visual Studio installer exited with failure code: {0}.' -f $installerExitCode);
}
