param(
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = 'Release',
    [ValidateSet('net6.0', 'net7.0')]
    [string]
    $Framework = 'net6.0',
    [string]
    $ModuleName = 'ByteTerrace.VirtualMachine.Setup',
    [ValidateSet('Detailed', 'Diagnostic', 'Minimal', 'Normal', 'Quiet')]
    [string]
    $Verbosity = 'Minimal'
);

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;

function Invoke-DotNetPublish(
    [string] $configuration,
    [string] $framework,
    [string] $workingDirectory
) {
    Push-Location -Path $workingDirectory;

    try {
        dotnet restore `
            --verbosity $Verbosity;

        Test-LastExitCode;

        dotnet build `
            --configuration $Configuration `
            --framework $Framework `
            --nologo `
            --no-dependencies `
            --no-restore `
            --verbosity $Verbosity;

        Test-LastExitCode;

        dotnet publish `
            --configuration $Configuration `
            --framework $Framework `
            --nologo `
            --no-build `
            --no-restore `
            --verbosity $Verbosity;

        Test-LastExitCode;
    }
    finally {
        Pop-Location;
    }
}
function Test-LastExitCode {
    [CmdletBinding()]
    param();

    process {
        if (0 -ne $LASTEXITCODE) {
            Write-Error 'Something happened =(.';
        }
    }
}

$binariesPath = "$PSScriptRoot/bin/$ModuleName";
$cmdletsProjectPath = "$PSScriptRoot/Cmdlets";
$commonPath = "$binariesPath/Common";
$coreProjectPath = "$PSScriptRoot/Core";
$mainPath = "$binariesPath/Main";
$processedPaths = [Collections.Generic.HashSet[string]]::new();

if (Test-Path -Path $binariesPath) {
    Remove-Item `
        -Path $binariesPath `
        -Recurse;
}

New-Item `
    -ItemType 'Directory' `
    -Path $binariesPath;
New-Item `
    -ItemType 'Directory' `
    -Path $commonPath;
New-Item `
    -ItemType 'Directory' `
    -Path $mainPath;

Invoke-DotNetPublish `
    -Configuration $Configuration `
    -Framework $Framework `
    -WorkingDirectory $coreProjectPath;
Invoke-DotNetPublish `
    -Configuration $Configuration `
    -Framework $Framework `
    -WorkingDirectory $cmdletsProjectPath;
Copy-Item `
    -Destination $binariesPath `
    -Path "$PSScriptRoot/$ModuleName.psd1";
Get-ChildItem `
    -Path "$coreProjectPath/bin/$Configuration/$Framework/publish" |
    Where-Object { ($_.Extension -in @('.dll', '.pdb')) } |
    ForEach-Object {
        [void]$processedPaths.Add($_.Name);
        Copy-Item `
            -Destination $commonPath `
            -LiteralPath $_.FullName;
    };
Get-ChildItem `
    -Path "$cmdletsProjectPath/bin/$Configuration/$Framework/publish" |
    Where-Object { (($_.Extension -in @('.dll', '.pdb')) -and (-not $processedPaths.Contains($_.Name))) } |
    ForEach-Object {
        Copy-Item `
            -Destination $mainPath `
            -LiteralPath $_.FullName;
    };
