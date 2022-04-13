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
        # Python
        @{
            Path = 'Python/2/libpython2.7-minimal_2.7.17-1~18.04ubuntu1.7_amd64.deb'
        },
        @{
            Path = 'Python/2/python2.7-minimal_2.7.17-1~18.04ubuntu1.7_amd64.deb'
        },
        @{
            Path = 'Python/2/libpython2.7-stdlib_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'Python/2/python2.7_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'Python/2/python-minimal_2.7.15~rc1-1_amd64.deb';
        },
        # Node
        @{
            Path = 'Node/16/nodejs_16.14.2-1nodesource1_amd64.deb';
        },
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
        },
        # Kubernetes
        @{
            Path = 'Kubectl/1/kubectl_1.23.5-00_amd64.deb';
        },
        @{
            Path = 'Helm/3/helm_3.8.1-1_amd64.deb';
        },
        # Packer
        @{
            Path = 'Packer/1/packer_1.8.0_amd64.deb';
        },
        # Podman
        @{
            Path = 'Podman/3/libnet1_1.1.6+dfsg-3.1_amd64.deb';
        },
        @{
            Path = 'Podman/3/catatonit_0.1.5~1_amd64.deb';
        },
        @{
            Path = 'Podman/3/slirp4netns_1.1.8-3_amd64.deb';
        },
        @{
            Path = 'Podman/3/libprotobuf-c1_1.2.1-2_amd64.deb';
        },
        @{
            Path = 'Podman/3/dbus-user-session_1.12.2-1ubuntu1.2_amd64.deb';
        },
        @{
            Path = 'Podman/3/libgpgme11_1.10.0-1ubuntu2_amd64.deb';
        },
        @{
            Path = 'Podman/3/libprotobuf10_3.0.0-9.1ubuntu1_amd64.deb';
        },
        @{
            Path = 'Podman/3/libyajl2_2.1.0-2build1_amd64.deb';
        },
        @{
            Path = 'Podman/3/python3-protobuf_3.0.0-9.1ubuntu1_amd64.deb';
        },
        @{
            Path = 'Podman/3/libnl-3-200_3.2.29-0ubuntu3_amd64.deb';
        },
        @{
            Path = 'Podman/3/conmon_2.1.0-2_amd64.deb';
        },
        @{
            Path = 'Podman/3/containers-common_1-22_all.deb';
        },
        @{
            Path = 'Podman/3/containernetworking-plugins_0.9.1-1_amd64.deb';
        },
        @{
            Path = 'Podman/3/podman-plugins_1.1.1-5_amd64.deb';
        },
        @{
            Path = 'Podman/3/criu_3.16.1-3_amd64.deb';
        },
        @{
            Path = 'Podman/3/crun_0.18-2_amd64.deb';
        },
        @{
            Path = 'Podman/3/podman_3.0.1-2_amd64.deb';
        },
        # Terraform
        @{
            Path = 'Terraform/1/terraform_1.1.8_amd64.deb';
        }
    );
}

if ($IsWindows) {
    $remoteBinaries = @(
        # Node
        @{
            Path = 'Node/16/node-v16.14.2-x64.msi';
        },
        # Azure CLI
        @{
            Path = 'AzureCli/2/azure-cli-2.34.1.msi';
        },
        # Git
        @{
            Arguments = @(
                '/CLOSEAPPLICATIONS',
                '/COMPONENTS=gitlfs',
                '/NOCANCEL',
                '/NORESTART',
                '/RESTARTAPPLICATIONS',
                '/SP-',
                '/VERYSILENT',
                '/o:BashTerminalOption=ConHost',
                '/o:EnableSymLink=Enabled',
                '/o:PathOption=CmdTools'
            );
            Path = 'Git/2/Git-2.35.1.2-64-bit.exe';
        }
        # .NET 6.0
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'DotNet/6/dotnet-sdk-6.0.201-win-x64.exe';
        },
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'DotNet/6/aspnetcore-runtime-6.0.3-win-x64.exe';
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
                $arguments.Add('/norestart');
                $arguments.Add('/qn');

                Invoke-Executable `
                    -Arguments $arguments `
                    -FileName 'msiexec.exe';
            }
        }
    };
