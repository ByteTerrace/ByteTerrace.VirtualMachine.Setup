using Azure.Core;
using Azure.Storage.Blobs;

namespace ByteTerrace.VirtualMachine.Setup.Core;

/// <summary>
/// 
/// </summary>
public static class AzureStorageAccountUtilities
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="cancellationToken"></param>
    /// <param name="fileMode"></param>
    /// <param name="sourceUri"></param>
    /// <param name="targetFile"></param>
    /// <param name="tokenCredential"></param>
    [CLSCompliant(isCompliant: false)]
    public static FileInfo DownloadBlob(
        Uri sourceUri,
        FileInfo targetFile,
        TokenCredential tokenCredential,
        FileMode fileMode = FileMode.CreateNew,
        CancellationToken cancellationToken = default
    ) {
        BlobClient blobClient;

        if (tokenCredential is null) {
            blobClient = new BlobClient(
                blobUri: sourceUri,
                options: default
            );
        }
        else {
            blobClient = new BlobClient(
                blobUri: sourceUri,
                credential: tokenCredential,
                options: default
            );
        }

        using var fileStream = targetFile.Open(
            access: FileAccess.Write,
            mode: fileMode,
            share: FileShare.Read
        );
        using var clientResponse = blobClient.DownloadTo(
            cancellationToken: cancellationToken,
            destination: fileStream
        );

        return targetFile;
    }
}
