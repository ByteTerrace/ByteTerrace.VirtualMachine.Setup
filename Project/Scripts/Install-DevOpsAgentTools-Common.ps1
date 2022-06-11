[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AccountName = 'byteterrace',
    [Parameter(Mandatory = $false)]
    [string]$BlobContainerName = 'binaries',
    [Parameter(Mandatory = $false)]
    [Management.Automation.SwitchParameter]$Force,
    [Parameter(Mandatory = $false)]
    [PSObject[]]$Tasks = @(),
    [Parameter(Mandatory = $false)]
    [string]$TemporaryPath = ''
);

function Update-EnvironmentVariables {
    $originalArchitecture = ${Env:PROCESSOR_ARCHITECTURE};
    $originalPsModulePath = ${Env:PSModulePath};
    $originalUserName = ${Env:USERNAME};
    $pathEntries = ([string[]]@());

    # process
    Get-ChildItem `
        -Path 'Env:\' |
        Select-Object `
            -ExpandProperty 'Key' |
            ForEach-Object {
                Set-Item `
                    -Path ('Env:{0}' -f $_) `
                    -Value ([Environment]::GetEnvironmentVariable($_, [EnvironmentVariableTarget]::Process));
            };

    # machine
    $machineEnvironmentRegistryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment\');

    if ($null -ne $machineEnvironmentRegistryKey) {
        try {
            Get-Item `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' |
                Select-Object `
                    -ExpandProperty 'Property' |
                    ForEach-Object {
                        $value =  $machineEnvironmentRegistryKey.GetValue(`
                            $_, `
                            [string]::Empty, `
                            [Microsoft.Win32.RegistryValueOptions]::None `
                        );

                        Set-Item `
                            -Path ('Env:{0}' -f $_) `
                            -Value $value;

                        if ('PATH' -eq $_) {
                            $pathEntries += $value.Split(';');
                        }
                    };
        }
        finally {
            $machineEnvironmentRegistryKey.Close();
        }
    }

    #user
    if ($originalUserName -notin @('SYSTEM', ('{0}$' -f ${Env:COMPUTERNAME}))) {
        $userEnvironmentRegistryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');
        $userPathEntries = ([string[]]@());

        if ($null -ne $userEnvironmentRegistryKey) {
            try {
                Get-Item `
                    -Path 'HKCU:\Environment' |
                    Select-Object `
                        -ExpandProperty 'Property' |
                        ForEach-Object {
                            $value =  $userEnvironmentRegistryKey.GetValue(`
                                $_, `
                                [string]::Empty, `
                                [Microsoft.Win32.RegistryValueOptions]::None `
                            );

                            Set-Item `
                                -Path ('Env:{0}' -f $_) `
                                -Value $value;

                            if ('PATH' -eq $_) {
                                $pathEntries += $value.Split(';');
                            }
                        };
            }
            catch {
                $userEnvironmentRegistryKey.Close();
            }
        }
    }

    ${Env:PATH} = (($pathEntries | Select-Object -Unique) -Join ';');
    ${Env:PROCESSOR_ARCHITECTURE} = $originalArchitecture;
    ${Env:PSModulePath} = $originalPsModulePath;

    if ($originalUserName) {
        ${Env:USERNAME} = $originalUserName;
    }
}

$internalTasks = [Collections.Generic.List[PSObject]]::new();
$localDirectoryPath = ('{0}{1}' -f (Get-PSDrive -Name 'Temp').Root, 'bytrc');

if (-not([string]::IsNullOrEmpty($TemporaryPath))) {
    $localDirectoryPath = $TemporaryPath;
}

[System.Environment]::SetEnvironmentVariable('ACCEPT_EULA', 'Y');
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1');

if ($IsLinux) {
    [System.Environment]::SetEnvironmentVariable('AGENT_TOOLSDIRECTORY', '/agent/_work/_tool');

    $powerShellModulePath = '/opt/microsoft/powershell/7-lts/Modules';
    $Tasks += @(
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
        # Python 3
        @{
            Path = 'p/python/3/libpython3.8-minimal_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'p/python/3/python3.8-minimal_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'p/python/3/libpython3.8-stdlib_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'p/python/3/libpython3.8_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'l/linux/4/linux-libc-dev_4.15.0-177.186_amd64.deb';
        },
        @{
            Path = 'g/glibc/2/libc-dev-bin_2.27-3ubuntu1.5_amd64.deb';
        },
        @{
            Path = 'g/glibc/2/libc6-dev_2.27-3ubuntu1.5_amd64.deb';
        },
        @{
            Path = 'e/expat/2/libexpat1-dev_2.2.5-3ubuntu0.7_amd64.deb';
        },
        @{
            Path = 'm/manpages/4/manpages-dev_4.15-1_all.deb';
        },
        @{
            Path = 'p/python/3/libpython3.8-dev_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'p/python/3/python3.8_3.8.0-3ubuntu1~18.04.2_amd64.deb';
        },
        @{
            Path = 'p/python/3/python-3.8.12-linux-18.04-x64.tar.gz';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/Python/3.8.12/x64' -f $localDirectoryPath);
        },
        # Node 12
        @{
            Path = 'n/nodejs/12/node-12.22.12-linux-x64.tar.gz';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/node/12.22.12/x64' -f $localDirectoryPath);
        },
        # Node 14
        @{
            Path = 'n/nodejs/14/node-14.19.2-linux-x64.tar.gz';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/node/14.19.2/x64' -f $localDirectoryPath);
        },
        # Node 16
        @{
            Path = 'n/nodejs/16/node-16.15.0-linux-x64.tar.gz';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/node/16.15.0/x64' -f $localDirectoryPath);
        },
        # Node 18
        @{
            Path = 'n/nodejs/18/node-18.1.0-linux-x64.tar.gz';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/node/18.1.0/x64' -f $localDirectoryPath);
        },
        # PowerShell Az Module
        @{
            Path = 'p/powershell/modules/az/8/Az_8.0.0.zip';
            Type = 'PowerShellModule';
        },
        # PowerShell PackageManagement Module
        @{
            Path = 'p/powershell/modules/packagemanagement/1/PackageManagement_1.4.7.zip';
            Type = 'PowerShellModule';
        },
        # PowerShell SqlServer Module
        @{
            Path = 'p/powershell/modules/sqlserver/20/SqlServer_21.1.18256.zip';
            Type = 'PowerShellModule';
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
            Commands = @(
                @{
                    Arguments = @(
                        '-i',
                        ('{0}/odbcinst_2.3.7_amd64.deb' -f $localDirectoryPath),
                        ('{0}/odbcinst1debian2_2.3.7_amd64.deb' -f $localDirectoryPath)
                    );
                    Value = 'dpkg';
                }
            );
            Paths = @(
                'u/unixodbc/2/odbcinst_2.3.7_amd64.deb',
                'u/unixodbc/2/odbcinst1debian2_2.3.7_amd64.deb'
            );
            Type = 'Executable'
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
elseif ($IsWindows) {
    [System.Environment]::SetEnvironmentVariable('AGENT_TOOLSDIRECTORY', ('{0}/agent/_work/_tool' -f ${Env:SystemDrive}));

    $powerShellModulePath = ('{0}/PowerShell/7/Modules' -f [System.Environment]::GetEnvironmentVariable('ProgramFiles'));
    $Tasks += @(
        # 7-Zip
        @{
            Arguments = @('/S');
            Path = 's/7zip/20/7z2107-x64.exe';
            UpdateEnvironmentVariables = $true;
        },
        # Visual Studio Build Tools
        @{
            Commands = @(
                @{
                    Arguments = @{
                        Edition = 'BuildTools';
                    };
                    Value = ('{0}/Install-VisualStudioLayout-Windows.ps1' -f $localDirectoryPath);
                }
            );
            Paths = @(
                'v/visual-studio/17/Install-VisualStudioLayout-Windows.ps1',
                'v/visual-studio/17/vs_BuildTools_17.2.3.zip'
            );
            Type = 'PowerShellScript';
        },
        # Azure CLI
        @{
            Path = 'a/azure-cli/2/azure-cli-2.37.0.msi';
            UpdateEnvironmentVariables = $true;
        },
        # Chrome
        @{
            Path = 'c/chrome/100/googlechromestandaloneenterprise64_102.0.5005.115.msi';
        },
        # Edge
        @{
            Path = 'e/edge/100/MicrosoftEdgeEnterpriseX64_102.0.1245.39.msi';
        },
        # Firefox
        @{
            Path = 'f/firefox/100/Firefox Setup 101.0.1.msi';
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
            Path = 'g/git/2/Git-2.36.1-64-bit.exe';
        },
        # GitHub CLI
        @{
            Path = 'g/github-cli/2/gh_2.12.1_windows_amd64.msi';
        },
        # Java 8
        @{
            Commands = @(
                @{
                    Arguments = @{
                        Architecture = 'x64';
                        PackageName = 'OpenJDK8U-jdk_x64_windows_hotspot_8u332b09.zip';
                        Vendor = 'Temurin-Hotspot';
                        Version = '8.0.332-9';
                    };
                    Value = ('{0}/Install-JavaSdk-Windows.ps1' -f $localDirectoryPath);
                }
            );
            Paths = @(
                'o/openjdk-temurin/8/OpenJDK8U-jdk_x64_windows_hotspot_8u332b09.zip',
                'p/powershell/scripts/java/Install-JavaSdk-Windows.ps1'
            );
            Type = 'PowerShellScript';
            UpdateEnvironmentVariables = $true;
        },
        # Java 11
        @{
            Commands = @(
                @{
                    Arguments = @{
                        Architecture = 'x64';
                        PackageName = 'OpenJDK11U-jdk_x64_windows_hotspot_11.0.15_10.zip';
                        Vendor = 'Temurin-Hotspot';
                        Version = '11.0.15-10';
                    };
                    Value = ('{0}/Install-JavaSdk-Windows.ps1' -f $localDirectoryPath);
                }
            );
            Paths = @(
                'o/openjdk-temurin/11/OpenJDK11U-jdk_x64_windows_hotspot_11.0.15_10.zip'
            );
            Type = 'PowerShellScript';
            UpdateEnvironmentVariables = $true;
        },
        # Java 17
        @{
            Commands = @(
                @{
                    Arguments = @{
                        Architecture = 'x64';
                        PackageName = 'OpenJDK17U-jdk_x64_windows_hotspot_17.0.3_7.zip';
                        Vendor = 'Temurin-Hotspot';
                        Version = '17.0.3-7';
                    };
                    Value = ('{0}/Install-JavaSdk-Windows.ps1' -f $localDirectoryPath);
                }
            );
            Paths = @(
                'o/openjdk-temurin/17/OpenJDK17U-jdk_x64_windows_hotspot_17.0.3_7.zip'
            );
            Type = 'PowerShellScript';
            UpdateEnvironmentVariables = $true;
        },
        # Node
        @{
            Path = 'n/nodejs/16/node-v16.15.1-x64.msi';
        },
        # PowerShell Az Module
        @{
            Path = 'p/powershell/modules/az/8/Az_8.0.0.zip';
            Type = 'PowerShellModule';
        },
        # PowerShell PackageManagement Module
        @{
            Path = 'p/powershell/modules/packagemanagement/1/PackageManagement_1.4.7.zip';
            Type = 'PowerShellModule';
        },
        # PowerShell SqlServer Module
        @{
            Path = 'p/powershell/modules/sqlserver/20/SqlServer_21.1.18256.zip';
            Type = 'PowerShellModule';
        },
        # .NET 6.0
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'd/dotnet/6/dotnet-sdk-6.0.300-win-x64.exe';
        },
        @{
            Arguments = @('/install', '/norestart', '/quiet');
            Path = 'd/dotnet/6/dotnet-hosting-6.0.5-win.exe';
        },
        @{
            Path = 'p/python/3/python-3.10.5-win32-x64.zip';
            Type = 'CachedTool';
            WorkingDirectory = ('{0}/Python/3.10.5/x64' -f $localDirectoryPath);
        },
        @{
            Commands = @(
                @{
                    Value = {
                        az extension add --name 'azure-devops' --yes;
                        az extension add --name 'dev-spaces' --yes;
                        az extension add --name 'front-door' --yes;
                        az extension add --name 'rdbms-connect' --yes;
                        az extension add --name 'resource-graph' --yes;
                        az extension add --name 'ssh' --yes;
                    }
                }
            );
            Type = 'PowerShellScript-Inline';
        }
    );
}
else {
    throw 'Unsupported Platform';
}

New-Item `
    -Force `
    -Path $localDirectoryPath `
    -Type 'Directory' |
    Out-Null;

$Tasks |
    ForEach-Object {
        $task = $_;

        switch ($task.Type) {
            { @('CachedTool', 'PowerShellModule') -contains $_ } {
                $azureStorageBlobParams = @{
                    AccountName = $AccountName;
                    LocalFilePath = ('{0}/{1}' -f $localDirectoryPath, (Split-Path $task.Path -Leaf));
                    RemoteBlobPath = ('{0}/{1}' -f $BlobContainerName, $task.Path);
                };

                if ($Force) {
                    $azureStorageBlobParams.Force = $true;
                }

                $internalTasks.Add(@{
                    Name = $task.Name;
                    Path = $azureStorageBlobParams.LocalFilePath;
                    Type = $task.Type;
                    UpdateEnvironmentVariables = $task.UpdateEnvironmentVariables;
                    WorkingDirectory = $task.WorkingDirectory;
                });

                Write-Host $task.Path;
                Get-AzureStorageBlob @azureStorageBlobParams | Out-Null;
            }
            { @('Executable', 'PowerShellScript') -contains $_ } {
                $internalTasks.Add(@{
                    Commands = $task.Commands;
                    Type = $task.Type;
                    UpdateEnvironmentVariables = $task.UpdateEnvironmentVariables;
                    WorkingDirectory = $task.WorkingDirectory;
                });

                $task.Paths |
                    ForEach-Object {
                        $azureStorageBlobParams = @{
                            AccountName = $AccountName;
                            LocalFilePath = ('{0}/{1}' -f $localDirectoryPath, (Split-Path $_ -Leaf));
                            RemoteBlobPath = ('{0}/{1}' -f $BlobContainerName, $_);
                        };
                
                        if ($Force) {
                            $azureStorageBlobParams.Force = $true;
                        }
                
                        Write-Host $_;
                        Get-AzureStorageBlob @azureStorageBlobParams | Out-Null;
                    };
            }
            'PowerShellScript-Inline' {
                $internalTasks.Add(@{
                    Commands = $task.Commands;
                    Type = $task.Type;
                    UpdateEnvironmentVariables = $task.UpdateEnvironmentVariables;
                    WorkingDirectory = $task.WorkingDirectory;
                });
            }
            default {
                $azureStorageBlobParams = @{
                    AccountName = $AccountName;
                    LocalFilePath = ('{0}/{1}' -f $localDirectoryPath, (Split-Path $task.Path -Leaf));
                    RemoteBlobPath = ('{0}/{1}' -f $BlobContainerName, $task.Path);
                };

                if ($Force) {
                    $azureStorageBlobParams.Force = $true;
                }

                Write-Host $task.Path;
                $internalTasks.Add(@{
                    Arguments = $task.Arguments;
                    FileInfo = Get-AzureStorageBlob @azureStorageBlobParams;
                    UpdateEnvironmentVariables = $task.UpdateEnvironmentVariables;
                });
            }
        }
    };
$internalTasks |
    ForEach-Object {
        $task = $_;

        switch ($task.Type) {
            'CachedTool' {
                if ($null -ne $task.WorkingDirectory) {
                    New-Item `
                        -Force `
                        -Path $task.WorkingDirectory `
                        -Type 'Directory' |
                        Out-Null;
                    Push-Location -Path $task.WorkingDirectory;
                }

                if ($IsLinux) {
                    Invoke-Expression -Command ('tar -xzf ''{0}''' -f $task.Path);
                    Invoke-Expression -Command 'bash ./setup.sh';
                }
                elseif ($IsWindows) {
                    Expand-Archive `
                        -DestinationPath '.' `
                        -Path $task.Path |
                        Out-Null;
                    Invoke-Expression -Command './setup.ps1';
                }

                if ($null -ne $task.WorkingDirectory) {
                    Pop-Location;
                }
            }
            'Executable' {
                $task.Commands |
                    ForEach-Object {
                        Invoke-Executable `
                            -Arguments $_.Arguments `
                            -FileName $_.Value;
                    };
            }
            'PowerShellModule' {
                Expand-Archive `
                    -DestinationPath $powerShellModulePath `
                    -Path $task.Path |
                    Out-Null;
            }
            'PowerShellScript' {
                $task.Commands |
                    ForEach-Object {
                        $arguments = $_.Arguments;

                        & $_.Value @arguments;
                    };
            }
            'PowerShellScript-Inline' {
                $task.Commands |
                    ForEach-Object {
                        Invoke-Command `
                            -ArgumentList $_.Arguments `
                            -ScriptBlock $_.Value;
                    };
            }
            default {
                $arguments = ([Collections.Generic.List[string]]$task.Arguments);
                $fileInfo = $task.FileInfo;

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
            }
        }

        if ($task.UpdateEnvironmentVariables) {
            Update-EnvironmentVariables;
        }
    };
