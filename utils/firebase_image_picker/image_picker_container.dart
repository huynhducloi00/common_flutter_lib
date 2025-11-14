import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../utils.dart';
import '../../widget/common.dart';
import '../image_compression/luban.dart';

const double imageMaxHeight = 500;
const int imageQuality = 75;

class ImageCombo {
  File? cameraFile;
  Uint8List? byteArray;
  double storageSize;
  String? imageLink;
  String? originalImageLink;
  bool needUploadToFirebase;
  static FirebaseStorage firestore = FirebaseStorage.instance;

  static ImageCombo fromImageLink(link) {
    return ImageCombo(imageLink: link, originalImageLink: link);
  }

  ImageCombo({
    this.cameraFile,
    this.byteArray,
    this.storageSize = 0,
    this.imageLink,
    this.originalImageLink,
    this.needUploadToFirebase = false,
  });

  ImageCombo resetToBefore() {
    return ImageCombo(
        cameraFile: null,
        storageSize: 0,
        imageLink: originalImageLink,
        originalImageLink: originalImageLink,
        needUploadToFirebase: false);
  }

  ImageCombo clearOriginalImage() {
    return ImageCombo(
        cameraFile: null,
        storageSize: 0,
        imageLink: null,
        originalImageLink: originalImageLink,
        needUploadToFirebase: false);
  }

  ImageCombo takeCameraPicture(File xFile, length) {
    return ImageCombo(
        cameraFile: xFile,
        storageSize: length,
        imageLink: null,
        originalImageLink: originalImageLink,
        needUploadToFirebase: true);
  }

  deduceFromBytes(Uint8List result) {
    return ImageCombo(
        byteArray: result,
        storageSize: result.length / 1024.0,
        imageLink: null,
        originalImageLink: originalImageLink,
        needUploadToFirebase: true);
  }

  upload(ImageValueNotifier notifier) async {
    var refPath = '';
    if (originalImageLink == null) {
      // create new
      refPath = DateTime.now().toString();
      originalImageLink = refPath;
      imageLink = refPath;
    } else {
      refPath = originalImageLink!;
    }
    if (byteArray != null) {
      firestore.ref().putData(byteArray!);
    } else if (cameraFile != null) {
      if (kIsWeb) {
        firestore.ref().putData(await cameraFile!.readAsBytes());
      } else {
        firestore.ref().child(refPath).putFile(File(cameraFile!.path));
      }
    }

    needUploadToFirebase = false;
    notifier.notifyListeners();
  }

  compressImage() async {
    CompressObject compressObject = CompressObject(
      bytes: byteArray!,
      //compress to path
      quality: 85,
      //first compress quality, default 80
      step: 9,
      //compress quality step, The bigger the fast, Smaller is more accurate, default 6
      mode: CompressMode.LARGE2SMALL, //default AUTO
    );
    var result = await Luban.compressImage(compressObject);
    return deduceFromBytes(Uint8List.fromList(result));
  }
}

class ImageValueNotifier extends ValueNotifier<ImageCombo> {
  ImageValueNotifier(ImageCombo value) : super(value);
}

class ImageValuePicker extends StatefulWidget {
  const ImageValuePicker({Key? key}) : super(key: key);

  @override
  _ImageValuePickerState createState() => _ImageValuePickerState();
}

class _ImageValuePickerState extends State<ImageValuePicker> {
  // File _image;
  late ImagePicker imagePicker;
  late ImageValueNotifier _imageValueNotifier;

  @override
  void initState() {
    imagePicker = ImagePicker();
    super.initState();
  }

  Future getImageFromCamera(ImageValueNotifier imageValueNotifier) async {
    var xFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: imageMaxHeight,
      imageQuality: imageQuality, //compress later
    );
    if (xFile == null) return;
    var bytes = await xFile.readAsBytes();
    imageValueNotifier.value =
        await imageValueNotifier.value.deduceFromBytes(bytes);
  }

  getFileSize(File? file) async {
    if (file == null) return 0;
    final bytes = await file.length();
    return bytes / 1024;
  }

  getFileSizeWidget(double size) {
    return Text("File size: ${size.toStringAsFixed(2)} KB");
  }

  Completer<ui.Image> getDimensionCompleter(Image image) {
    Completer<ui.Image> completer = Completer<ui.Image>();
    image.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }));
    return completer;
  }

  Future<List<Widget>> getImageAndFileSize(ImageCombo imageCombo) async {
    Widget image = Container(color: Colors.red);
    Widget fileSize = getFileSizeWidget(0);
    final fit = BoxFit.contain;
    if (imageCombo.byteArray != null) {
      image = Image.memory(
        imageCombo.byteArray!,
        fit: fit,
      );
      fileSize = getFileSizeWidget(imageCombo.storageSize);
    } else if (imageCombo.cameraFile != null) {
      image = kIsWeb
          ? Image.network(
              imageCombo.cameraFile!.path,
              fit: fit,
            )
          : Image.file(
              File(imageCombo.cameraFile!.path),
              fit: fit,
            );
      fileSize = getFileSizeWidget(imageCombo.storageSize);
    } else if (imageCombo.imageLink != null) {
      var link = await ImageCombo.firestore
          .ref()
          .child(imageCombo.imageLink!)
          .getDownloadURL();
      image = Image.network(link, fit: fit, loadingBuilder:
          (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      });
      var metaData = await ImageCombo.firestore
          .ref()
          .child(imageCombo.imageLink!)
          .getMetadata();
      fileSize = getFileSizeWidget(metaData.size! / 1024.0);
    }
    return [image, fileSize];
  }

  loiDartFunc(context, data) async {
    if (!mounted) {
      return;
    }
    var result = base64Decode(data.split(",").last);
    _imageValueNotifier.value =
        await _imageValueNotifier.value.deduceFromBytes(result);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // jsutil.JsUtilImpl().bindCall(loiDartFunc);
    }
    return Consumer<ImageValueNotifier>(
        builder: (BuildContext context, imageValueNotifier, Widget? child) {
      _imageValueNotifier = imageValueNotifier;
      var imageCombo = imageValueNotifier.value;
      return FutureBuilder<List<Widget>>(
          future: getImageAndFileSize(imageCombo),
          builder:
              (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              var res = snapshot.data!;
              var image = res[0];
              var fileSize = res[1];

              // return ImagePick
              return Column(
                  children: [
                (imageCombo.originalImageLink == null
                    ? null
                    : Text(
                        'File name: ${imageCombo.originalImageLink!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                SizedBox(
                    height: 200,
                    width: 200,
                    child: Padding(
                        padding: EdgeInsets.all(10),
                        child: InkWell(
                            onTap: () {
                              if (image is Image)
                                showFullSizeImage(context, image);
                            },
                            child: image))),
                Wrap(
                    spacing: 20,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CommonButton.getButtonAsync(context, () async {
                        await getImageFromCamera(imageValueNotifier);
                      },
                          title: 'Take picture',
                          iconData: Icons.picture_in_picture_alt),
                      CommonButton.getButton(context, () {
                        imageValueNotifier.value =
                            imageCombo.clearOriginalImage();
                      }, title: 'Clear', iconData: Icons.clean_hands),
                      CommonButton.getButtonAsync(context, () async {
                        imageValueNotifier.value =
                            await imageValueNotifier.value.compressImage();
                      }, title: 'Compress', iconData: Icons.compress),
                      CommonButton.getButton(context, () {
                        imageValueNotifier.value = imageCombo.resetToBefore();
                      }, title: 'Reset', iconData: Icons.reset_tv),
                      CommonButton.getButtonAsync(context, () async {
                        return await imageValueNotifier.value
                            .upload(_imageValueNotifier);
                      },
                          title: 'Upload',
                          iconData: Icons.cloud_upload,
                          isEnabled: imageCombo.needUploadToFirebase &&
                              (imageCombo.byteArray != null ||
                                  imageCombo.cameraFile != null)),
                    ]),
                fileSize,
                (image is Image)
                    ? FutureBuilder<ui.Image>(
                        future: getDimensionCompleter(image).future,
                        builder: (BuildContext context,
                            AsyncSnapshot<ui.Image> snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                                'Dimension: ${snapshot.data!.width}x${snapshot.data!.height}');
                          }
                          return Center(child: CircularProgressIndicator());
                        },
                      )
                    : null,
              ].whereType<Widget>().toList());
            } else {
              return Center(child: CircularProgressIndicator());
            }
          });
    });
  }
}
