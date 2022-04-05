using System.Collections.Concurrent;
using System.Reflection;
using System.Runtime.Loader;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

public class DependencyAssemblyLoadContext : AssemblyLoadContext
{
    private static ConcurrentDictionary<string, DependencyAssemblyLoadContext> DependencyLoadContexts { get; } = new();
    private static string PowerShellHome { get; } = Path.GetDirectoryName(Assembly.GetEntryAssembly()!.Location)!;

    internal static DependencyAssemblyLoadContext GetForDirectory(string directoryPath) {
        return DependencyLoadContexts.GetOrAdd(
            key: directoryPath,
            valueFactory: (path) => new DependencyAssemblyLoadContext(dependencyDirectoryPath: path)
        );
    }

    private string DependencyDirectoryPath { get; }

    public DependencyAssemblyLoadContext(string dependencyDirectoryPath) : base(name: nameof(DependencyAssemblyLoadContext)) {
        DependencyDirectoryPath = dependencyDirectoryPath;
    }

    protected override Assembly Load(AssemblyName assemblyName) {
        var assemblyFileName = $"{assemblyName.Name}.dll";
        var powerShellHomeAssemblyPath = Path.Join(PowerShellHome, assemblyFileName);

        if (File.Exists(powerShellHomeAssemblyPath)) {
            return null!;
        }

        var dependencyAssemblyPath = Path.Join(DependencyDirectoryPath, assemblyFileName);

        return (File.Exists(dependencyAssemblyPath) ? LoadFromAssemblyPath(dependencyAssemblyPath) : null)!;
    }
}
