// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropbox_account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DropboxAccountState)
final dropboxAccountStateProvider = DropboxAccountStateProvider._();

final class DropboxAccountStateProvider
    extends $NotifierProvider<DropboxAccountState, DropboxAccount?> {
  DropboxAccountStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dropboxAccountStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dropboxAccountStateHash();

  @$internal
  @override
  DropboxAccountState create() => DropboxAccountState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DropboxAccount? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DropboxAccount?>(value),
    );
  }
}

String _$dropboxAccountStateHash() =>
    r'c9f00f1db97aa574f1359e3921cc23725a2bfc26';

abstract class _$DropboxAccountState extends $Notifier<DropboxAccount?> {
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
