<#
    Reference:
        https://docs.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio?view=vs-2022
        https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022
        https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids?view=vs-2022
 #>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigurationFilePath = '',
    [Parameter(Mandatory = $true)]
    [ValidateSet('BuildTools', 'Enterprise', 'Professional')]
    [string]$Edition,
    [Parameter(Mandatory = $false)]
    [string]$InstallationPath = '',
    [Parameter(Mandatory = $false)]
    [string]$Nickname = '',
    [Parameter(Mandatory = $false)]
    [string]$ProductKey = '',
    [Parameter(Mandatory = $false)]
    [string]$Version = '17.2.3',
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = ''
);

if ([string]::Empty -eq $Nickname) {
    $Nickname = ('BYTRC{0}{1}' -f $Version.Split('.')[0], $Edition[0]);
}

if ([string]::IsNullOrEmpty($WorkingDirectory)) {
    $WorkingDirectory = Join-Path `
        -ChildPath 'bytrc' `
        -Path (Get-PSDrive -Name 'Temp').Root;
}

$visualStudioInstallerName = ('vs_{0}_{1}' -f $Edition, $Version);
$visualStudioInstallerPath = Join-Path `
    -ChildPath $visualStudioInstallerName `
    -Path $WorkingDirectory;

if ([string]::IsNullOrEmpty($ConfigurationFilePath)) {
    $ConfigurationFilePath = (
        Join-Path `
            -ChildPath 'Response.json' `
            -Path $visualStudioInstallerPath
    );
}

Push-Location -Path $WorkingDirectory;

try {
    Write-Debug 'Extracting Visual Studio installer...';
    Expand-Archive `
        -DestinationPath '.' `
        -Path ('{0}.zip' -f $visualStudioInstallerName);

    $installerArguments = @(
        '--in'
        $ConfigurationFilePath,
        '--norestart',
        '--noWeb',
        '--quiet'
    );

    if (-not [string]::IsNullOrEmpty($InstallationPath)) {
        $installerArguments += ('--installPath', $InstallationPath);
    }

    if ($null -ne $Nickname) {
        $installerArguments += ('--nickname', $Nickname);
    }

    if (-not [string]::IsNullOrEmpty($ProductKey)) {
        $installerArguments += ('--productKey', $ProductKey);
    }

    Write-Debug 'Running Visual Studio installer...';

    $installerProcess = Start-Process `
        -ArgumentList $installerArguments `
        -FilePath (
            Join-Path `
                -ChildPath ('{0}.exe' -f $visualStudioInstallerName) `
                -Path $visualStudioInstallerPath
        ) `
        -PassThru `
        -Wait;
    $installerExitCode = $installerProcess.ExitCode;

    if (0 -ne $installerExitCode) {
        throw ('Visual Studio installer exited with failure code: {0}.' -f $installerExitCode);
    }
}
finally {
    if (Test-Path -Path $visualStudioInstallerPath) {
        Write-Debug 'Removing Visual Studio installer...';
        Remove-Item `
            -Force `
            -Path $visualStudioInstallerPath `
            -Recurse;
    }

    Pop-Location;
}
