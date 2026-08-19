import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/utils/media_compressor.dart';

void main() {
  group('MediaCompressor Tests', () {
    test('compressImageBytes returns original bytes if size is less than 150 KB', () async {
      // 100 bytes (well below 150 KB limit)
      final bytes = Uint8List.fromList(List<int>.generate(100, (i) => i));

      final result = await MediaCompressor.compressImageBytes(bytes);

      expect(result, equals(bytes));
    });

    test('compressImageBytes fails gracefully to return original bytes on native error', () async {
      // 200 KB (above 150 KB threshold, will trigger FlutterImageCompress call)
      final bytes = Uint8List.fromList(List<int>.generate(200 * 1024, (i) => i % 256));

      // Native FlutterImageCompress will fail in tests (MissingPluginException), 
      // but it should catch and return the fallback bytes.
      final result = await MediaCompressor.compressImageBytes(bytes);

      expect(result, equals(bytes));
    });

    test('compressImageFile returns original file if file size is less than 150 KB', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/small_image.png');
      tempFile.writeAsBytesSync(List<int>.generate(1000, (i) => i % 256)); // ~1 KB

      final result = await MediaCompressor.compressImageFile(tempFile);

      expect(result.path, equals(tempFile.path));
      expect(result.lengthSync(), equals(1000));

      tempDir.deleteSync(recursive: true);
    });

    test('compressImageFile fails gracefully on native error', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/large_image.png');
      tempFile.writeAsBytesSync(List<int>.generate(200 * 1024, (i) => i % 256)); // 200 KB

      final result = await MediaCompressor.compressImageFile(tempFile);

      // Should return original file as fallback on exception
      expect(result.path, equals(tempFile.path));

      tempDir.deleteSync(recursive: true);
    });
  });
}
