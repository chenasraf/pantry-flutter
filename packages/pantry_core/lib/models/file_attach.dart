/// How a file picked from the account's Nextcloud files becomes an image.
enum FileAttachMode {
  /// Point at the file itself, wherever it is moved or renamed.
  link,

  /// Copy it into Pantry's image folder.
  import;

  static FileAttachMode parse(Object? raw) =>
      raw == 'import' ? FileAttachMode.import : FileAttachMode.link;
}

/// An image picked from the account's Nextcloud files, and how to attach it.
class NextcloudImagePick {
  final int fileId;
  final String name;
  final FileAttachMode mode;

  const NextcloudImagePick({
    required this.fileId,
    required this.name,
    required this.mode,
  });
}
