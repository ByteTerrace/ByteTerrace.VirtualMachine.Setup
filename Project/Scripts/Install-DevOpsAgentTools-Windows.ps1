$azureStorageAccountName = 'byteterrace';
$devOpsAgentToolsScriptName = 'Install-DevOpsAgentTools-Common.ps1';
$powerShellPackageName = 'PowerShell-7.2.4-win-x64.msi';
$setupModuleName = 'ByteTerrace.VirtualMachine.Setup';
$temporaryPath = [IO.Path]::Combine(([IO.Path]::GetTempPath()), 'bytrc');

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    New-Item `
        -Force `
        -Path $temporaryPath `
        -Type 'Directory';
    Push-Location -Path $temporaryPath;
    Invoke-WebRequest `
        -OutFile $devOpsAgentToolsScriptName `
        -Uri "https://$azureStorageAccountName.blob.core.windows.net/scripts/$devOpsAgentToolsScriptName";
    Invoke-WebRequest `
        -OutFile "$setupModuleName.zip" `
        -Uri "https://$azureStorageAccountName.blob.core.windows.net/binaries/p/powershell/modules/byteterrace/virtual-machine/configuration/1.0.0.zip";
    Invoke-WebRequest `
        -OutFile $powerShellPackageName `
        -Uri "https://$azureStorageAccountName.blob.core.windows.net/binaries/p/powershell/7/$powerShellPackageName";
    Expand-Archive `
        -Destination '.' `
        -Path "$setupModuleName.zip";
    Start-Process `
        -ArgumentList @(
            '/i',
            (Get-Item -Path "$temporaryPath/$powerShellPackageName").FullName,
            '/norestart',
            '/qn'
        ) `
        -FilePath 'msiexec' `
        -Wait;
    & (Get-Item -Path "${Env:ProgramFiles}/PowerShell/7/pwsh.exe").FullName -Command "&{ Import-Module './$setupModuleName'; } && & './$devOpsAgentToolsScriptName' -AccountName '$azureStorageAccountName' -Force -TemporaryPath '$temporaryPath';";
}
finally {
    Pop-Location;
}

if (Test-Path -Path $temporaryPath) {
    Remove-Item `
        -Force `
        -Path $temporaryPath `
        -Recurse;
}
