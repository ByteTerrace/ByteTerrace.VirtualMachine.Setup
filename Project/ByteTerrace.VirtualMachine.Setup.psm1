$dependencyPath = (Join-Path $PSScriptRoot -ChildPath 'Common');
$modulePath = (Join-Path $PSScriptRoot 'Main/ByteTerrace.VirtualMachine.Setup.Cmdlets.dll');
$null = Import-Module -Name $modulePath;

if (Test-Path $dependencyPath -ErrorAction Ignore) {
    try {
        Get-ChildItem -ErrorAction Stop -Path $dependencyPath -Filter '*.dll' | ForEach-Object {
            try {
                Add-Type -Path $_.FullName -ErrorAction Ignore | Out-Null
            }
            catch {
                Write-Verbose $_
            }
        }
    }
    catch {}
}
