#!/bin/sh
apt-get -y update && \
apt-get -y upgrade && \
apt-get -y autoremove && \
azureStorageAccountName='byteterrace' && \
temporaryPath='/tmp/bytrc' && \
mkdir -p $temporaryPath && \
cd $temporaryPath && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/binaries/PowerShell/Modules/1/ByteTerrace.VirtualMachine.Setup/ByteTerrace.VirtualMachine.Setup.zip" && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/binaries/p/powershell/7/powershell-lts_7.2.2-1.deb_amd64.deb" && \
curl -O "https://$azureStorageAccountName.blob.core.windows.net/scripts/Install-DevOpsAgentTools-Common.ps1" && \
dpkg --install './powershell-lts_7.2.2-1.deb_amd64.deb' && \
unzip "$temporaryPath/ByteTerrace.VirtualMachine.Setup.zip" && \
pwsh -Command "&{ Import-Module './ByteTerrace.VirtualMachine.Setup'; } && & './Install-DevOpsAgentTools-Common.ps1' -AccountName '$azureStorageAccountName' -Force -TemporaryPath '$temporaryPath';";
