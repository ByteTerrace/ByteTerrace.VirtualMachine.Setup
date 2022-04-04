using Azure.Core;
using Azure.Identity;
using ByteTerrace.VirtualMachine.Setup.Core;
using System.Management.Automation;

namespace ByteTerrace.VirtualMachine.Setup.Cmdlets;

[Cmdlet(VerbsCommon.Get, "Blob")]
[OutputType(typeof(FileInfo))]
public class GetBlobCommand : Cmdlet, IDisposable
{
    private CancellationTokenSource? CancellationTokenSource { get; set; }
    private bool IsDisposed { get; set; }

    [Parameter(
        Mandatory = false,
        Position = 2,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? LocalFilePath { get; set; }
    [Parameter(
        Mandatory = true,
        Position = 1,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? RemoteBlobPath { get; set; }
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string? StorageAccountName { get; set; }
    [Parameter(
        Mandatory = false,
        Position = 3,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public int? TimeoutInMilliseconds { get; set; }
    [Parameter(
        Mandatory = false,
        Position = 4,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public TokenCredential? TokenCredential { get; set; }

    public GetBlobCommand() {
        CancellationTokenSource = new();
        IsDisposed = false;
    }

    protected override void BeginProcessing() {
        if (TokenCredential is null) {
            TokenCredential = new DefaultAzureCredential();
        }
    }
    protected virtual void Dispose(bool disposing) {
        if (!IsDisposed) {
            if (disposing) {
                var cancellationTokenSource = CancellationTokenSource;

                if (cancellationTokenSource is not null) {
                    cancellationTokenSource.Dispose();
                }

                CancellationTokenSource = null;
            }

            IsDisposed = true;
        }
    }
    protected override void ProcessRecord() {
        if (LocalFilePath is null) {
            LocalFilePath = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        }

        CancellationToken cancellationToken;

        if (CancellationTokenSource is not null) {
            if (TimeoutInMilliseconds is not null) {
                CancellationTokenSource.CancelAfter(millisecondsDelay: TimeoutInMilliseconds.Value);
            }

            cancellationToken = CancellationTokenSource.Token;
        }
        else {
            cancellationToken = default;
        }

        WriteObject(
            sendToPipeline: AzureStorageAccountUtilities.DownloadBlob(
                cancellationToken: cancellationToken,
                sourceUri: new Uri($"https://{StorageAccountName}.blob.core.windows.net/{RemoteBlobPath}"),
                targetFile: new FileInfo(fileName: LocalFilePath),
                tokenCredential: TokenCredential!
            )
        );
    }

    public void Dispose() {
        Dispose(disposing: true);
        GC.SuppressFinalize(obj: this);
    }
}
