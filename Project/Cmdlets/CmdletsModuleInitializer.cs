using System.Management.Automation;
using System.Reflection;
using System.Runtime.Loader;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

/// <summary>
/// 
/// </summary>
public sealed class CmdletsModuleInitializer : IModuleAssemblyInitializer
{
    private static string BasePath { get; } = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)!, ".."));
    private static string CommonPath { get; } = Path.Combine(BasePath, "Common");
    private static Dictionary<string, Version> Dependencies { get; } = new Dictionary<string, Version> {
        { "Azure.Core", new Version("1.24.0.0") },
        { "Azure.Identity", new Version("1.6.0.0") },
        { "ByteTerrace.VirtualMachine.Setup.Core", new Version("1.0.0.0") },
    };

    /// <summary>
    /// 
    /// </summary>
    public void OnImport() {
        AssemblyLoadContext.Default.Resolving += (AssemblyLoadContext assemblyLoadContext, AssemblyName assemblyName) => (
            (
                Dependencies.TryGetValue(
                    key: assemblyName.Name!,
                    value: out var version
                )
                && (version >= assemblyName.Version)
            )
            ? DependencyAssemblyLoadContext
                .GetForDirectory(directoryPath: CommonPath)
                .LoadFromAssemblyName(assemblyName: assemblyName)
            : null
        );
    }
}
