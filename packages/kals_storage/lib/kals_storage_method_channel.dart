import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kals_storage_platform_interface.dart';

/// An implementation of [KalsStoragePlatform] that uses method channels.
class MethodChannelKalsStorage extends KalsStoragePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kals_storage');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
