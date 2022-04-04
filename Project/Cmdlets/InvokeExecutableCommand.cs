using System.Diagnostics;
using System.Management.Automation;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

/// <summary>
/// 
/// </summary>
[Cmdlet(VerbsLifecycle.Invoke, "Executable")]
[OutputType(typeof(int))]
public class InvokeExecutableCommand : Cmdlet
{
    private ProcessStartInfo ProcessStartInfo { get; }

    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 1,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string[]? Arguments { get; set; }
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 2,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public Dictionary<string, string?>? EnvironmentVariables { get; set; }
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
    [Parameter(
        Mandatory = false,
        Position = 3,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public int TimeoutInMilliseconds { get; set; } = int.MaxValue;
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 4,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string WorkingDirectory { get; set; } = string.Empty;

    public InvokeExecutableCommand() {
        ProcessStartInfo = new ProcessStartInfo {
            FileName = string.Empty,
            RedirectStandardError = false,
            RedirectStandardInput = false,
            RedirectStandardOutput = false,
            StandardErrorEncoding = default,
            StandardInputEncoding = default,
            StandardOutputEncoding = default,
            UseShellExecute = false,
            WorkingDirectory = string.Empty,
        };
    }

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
        var processStartInfo = ProcessStartInfo;

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

        processStartInfo.FileName = FileName;
        processStartInfo.WorkingDirectory = WorkingDirectory;
    }
    /// <summary>
    /// 
    /// </summary>
    protected override void ProcessRecord() {
        using var process = Process.Start(startInfo: ProcessStartInfo);

        try {
            if (process is null) {
                throw new InvalidOperationException(message: "Process start returned null; unable to continue.");
            }

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
            target: (process ?? ((object)this))
        )) { }
        finally { }
    }
}
