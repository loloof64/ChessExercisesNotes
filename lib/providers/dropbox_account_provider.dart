import 'package:chess_exercises_notes/models/synchronisation_items/dropbox_account.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dropbox_account_provider.g.dart';

@Riverpod(keepAlive: true)
class DropboxAccountState extends _$DropboxAccountState {
  @override
  DropboxAccount? build() {
    return null;
  }

  void setAccount(DropboxAccount account) {
    state = account;
  }

  void clear() {
    state = null;
  }
}
