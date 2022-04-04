using System.Collections.Concurrent;
using System.Reflection;
using System.Runtime.Loader;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

public class DependencyAssemblyLoadContext : AssemblyLoadContext
{
    private static ConcurrentDictionary<string, DependencyAssemblyLoadContext> DependencyLoadContexts { get; } = new();
    private static string PowerShellHome { get; } = Path.GetDirectoryName(Assembly.GetEntryAssembly()!.Location)!;

    internal static DependencyAssemblyLoadContext GetForDirectory(string directoryPath) {
        return DependencyLoadContexts.GetOrAdd(directoryPath, (path) => new DependencyAssemblyLoadContext(path));
    }

    private readonly string m_dependencyDirectoryPath;

    public DependencyAssemblyLoadContext(string dependencyDirPath) : base(nameof(DependencyAssemblyLoadContext)) {
        m_dependencyDirectoryPath = dependencyDirPath;
    }

    protected override Assembly Load(AssemblyName assemblyName) {
        var assemblyFileName = $"{assemblyName.Name}.dll";
        var dependencyAssemblyPath = Path.Join(m_dependencyDirectoryPath, assemblyFileName);

        return (File.Exists(dependencyAssemblyPath) ? LoadFromAssemblyPath(dependencyAssemblyPath) : null)!;
    }
}
