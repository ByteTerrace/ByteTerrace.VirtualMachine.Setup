param(
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = 'Debug'
);

$netCore = 'net6.0';
$outPath = "$PSScriptRoot/bin/ByteTerrace.VirtualMachine.Setup";
$commonPath = "$outPath/Common";
$mainPath = "$outPath/Main";

if (Test-Path $outPath) {
    Remove-Item -Path $outPath -Recurse;
}

New-Item -Path $outPath -ItemType Directory;
New-Item -Path $commonPath -ItemType Directory;
New-Item -Path $mainPath -ItemType Directory;
Push-Location "$PSScriptRoot/Core";

try {
    dotnet publish -f $netCore;
}
finally {
    Pop-Location;
}

Push-Location "$PSScriptRoot/Cmdlets";

try {
    dotnet publish -f $netCore;
}
finally {
    Pop-Location;
}

$commonFiles = [System.Collections.Generic.HashSet[string]]::new();
Copy-Item -Path "$PSScriptRoot/ByteTerrace.VirtualMachine.Setup.psd1" -Destination $outPath;
Get-ChildItem -Path "$PSScriptRoot/Core/bin/$Configuration/$netCore/publish" |
    Where-Object { $_.Extension -in '.dll','.pdb' } |
    ForEach-Object { [void]$commonFiles.Add($_.Name); Copy-Item -LiteralPath $_.FullName -Destination $commonPath };
Get-ChildItem -Path "$PSScriptRoot/Cmdlets/bin/$Configuration/$netCore/publish" |
    Where-Object { $_.Extension -in '.dll','.pdb' -and -not $commonFiles.Contains($_.Name) } |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $mainPath };
