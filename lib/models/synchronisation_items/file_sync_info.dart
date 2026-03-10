class FileSyncInfo {
  final String path;
  final bool isDir;
  final DateTime? localModified;
  final DateTime? remoteModified;

  FileSyncInfo({
    required this.path,
    required this.isDir,
    this.localModified,
    this.remoteModified,
  });
}
