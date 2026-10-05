import 'dart:math';

/// Fast, collision-resistant unique ID generator without heavy external dependencies.
class IdGenerator {
  static final _random = Random.secure();

  static String generate() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand1 = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final rand2 = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$now-$rand1-$rand2';
  }

  static String uuid() => generate();
}
