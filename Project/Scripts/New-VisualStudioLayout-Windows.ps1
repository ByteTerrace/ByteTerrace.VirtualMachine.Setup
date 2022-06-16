<#
    Reference:
        https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2022
        https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-enterprise?view=vs-2022
        https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-professional?view=vs-2022
 #>
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
    "Microsoft.Net.Component.4.8.SDK",
    "Microsoft.Net.Component.4.8.TargetingPack",
    "Microsoft.Net.ComponentGroup.DevelopmentPrerequisites",
    "Microsoft.Net.ComponentGroup.TargetingPacks.Common",
    "Microsoft.Net.ComponentGroup.4.8.DeveloperTools",
    "microsoft.net.sdk.emscripten",
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
    "Component.Dotfuscator",
    "Microsoft.Component.Azure.DataLake.Tools",
    "Microsoft.Component.CodeAnalysis.SDK",
    "Microsoft.Net.Component.4.7.TargetingPack",
    "Microsoft.Net.Component.4.7.2.TargetingPack",
    "Microsoft.Net.Component.4.8.TargetingPack",
    "Microsoft.VisualStudio.Component.AspNet45",
    "Microsoft.VisualStudio.Component.Azure.ResourceManager.Tools",
    "Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools",
    "Microsoft.VisualStudio.Component.Debugger.JustInTime",
    "Microsoft.VisualStudio.Component.DslTools",
    "Microsoft.VisualStudio.Component.EntityFramework",
    "Microsoft.VisualStudio.Component.LinqToSql",
    "Microsoft.VisualStudio.Component.PortableLibrary",
    "Microsoft.VisualStudio.Component.Sharepoint.Tools",
    "Microsoft.VisualStudio.Component.SQL.SSDT",
    "Microsoft.VisualStudio.Component.TeamOffice",
    "Microsoft.VisualStudio.Component.TeamsFx",
    "Microsoft.VisualStudio.Component.TestTools.CodedUITest",
    "Microsoft.VisualStudio.Component.TestTools.WebLoadTest",
    "Microsoft.VisualStudio.Component.Workflow",
    "Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices",
    "Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools",
    "Microsoft.VisualStudio.ComponentGroup.Web.CloudTools",
    "Microsoft.VisualStudio.Workload.Azure",
    "Microsoft.VisualStudio.Workload.Data",
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NetWeb",
    "Microsoft.VisualStudio.Workload.Node",
    "Microsoft.VisualStudio.Workload.Office",
    "Microsoft.VisualStudio.Workload.Python",
    "Microsoft.VisualStudio.Workload.VisualStudioExtension",
    "wasm.tools"
);
$professionalIds = @(
    "Component.Dotfuscator",
    "Microsoft.Component.Azure.DataLake.Tools",
    "Microsoft.Component.CodeAnalysis.SDK",
    "Microsoft.Net.Component.4.7.TargetingPack",
    "Microsoft.Net.Component.4.7.2.TargetingPack",
    "Microsoft.Net.Component.4.8.TargetingPack",
    "Microsoft.VisualStudio.Component.AspNet45",
    "Microsoft.VisualStudio.Component.Azure.ResourceManager.Tools",
    "Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools",
    "Microsoft.VisualStudio.Component.Debugger.JustInTime",
    "Microsoft.VisualStudio.Component.DslTools",
    "Microsoft.VisualStudio.Component.EntityFramework",
    "Microsoft.VisualStudio.Component.LinqToSql",
    "Microsoft.VisualStudio.Component.PortableLibrary",
    "Microsoft.VisualStudio.Component.Sharepoint.Tools",
    "Microsoft.VisualStudio.Component.SQL.SSDT",
    "Microsoft.VisualStudio.Component.TeamOffice",
    "Microsoft.VisualStudio.Component.TeamsFx",
    "Microsoft.VisualStudio.Component.Workflow",
    "Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices",
    "Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools",
    "Microsoft.VisualStudio.ComponentGroup.Web.CloudTools",
    "Microsoft.VisualStudio.Workload.Azure",
    "Microsoft.VisualStudio.Workload.Data",
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NetWeb",
    "Microsoft.VisualStudio.Workload.Node",
    "Microsoft.VisualStudio.Workload.Office",
    "Microsoft.VisualStudio.Workload.Python",
    "Microsoft.VisualStudio.Workload.VisualStudioExtension",
    "wasm.tools"
);
$workloadIds = ([string[]]@());

switch ($Edition) {
    'BuildTools' { $workloadIds = $buildToolIds; }
    'Enterprise' { $workloadIds = $enterpriseIds; }
    'Professional' { $workloadIds = $professionalIds; }
}

$installerArguments = ('--add "{0}" --addProductLang "{2}" --layout "{1}" --useLatestInstaller' -f ($workloadIds -Join '" --add "'), [IO.Path]::GetFullPath($DestinationPath), $LanguageLocale).Split(' ');
$installerCommand = Get-Command -Name ('./vs_{0}_{1}.exe' -f $Edition, $Version);

& $installerCommand $installerArguments;
