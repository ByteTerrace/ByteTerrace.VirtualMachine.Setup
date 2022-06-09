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
    "Component.Dotfuscator",
    "Microsoft.Component.ClickOnce.MSBuild",
    "Microsoft.Component.MSBuild",
    "Microsoft.Component.NetFX.Native",
    "Microsoft.Net.Component.4.8.SDK",
    "Microsoft.Net.Component.4.8.TargetingPack",
    "Microsoft.Net.ComponentGroup.DevelopmentPrerequisites",
    "Microsoft.Net.ComponentGroup.TargetingPacks.Common",
    "Microsoft.Net.ComponentGroup.4.8.DeveloperTools",
    "Microsoft.Net.Core.Component.SDK.2.1",
    "microsoft.net.runtime.mono.tooling",
    "microsoft.net.sdk.emscripten",
    "Microsoft.NetCore.Component.Runtime.3.1",
    "Microsoft.NetCore.Component.Runtime.5.0",
    "Microsoft.NetCore.Component.Runtime.6.0",
    "Microsoft.NetCore.Component.SDK",
    "Microsoft.VisualStudio.Component.Azure.AuthoringTools",
    "Microsoft.VisualStudio.Component.Azure.ClientLibs",
    "Microsoft.VisualStudio.Component.Azure.Waverton.BuildTools",
    "Microsoft.VisualStudio.Component.CoreBuildTools",
    "Microsoft.VisualStudio.Component.DockerTools.BuildTools",
    "Microsoft.VisualStudio.Component.FSharp.MSBuild",
    "Microsoft.VisualStudio.Component.Node.Build",
    "Microsoft.VisualStudio.Component.NuGet",
    "Microsoft.VisualStudio.Component.NuGet.BuildTools",
    "Microsoft.VisualStudio.Component.Roslyn.Compiler",
    "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
    "Microsoft.VisualStudio.Component.SQL.SSDTBuildSku",
    "Microsoft.VisualStudio.Component.TestTools.BuildTools",
    "Microsoft.VisualStudio.Component.TextTemplating",
    "Microsoft.VisualStudio.Component.TypeScript.SDK.4.6",
    "Microsoft.VisualStudio.Component.TypeScript.TSServer",
    "Microsoft.VisualStudio.Component.WebDeploy",
    "Microsoft.VisualStudio.Wcf.BuildTools.ComponentGroup",
    "Microsoft.VisualStudio.Web.BuildTools.ComponentGroup",
    "Microsoft.VisualStudio.Workload.AzureBuildTools",
    "Microsoft.VisualStudio.Workload.DataBuildTools",
    "Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools",
    "Microsoft.VisualStudio.Workload.MSBuildTools",
    "Microsoft.VisualStudio.Workload.NodeBuildTools",
    "Microsoft.VisualStudio.Workload.WebBuildTools",
    "wasm.tools"
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
