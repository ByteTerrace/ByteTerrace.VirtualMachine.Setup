[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,
    [Parameter(Mandatory = $true)]
    [ValidateSet('BuildTools', 'Enterprise', 'Professional')]
    [string]$Edition,
    [Parameter(Mandatory = $false)]
    [string]$LanguageLocale = 'en-US',
    [Parameter(Mandatory = $false)]
    [string]$Version = '17.2.3'
);

$buildToolIds = @(
    "Microsoft.VisualStudio.Workload.AzureBuildTools",
    "Microsoft.VisualStudio.Workload.DataBuildTools",
    "Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools",
    "Microsoft.VisualStudio.Workload.MSBuildTools",
    "Microsoft.VisualStudio.Workload.NodeBuildTools",
    "Microsoft.VisualStudio.Workload.WebBuildTools"
);
$enterpriseIds = @(
    "Microsoft.VisualStudio.Workload.Azure",
    "Microsoft.VisualStudio.Workload.CoreEditor",
    "Microsoft.VisualStudio.Workload.Data",
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NetCrossPlat",
    "Microsoft.VisualStudio.Workload.NetWeb",
    "Microsoft.VisualStudio.Workload.Node"
);
$professionalIds = @(
    "Microsoft.VisualStudio.Workload.Azure",
    "Microsoft.VisualStudio.Workload.CoreEditor",
    "Microsoft.VisualStudio.Workload.Data",
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NetCrossPlat",
    "Microsoft.VisualStudio.Workload.NetWeb",
    "Microsoft.VisualStudio.Workload.Node"
);
[string[]]$workloadIds = @();

switch ($Edition) {
    'BuildTools' { $workloadIds = $buildToolIds }
    'Enterprise' { $workloadIds = $enterpriseIds }
    'Professional' { $workloadIds = $professionalIds }
}

$installerArguments = ('--add "{0}" --addProductLang "{2}" --layout "{1}" --useLatestInstaller' -f ($workloadIds -Join '" --add "'), [IO.Path]::GetFullPath($DestinationPath), $LanguageLocale).Split(' ');
$installerCommand = Get-Command -Name ('./vs_{0}_{1}.exe' -f $Edition, $Version);

& $installerCommand $installerArguments;
