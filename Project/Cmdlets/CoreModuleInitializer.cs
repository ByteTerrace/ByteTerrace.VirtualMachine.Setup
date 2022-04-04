using System.Management.Automation;
using System.Reflection;
using System.Runtime.Loader;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

public class CoreModuleInitializer : IModuleAssemblyInitializer
{
    private static string BasePath { get; } = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)!, ".."));
    private static string CommonPath { get; } = Path.Combine(BasePath, "Common");

    public void OnImport() {
        AssemblyLoadContext.Default.Resolving += (AssemblyLoadContext assemblyLoadContext, AssemblyName assemblyName) =>
            (assemblyName.Name!.Equals("ByteTerrace.VirtualMachine.Setup.Core", StringComparison.Ordinal) ? DependencyAssemblyLoadContext.GetForDirectory(CommonPath).LoadFromAssemblyName(assemblyName) : null);
    }
}
