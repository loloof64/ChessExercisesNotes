// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropbox_login_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DropboxLogin)
final dropboxLoginProvider = DropboxLoginProvider._();

final class DropboxLoginProvider
    extends $AsyncNotifierProvider<DropboxLogin, AccessTokenResponse?> {
  DropboxLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dropboxLoginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dropboxLoginHash();

  @$internal
  @override
  DropboxLogin create() => DropboxLogin();
}

String _$dropboxLoginHash() => r'a67b58b4f1134479b702854dce582cfaf2b44aae';

abstract class _$DropboxLogin extends $AsyncNotifier<AccessTokenResponse?> {
  FutureOr<AccessTokenResponse?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AccessTokenResponse?>, AccessTokenResponse?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AccessTokenResponse?>,
                AccessTokenResponse?
              >,
              AsyncValue<AccessTokenResponse?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
