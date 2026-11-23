import 'package:flutter_test/flutter_test.dart';
import 'package:kals_storage/kals_storage.dart';
import 'package:kals_storage/kals_storage_platform_interface.dart';
import 'package:kals_storage/kals_storage_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKalsStoragePlatform
    with MockPlatformInterfaceMixin
    implements KalsStoragePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KalsStoragePlatform initialPlatform = KalsStoragePlatform.instance;

  test('$MethodChannelKalsStorage is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKalsStorage>());
  });

  test('getPlatformVersion', () async {
    KalsStorage kalsStoragePlugin = KalsStorage();
    MockKalsStoragePlatform fakePlatform = MockKalsStoragePlatform();
    KalsStoragePlatform.instance = fakePlatform;

    expect(await kalsStoragePlugin.getPlatformVersion(), '42');
  });
}
