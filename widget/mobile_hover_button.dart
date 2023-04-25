import '../utils.dart';
import 'hover_button_interface.dart';
import 'package:flutter/material.dart';

class HoverButtonImpl extends HoverButtonInterface {
  @override
  Widget createButton(Function? onPressed,
      {String? title,
      TextAlign align = TextAlign.start,
      IconData? iconData,
      Color? regularColor,
      Color? hoverColor,
      Color? textColor = Colors.white,
      Color? iconColor = Colors.black,
      bool isDense = false}) {
    var isTitleEmpty = isStringEmpty(title);
    bool showEmptyPlaceHolder = isTitleEmpty && iconData == null;
    if (iconData != null && isTitleEmpty || showEmptyPlaceHolder) {
      return TextButton(
        child: Icon(
          iconData,
          color: iconColor,
        ),
        style: TextButton.styleFrom(
          backgroundColor: regularColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onPressed as void Function()?,
      );
    } else {
      return TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: regularColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onPressed as void Function()?,
        label:
            Text(title!, style: TextStyle(color: textColor), textAlign: align),
        icon: Icon(
          iconData,
          color: iconColor,
        ),
      );
    }
  }
}
