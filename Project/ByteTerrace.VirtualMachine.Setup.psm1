$dependencyPath = (Join-Path $PSScriptRoot -ChildPath 'Common');
$modulePath = (Join-Path $PSScriptRoot 'Main/ByteTerrace.VirtualMachine.Setup.Cmdlets.dll');
$null = Import-Module -Name $modulePath;

if (Test-Path $dependencyPath -ErrorAction Stop) {
    Get-ChildItem `
        -ErrorAction Stop `
        -Filter '*.dll' `
        -Path $dependencyPath |
    ForEach-Object {
        Add-Type `
            -ErrorAction Stop `
            -Path $_.FullName |
        Out-Null;
    };
}
