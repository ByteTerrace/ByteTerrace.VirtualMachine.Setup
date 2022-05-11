#!/bin/sh
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y autoremove && \
azureStorageAccountName='byteterrace' && \
devOpsAgentToolsScriptName='Install-DevOpsAgentTools-Common.ps1' && \
powerShellPackageName='powershell-lts_7.2.3-1.deb_amd64.deb' && \
setupModuleName='ByteTerrace.VirtualMachine.Setup' && \
temporaryPath='/tmp/bytrc' && \
mkdir -p $temporaryPath && \
cd $temporaryPath && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/binaries/PowerShell/Modules/1/ByteTerrace.VirtualMachine.Setup/$setupModuleName.zip" && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/binaries/p/powershell/7/$powerShellPackageName" && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/scripts/$devOpsAgentToolsScriptName" && \
dpkg --install "./$powerShellPackageName" && \
unzip "$temporaryPath/$setupModuleName.zip" && \
pwsh -Command "&{ Import-Module './$setupModuleName'; } && & './$devOpsAgentToolsScriptName' -AccountName '$azureStorageAccountName' -Force -TemporaryPath '$temporaryPath';";
