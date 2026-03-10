class DropboxAccount {
  final String displayName;
  final String email;
  final String accountId;
  final String? profilePhotoUrl;

  const DropboxAccount({
    required this.displayName,
    required this.email,
    required this.accountId,
    required this.profilePhotoUrl,
  });
}
