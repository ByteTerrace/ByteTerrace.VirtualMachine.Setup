using Azure.Core;
using Azure.Storage.Blobs;

namespace ByteTerrace.VirtualMachine.Setup.Core;

public static class AzureStorageAccountUtilities
{
    [CLSCompliant(isCompliant: false)]
    public static FileInfo DownloadBlob(
        Uri sourceUri,
        FileInfo targetFile,
        TokenCredential tokenCredential,
        CancellationToken cancellationToken = default
    ) {
        var blobClient = new BlobClient(
            blobUri: sourceUri,
            credential: tokenCredential,
            options: default
        );
        using var fileStream = targetFile.Open(
            access: FileAccess.Write,
            mode: FileMode.CreateNew,
            share: FileShare.Read
        );
        using var clientResponse = blobClient.DownloadTo(
            cancellationToken: cancellationToken,
            destination: fileStream
        );

        return targetFile;
    }
}
