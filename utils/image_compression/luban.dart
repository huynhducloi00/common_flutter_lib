import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class ResultWrapper {
  List<int>? finalImage;

  ResultWrapper(this.finalImage);
}

class Luban {
  Luban._();

  static Future<List<int>> compressImage(CompressObject object) async {
    return compute(_lubanCompress, object);
  }

  static Future<dynamic> compressImageQueue(CompressObject object) async {
    final response = ReceivePort();
    await Isolate.spawn(_lubanCompressQueue, response.sendPort);
    final sendPort = await response.first;
    final answer = ReceivePort();
    sendPort.send([answer.sendPort, object]);
    return answer.first;
  }

  static Future<List<String?>> compressImageList(
      List<CompressObject> objects) async {
    return compute(_lubanCompressList, objects);
  }

  static void _lubanCompressQueue(SendPort port) {
    final rPort = ReceivePort();
    port.send(rPort.sendPort);
    rPort.listen((message) {
      final send = message[0] as SendPort;
      final object = message[1] as CompressObject;
      send.send(_lubanCompress(object));
    });
  }

  static List<String?> _lubanCompressList(List<CompressObject> objects) {
    var results = [];
    objects.forEach((_o) {
      results.add(_lubanCompress(_o));
    });
    return results as List<String?>;
  }

  static bool _parseType(String path, List<String> suffix) {
    bool _result = false;
    for (int i = 0; i < suffix.length; i++) {
      if (path.endsWith(suffix[i])) {
        _result = true;
        break;
      }
    }
    return _result;
  }

  static List<int> _lubanCompress(CompressObject object) {
    Image image = decodeImage(object.bytes)!;
    var smallerImage;
    if (image.width < 500) {
      smallerImage = image;
    } else {
      smallerImage = copyResize(image, height: 500);
    }
    return encodeJpg(smallerImage, quality: object.quality);
  }

  static _large2SmallCompressImage({
    required Image image,
    required ResultWrapper resultWrapper,
    quality,
    targetSize,
    step,
    bool isJpg = true,
  }) {
    if (isJpg) {
      var im = encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 > targetSize && quality > step) {
        quality -= step;
        _large2SmallCompressImage(
          image: image,
          resultWrapper: resultWrapper,
          quality: quality,
          targetSize: targetSize,
          step: step,
        );
        return;
      }
      print('quality cuoi $quality');
      resultWrapper.finalImage = im;
    } else {
      _compressPng(
        image: image,
        targetSize: targetSize,
        large2Small: true,
      );
    }
  }

  static _small2LargeCompressImage({
    required Image image,
    required ResultWrapper resultWrapper,
    quality,
    targetSize,
    step,
    bool isJpg = true,
  }) {
    if (isJpg) {
      var im = encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 < targetSize && quality <= 100) {
        quality += step;
        _small2LargeCompressImage(
          image: image,
          resultWrapper: resultWrapper,
          quality: quality,
          targetSize: targetSize,
          step: step,
          isJpg: isJpg,
        );
        return;
      }
      resultWrapper.finalImage = im;
    } else {
      _compressPng(
        image: image,
        targetSize: targetSize,
        large2Small: false,
      );
    }
  }

  ///level 1~9  level++ -> image--
  static void _compressPng({
    required Image image,
    File? file,
    level,
    targetSize,
    required bool large2Small,
  }) {
    var _level;
    if (large2Small) {
      _level = level ?? 1;
    } else {
      _level = level ?? 9;
    }
    List<int> im = encodePng(image, level: _level);
    if (_level > 9 || _level < 1) {
    } else {
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 > targetSize) {
        _compressPng(
          image: image,
          file: file,
          targetSize: targetSize,
          level: large2Small ? _level + 1 : _level - 1,
          large2Small: large2Small,
        );
        return;
      }
    }

    file!.writeAsBytesSync(im);
  }
}

enum CompressMode {
  SMALL2LARGE,
  LARGE2SMALL,
  AUTO,
}

class CompressObject {
  final Uint8List bytes;
  final String? outputPath;
  final CompressMode mode;
  final int quality;
  final int step;

  ///If you are not sure whether the image detail property is correct, set true, otherwise the compressed ratio may be incorrect
  final bool autoRatio;

  CompressObject({
    required this.bytes,
    this.outputPath,
    this.mode = CompressMode.AUTO,
    this.quality = 80,
    this.step = 6,
    this.autoRatio = true,
  });
}
