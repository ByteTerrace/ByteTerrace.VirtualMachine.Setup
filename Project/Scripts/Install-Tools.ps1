[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AccountName = 'byteterrace',
    [Parameter(Mandatory = $false)]
    [string]$TemporaryPath = ''
);

$localBinaries = @();
$localDirectoryPath = ('{0}{1}' -f (Get-PSDrive -Name 'Temp').Root, 'bytrc');
$remoteBinaries = @();
$remoteBlobBasePath = 'binaries';

if (-not([string]::IsNullOrEmpty($TemporaryPath))) {
    $localDirectoryPath = $TemporaryPath;
}

if ($IsLinux) {
    $remoteBinaries = @(
        # Azure CLI
        'AzureCli/2/azure-cli_2.34.1-1~bionic_all.deb',
        # .NET 6.0
        'DotNet/6/dotnet-host-6.0.3-x64.deb',
        'DotNet/6/dotnet-hostfxr-6.0.3-x64.deb',
        'DotNet/6/dotnet-runtime-deps-6.0.3-x64.deb',
        'DotNet/6/dotnet-runtime-6.0.3-x64.deb',
        'DotNet/6/aspnetcore-runtime-6.0.3-x64.deb',
        'DotNet/6/dotnet-targeting-pack-6.0.3-x64.deb',
        'DotNet/6/aspnetcore-targeting-pack-6.0.3.deb',
        'DotNet/6/dotnet-apphost-pack-6.0.3-x64.deb',
        'DotNet/6/netstandard-targeting-pack-2.1_2.1.0-1_amd64.deb',
        'DotNet/6/dotnet-sdk-6.0.201-x64.deb',
        # Moby
        'MobyEngine/20/moby-buildx_0.8.1+azure-1_amd64.deb',
        'Pigz/2/pigz_2.4-1_amd64.deb',
        'MobyEngine/20/moby-cli_20.10.14+azure-1_amd64.deb',
        'MobyEngine/20/moby-runc_1.0.3+azure-1_amd64.deb',
        'MobyEngine/20/moby-containerd_1.5.11+azure-1_amd64.deb',
        'MobyEngine/20/moby-engine_20.10.14+azure-1_amd64.deb',
        'MobyEngine/20/moby-compose_2.2.3+azure-1_amd64.deb'
    );
}

if ($IsWindows) {
    $remoteBinaries = @(
        'AzureCli/2/azure-cli-2.34.1.msi'
    );
}

New-Item `
    -Force `
    -Path $localDirectoryPath `
    -Type 'Directory' |
    Out-Null;

$remoteBinaries |
    ForEach-Object {
        $fileName = ($_ -Split '/' | Select-Object -Last 1);
        $localBinaries += Get-AzureStorageBlob `
            -AccountName $AccountName `
            -LocalFilePath ('{0}/{1}' -f $localDirectoryPath, $fileName) `
            -RemoteBlobPath ('{0}/{1}' -f $remoteBlobBasePath, $_);
    };

$localBinaries |
    ForEach-Object {
        if ($_.Name.EndsWith('.deb')) {
            Invoke-Executable `
                -Arguments @(
                    'dpkg',
                    '-i',
                    $_.FullName
                ) `
                -FileName 'sudo';
        }
    };
