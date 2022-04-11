using Azure.Core;
using Azure.Identity;
using ByteTerrace.VirtualMachine.Setup.Core;
using System.Management.Automation;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

/// <summary>
/// 
/// </summary>
[Cmdlet(VerbsCommon.Get, "AzureStorageBlob")]
[OutputType(typeof(FileInfo))]
public class GetAzureStorageBlobCommand : Cmdlet, IDisposable
{
    private CancellationTokenSource CancellationTokenSource { get; set; }
    private bool IsDisposed { get; set; }

    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? AccountName { get; set; }
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 2,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? LocalFilePath { get; set; }
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = true,
        Position = 1,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? RemoteBlobPath { get; set; }
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 3,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public int? TimeoutInMilliseconds { get; set; }
    /// <summary>
    /// 
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 4,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public TokenCredential? TokenCredential { get; set; }

    /// <summary>
    /// 
    /// </summary>
    public GetAzureStorageBlobCommand() {
        CancellationTokenSource = new();
        IsDisposed = false;
    }

    /// <summary>
    /// 
    /// </summary>
    protected override void BeginProcessing() {
        if (TimeoutInMilliseconds is not null) {
            CancellationTokenSource.CancelAfter(millisecondsDelay: TimeoutInMilliseconds.Value);
        }

        if (TokenCredential is null) {
            TokenCredential = new DefaultAzureCredential();
        }
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="disposing"></param>
    protected virtual void Dispose(bool disposing) {
        if (!IsDisposed) {
            if (disposing) {
                CancellationTokenSource.Dispose();
            }

            IsDisposed = true;
        }
    }
    /// <summary>
    /// 
    /// </summary>
    protected override void ProcessRecord() {
        if (LocalFilePath is null) {
            LocalFilePath = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        }

        WriteObject(
            sendToPipeline: AzureStorageAccountUtilities.DownloadBlob(
                cancellationToken: CancellationTokenSource.Token,
                sourceUri: new Uri($"https://{AccountName}.blob.core.windows.net/{RemoteBlobPath}"),
                targetFile: new FileInfo(fileName: LocalFilePath),
                tokenCredential: TokenCredential!
            )
        );
    }

    /// <summary>
    /// 
    /// </summary>
    public void Dispose() {
        Dispose(disposing: true);
        GC.SuppressFinalize(obj: this);
    }
}
