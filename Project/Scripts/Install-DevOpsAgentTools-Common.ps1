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
    [System.Environment]::SetEnvironmentVariable('ACCEPT_EULA', 'Y');

    $remoteBinaries = @(
        # Python 2
        @{
            Path = 'p/python/2/libpython2.7-minimal_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'p/python/2/python2.7-minimal_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'p/python/2/libpython2.7-stdlib_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'p/python/2/python2.7_2.7.17-1~18.04ubuntu1.7_amd64.deb';
        },
        @{
            Path = 'p/python/2/python-minimal_2.7.15~rc1-1_amd64.deb';
        },
        # Node 16
        @{
            Path = 'n/nodejs/16/nodejs_16.14.2-1nodesource1_amd64.deb';
        },
        # Azure CLI 2
        @{
            Path = 'a/azure-cli/2/azure-cli_2.34.1-1~bionic_all.deb';
        },
        # DotNet 6.0
        @{
            Path = 'd/dotnet/6/dotnet-host-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-hostfxr-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-runtime-deps-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-runtime-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/aspnetcore-runtime-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-targeting-pack-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/aspnetcore-targeting-pack-6.0.3.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-apphost-pack-6.0.3-x64.deb';
        },
        @{
            Path = 'd/dotnet/6/netstandard-targeting-pack-2.1_2.1.0-1_amd64.deb';
        },
        @{
            Path = 'd/dotnet/6/dotnet-sdk-6.0.201-x64.deb';
        },
        # Java
        @{
            Path = 'a/alsa-lib/1/libasound2-data_1.1.3-5ubuntu0.6_all.deb';
        },
        @{
            Path = 'j/java-common/0/java-common_0.68ubuntu1~18.04.1_all.deb';
        },
        @{
            Path = 'a/alsa-lib/1/libasound2_1.1.3-5ubuntu0.6_amd64.deb';
        },
        @{
            Path = 'p/p11-kit/0/p11-kit-modules_0.23.9-2ubuntu0.1_amd64.deb';
        },
        @{
            Path = 'f/fonts-dejavu/2/fonts-dejavu-extra_2.37-1_all.deb';
        },
        @{
            Path = 'f/fonts-dejavu/2/fonts-dejavu_2.37-1_all.deb';
        },
        @{
            Path = 'p/p11-kit/0/p11-kit_0.23.9-2ubuntu0.1_amd64.deb';
        },
        @{
            Path = 'a/adoptium-ca-certificates/1/adoptium-ca-certificates_1.0.0-1_all.deb';
        },
        @{
            Path = 'o/openjdk-temurin/8/temurin-8-jdk_8.0.322.0.0+6-1_amd64.deb';
        },
        @{
            Path = 'o/openjdk-temurin/11/temurin-11-jdk_11.0.14.1.0+9-1_amd64.deb';
        },
        @{
            Path = 'o/openjdk-temurin/17/temurin-17-jdk_17.0.2.0.0+8-1_amd64.deb';
        },
        # Moby 20
        @{
            Path = 'm/moby-engine/20/moby-buildx_0.8.1+azure-1_amd64.deb';
        },
        @{
            Path = 'p/pigz/2/pigz_2.4-1_amd64.deb';
        },
        @{
            Path = 'm/moby-engine/20/moby-cli_20.10.14+azure-1_amd64.deb';
        },
        @{
            Path = 'm/moby-engine/20/moby-runc_1.0.3+azure-1_amd64.deb';
        },
        @{
            Path = 'm/moby-engine/20/moby-containerd_1.5.11+azure-1_amd64.deb';
        },
        @{
            Path = 'm/moby-engine/20/moby-engine_20.10.14+azure-1_amd64.deb';
        },
        @{
            Path = 'm/moby-engine/20/moby-compose_2.2.3+azure-1_amd64.deb';
        },
        # MsSql Tools 17
        @{
            Path = 'l/libtool/2/libltdl7_2.4.6-2_amd64.deb';
        },
        @{
            Path = 'u/unixodbc/2/libodbc1_2.3.7_amd64.deb';
        },
        @{
            Arguments = @('-i', ('{0}/odbcinst_2.3.7_amd64.deb' -f $localDirectoryPath), ('{0}/odbcinst1debian2_2.3.7_amd64.deb' -f $localDirectoryPath));
            Command = 'dpkg';
            Paths = @(
                'u/unixodbc/2/odbcinst_2.3.7_amd64.deb',
                'u/unixodbc/2/odbcinst1debian2_2.3.7_amd64.deb'
            );
        },
        @{
            Path = 'u/unixodbc/2/unixodbc_2.3.7_amd64.deb';
        },
        @{
            Path = 'm/mssql-tools/17/msodbcsql17_17.9.1.1-1_amd64.deb';
        },
        @{
            Path = 'm/mssql-tools/17/mssql-tools_17.9.1.1-1_amd64.deb';
        },
        # MySql 5
        @{
            Path = 'l/libaio/0/libaio1_0.3.110-5ubuntu0.1_amd64.deb';
        },
        @{
            Path = 'm/mysql-common/5/mysql-common_5.8+1.0.4_all.deb';
        },
        @{
            Path = 'm/mysql-client/5/mysql-client-core-5.7_5.7.37-0ubuntu0.18.04.1_amd64.deb';
        },
        @{
            Path = 'm/mysql-client/5/mysql-client-5.7_5.7.37-0ubuntu0.18.04.1_amd64.deb';
        },
        @{
            Path = 'm/mysql-client/5/mysql-client_5.7.37-0ubuntu0.18.04.1_all.deb';
        },
        # Kubernetes
        @{
            Path = 'k/kubectl/1/kubectl_1.23.5-00_amd64.deb';
        },
        @{
            Path = 'h/helm/3/helm_3.8.1-1_amd64.deb';
        },
        # Packer
        @{
            Path = 'p/packer/1/packer_1.8.0_amd64.deb';
        },
        # Terraform
        @{
            Path = 't/terraform/1/terraform_1.1.8_amd64.deb';
        },
        # Podman 3
        @{
            Path = 'p/podman/3/libnet1_1.1.6+dfsg-3.1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/catatonit_0.1.5~1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/slirp4netns_1.1.8-3_amd64.deb';
        },
        @{
            Path = 'p/podman/3/libprotobuf-c1_1.2.1-2_amd64.deb';
        },
        @{
            Path = 'p/podman/3/dbus-user-session_1.12.2-1ubuntu1.2_amd64.deb';
        },
        @{
            Path = 'p/podman/3/libgpgme11_1.10.0-1ubuntu2_amd64.deb';
        },
        @{
            Path = 'p/podman/3/libprotobuf10_3.0.0-9.1ubuntu1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/libyajl2_2.1.0-2build1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/python3-protobuf_3.0.0-9.1ubuntu1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/libnl-3-200_3.2.29-0ubuntu3_amd64.deb';
        },
        @{
            Path = 'p/podman/3/conmon_2.1.0-2_amd64.deb';
        },
        @{
            Path = 'p/podman/3/containers-common_1-22_all.deb';
        },
        @{
            Path = 'p/podman/3/containernetworking-plugins_0.9.1-1_amd64.deb';
        },
        @{
            Path = 'p/podman/3/podman-plugins_1.1.1-5_amd64.deb';
        },
        @{
            Path = 'p/podman/3/criu_3.16.1-3_amd64.deb';
        },
        @{
            Path = 'p/podman/3/crun_0.18-2_amd64.deb';
        },
        @{
            Path = 'p/podman/3/podman_3.0.1-2_amd64.deb';
        },
        # Buildah
        @{
            Path = 'b/buildah/1/buildah_1.19.6-2_amd64.deb';
        },
        # Skopeo
        @{
            Path = 's/skopeo/1/skopeo_1.2.2-2_amd64.deb';
        }
    );
}

if ($IsWindows) {
    $remoteBinaries = @(
        # Node
        @{
            Path = 'n/nodejs/16/node-v16.14.2-x64.msi';
        },
        # Azure CLI
        @{
            Path = 'a/azure-cli/2/azure-cli-2.34.1.msi';
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
            Path = 'g/git/2/Git-2.35.2-64-bit.exe';
        }
        # .NET 6.0
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'd/dotnet/6/dotnet-sdk-6.0.201-win-x64.exe';
        },
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'd/dotnet/6/aspnetcore-runtime-6.0.3-win-x64.exe';
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
        if ($null -eq $_.Command) {
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
        }
        else {
            $localBinaries.Add(@{
                Arguments = $_.Arguments;
                Command = $_.Command;
            });

            $_.Paths |
                ForEach-Object {
                    $azureStorageBlobParams = @{
                        AccountName = $AccountName;
                        LocalFilePath = ('{0}/{1}' -f $localDirectoryPath, ($_ -Split '/' | Select-Object -Last 1));
                        RemoteBlobPath = ('{0}/{1}' -f $remoteBlobBasePath, $_);
                    };

                    if ($Force) {
                        $azureStorageBlobParams.Force = $true;
                    }

                    Get-AzureStorageBlob @azureStorageBlobParams |
                        Out-Null;
                };
        }
    };

$localBinaries |
    ForEach-Object {
        $arguments = ([Collections.Generic.List[string]]$_.Arguments);

        if ($null -eq $arguments) {
            $arguments = [Collections.Generic.List[string]]::new();
        }

        if ($null -eq $_.Command) {
            $fileInfo = $_.FileInfo;

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
        }
        else {
            Invoke-Executable `
                -Arguments $arguments `
                -FileName $_.Command;
        }
    };
