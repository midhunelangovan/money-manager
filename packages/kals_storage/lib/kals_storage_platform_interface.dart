import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kals_storage_method_channel.dart';

abstract class KalsStoragePlatform extends PlatformInterface {
  /// Constructs a KalsStoragePlatform.
  KalsStoragePlatform() : super(token: _token);

  static final Object _token = Object();

  static KalsStoragePlatform _instance = MethodChannelKalsStorage();

  /// The default instance of [KalsStoragePlatform] to use.
  ///
  /// Defaults to [MethodChannelKalsStorage].
  static KalsStoragePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KalsStoragePlatform] when
  /// they register themselves.
  static set instance(KalsStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
