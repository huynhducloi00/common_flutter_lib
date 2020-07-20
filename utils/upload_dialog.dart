import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';

class UploadDialog extends StatefulWidget {
  @override
  _UploadDialogState createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  File _image;

  Future takePicture() async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.camera);
      setState(() {
        _image = image;
      });
    } on PlatformException catch (e) {
      Toast.show(e.toString(), context);
    }
  }

  Future openFile() async {
    try {
      var image = await FilePicker.getFile(type: FileType.image);
      setState(() {
        _image = image;
      });
    } on PlatformException catch (e) {
      Toast.show(e.toString(), context);
    }
  }

  final Color buttonColor = Colors.lightGreen;
  final double buttonFontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 5),
        color: Colors.brown[50],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircleAvatar(
                radius: 30,
                backgroundColor: buttonColor,
                child: IconButton(
                  icon: Icon(Icons.add_a_photo),
                  color: Colors.white,
                  onPressed: () {
                    takePicture();
                  },
                )),
            CircleAvatar(
                radius: 30,
                backgroundColor: buttonColor,
                child: IconButton(
                  icon: Icon(
                    Icons.file_upload,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    openFile();
                  },
                )),
          ],
        ),
      ),
      body: Container(
        color: Colors.red[50],
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _image == null
                  ? Text(
                      'No image selected.',
                      style: TextStyle(fontSize: buttonFontSize),
                    )
                  : Image.file(
                      _image,
                      fit: BoxFit.contain,
                    ),
            ]),
      ),
    );
  }
}
