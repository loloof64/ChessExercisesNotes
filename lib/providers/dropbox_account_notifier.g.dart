// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropbox_account_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DropboxAccountNotifier)
final dropboxAccountProvider = DropboxAccountNotifierProvider._();

final class DropboxAccountNotifierProvider
    extends $NotifierProvider<DropboxAccountNotifier, DropboxAccount?> {
  DropboxAccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dropboxAccountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dropboxAccountNotifierHash();

  @$internal
  @override
  DropboxAccountNotifier create() => DropboxAccountNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DropboxAccount? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DropboxAccount?>(value),
    );
  }
}

String _$dropboxAccountNotifierHash() =>
    r'd193f81ba480d1d72f4e66b332247293f6b087d1';

abstract class _$DropboxAccountNotifier extends $Notifier<DropboxAccount?> {
  DropboxAccount? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DropboxAccount?, DropboxAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DropboxAccount?, DropboxAccount?>,
              DropboxAccount?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
