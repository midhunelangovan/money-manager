
import 'kals_storage_platform_interface.dart';

class KalsStorage {
  Future<String?> getPlatformVersion() {
    return KalsStoragePlatform.instance.getPlatformVersion();
  }
}
