[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AccountName = 'byteterrace',
    [Parameter(Mandatory = $false)]
    [Management.Automation.SwitchParameter]$Force,
    [Parameter(Mandatory = $false)]
    [string]$TemporaryPath = ''
);

$localBinaries = [Collections.Generic.List[PSObject]]::new();
$localDirectoryPath = ('{0}{1}' -f (Get-PSDrive -Name 'Temp').Root, 'bytrc');
$remoteBinaries = @();
$remoteBlobBasePath = 'binaries';

if (-not([string]::IsNullOrEmpty($TemporaryPath))) {
    $localDirectoryPath = $TemporaryPath;
}

if ($IsLinux) {
    $remoteBinaries = @(
        # Azure CLI
        @{
            Path = 'AzureCli/2/azure-cli_2.34.1-1~bionic_all.deb';
        },
        # .NET 6.0
        @{
            Path = 'DotNet/6/dotnet-host-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-hostfxr-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-runtime-deps-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-runtime-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/aspnetcore-runtime-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-targeting-pack-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/aspnetcore-targeting-pack-6.0.3.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-apphost-pack-6.0.3-x64.deb';
        },
        @{
            Path = 'DotNet/6/netstandard-targeting-pack-2.1_2.1.0-1_amd64.deb';
        },
        @{
            Path = 'DotNet/6/dotnet-sdk-6.0.201-x64.deb';
        },
        # Moby
        @{
            Path = 'MobyEngine/20/moby-buildx_0.8.1+azure-1_amd64.deb';
        },
        @{
            Path = 'Pigz/2/pigz_2.4-1_amd64.deb';
        },
        @{
            Path = 'MobyEngine/20/moby-cli_20.10.14+azure-1_amd64.deb';
        },
        @{
            Path = 'MobyEngine/20/moby-runc_1.0.3+azure-1_amd64.deb';
        },
        @{
            Path = 'MobyEngine/20/moby-containerd_1.5.11+azure-1_amd64.deb';
        },
        @{
            Path = 'MobyEngine/20/moby-engine_20.10.14+azure-1_amd64.deb';
        },
        @{
            Path = 'MobyEngine/20/moby-compose_2.2.3+azure-1_amd64.deb';
        }
    );
}

if ($IsWindows) {
    $remoteBinaries = @(
        @{
            Arguments = @('/norestart', '/qn');
            Path = 'AzureCli/2/azure-cli-2.34.1.msi';
        },
        @{
            Arguments = @('/norestart', '/qn');
            Path = 'Node/16/node-v16.14.2-x64.msi';
        }
    );
}

New-Item `
    -Force `
    -Path $localDirectoryPath `
    -Type 'Directory' |
    Out-Null;

$remoteBinaries |
    ForEach-Object {
        $azureStorageBlobParams = @{
            AccountName = $AccountName;
            LocalFilePath = ('{0}/{1}' -f $localDirectoryPath, ($_.Path -Split '/' | Select-Object -Last 1));
            RemoteBlobPath = ('{0}/{1}' -f $remoteBlobBasePath, $_.Path);
        };

        if ($Force) {
            $azureStorageBlobParams.Force = $true;
        }

        $localBinaries.Add(@{
            Arguments = $_.Arguments;
            FileInfo = Get-AzureStorageBlob @azureStorageBlobParams;
        });
    };

$localBinaries |
    ForEach-Object {
        $arguments = ([Collections.Generic.List[string]]$_.Arguments);
        $fileInfo = $_.FileInfo;

        if ($null -eq $arguments) {
            $arguments = [Collections.Generic.List[string]]::new();
        }

        switch ($fileInfo.Name) {
            { $_.EndsWith('.deb') } {
                $arguments.Add('-i');
                $arguments.Add($fileInfo.FullName);

                Invoke-Executable `
                    -Arguments $arguments `
                    -FileName 'dpkg';
            }
            { $_.EndsWith('.exe') } {
                Invoke-Executable `
                    -Arguments $arguments `
                    -FileName $fileInfo.FullName;
            }
            { $_.EndsWith('.msi') } {
                $arguments.Add('/i');
                $arguments.Add($fileInfo.FullName);

                Invoke-Executable `
                    -Arguments $arguments `
                    -FileName 'msiexec.exe';
            }
        }
    };
