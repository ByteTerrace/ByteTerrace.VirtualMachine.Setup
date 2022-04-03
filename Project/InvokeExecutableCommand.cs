using System.Diagnostics;
using System.Management.Automation;

namespace ByteTerrace.VirtualMachine.Setup;

/// <summary>
/// 
/// </summary>
[Cmdlet(VerbsLifecycle.Invoke, "Executable")]
[OutputType(typeof(int))]
public class InvokeExecutableCommand : Cmdlet
{
    private ProcessStartInfo? m_processStartInfo;

    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 1,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
#pragma warning disable CA1819 // Properties should not return arrays
    public string[]? Arguments { get; set; }
#pragma warning restore CA1819 // Properties should not return arrays
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
            Mandatory = false,
            Position = 2,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
#pragma warning disable CA2227 // Collection properties should be read only
    public Dictionary<string, string>? EnvironmentVariables { get; set; }
#pragma warning restore CA2227 // Collection properties should be read only
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? FileName { get; set; }
    /// <summary>
    /// 
    /// </summary>
    public int TimeoutInMilliseconds { get; set; } = int.MaxValue;

    private bool LogException(ErrorCategory category, Exception exception, string id, object target) {
        WriteError(errorRecord: new ErrorRecord(
            exception: exception,
            errorCategory: category,
            errorId: id,
            targetObject: target
        ));

        return false;
    }

    /// <summary>
    /// 
    /// </summary>
    protected override void BeginProcessing() {
        if (FileName is null) {
            throw new ArgumentNullException(paramName: nameof(FileName));
        }

        var processStartInfo = new ProcessStartInfo(fileName: FileName) {
            RedirectStandardError = false,
            RedirectStandardInput = false,
            RedirectStandardOutput = false,
            StandardErrorEncoding = default,
            StandardInputEncoding = default,
            StandardOutputEncoding = default,
            UseShellExecute = false,
            WorkingDirectory = string.Empty,
        };

        if (Arguments is not null) {
            var argumentList = processStartInfo.ArgumentList;

            foreach (var argument in Arguments) {
                argumentList.Add(item: argument);
            }
        }

        if (EnvironmentVariables is not null) {
            var environmentVariables = processStartInfo.Environment;

            foreach (var variable in EnvironmentVariables) {
                environmentVariables.Add(item: variable);
            }
        }

        m_processStartInfo = processStartInfo;
    }
    /// <summary>
    /// 
    /// </summary>
    protected override void ProcessRecord() {
        using var process = Process.Start(startInfo: m_processStartInfo);

        try {
            if (process.WaitForExit(milliseconds: TimeoutInMilliseconds)) {
                WriteObject(sendToPipeline: process.ExitCode);
            }
            else if (!process.HasExited) {
                process.Kill();

                throw new OperationCanceledException(message: "The process did not exit gracefully, or exceeded its allotted time, and was forced to stop.");
            }
        }
        catch (Exception e)
        when (LogException(
            category: ErrorCategory.NotSpecified,
            exception: e,
            id: "UnhandledException",
            target: process
        )) { }
        finally { }
    }
}
