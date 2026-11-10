import 'dart:io';

void main() {
  final bytes = File('assets/icons/animal.png').readAsBytesSync();
  // We can write a quick C# script or use System.Drawing to get exact pixel bounding box
  print('Ready to get bounding box');
}
