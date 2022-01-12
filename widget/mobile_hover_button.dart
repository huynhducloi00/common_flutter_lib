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
    bool showEmptyPlaceHolder = isStringEmpty(title) && iconData == null;
    return FlatButton(
      disabledColor: regularColor,
      color: regularColor,
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(10.0)),
      padding: EdgeInsets.all(isDense ? 0 : 8),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget?>[
            iconData != null || showEmptyPlaceHolder
                ? Icon(
                    iconData,
                    color: iconColor,
                  )
                : null,
            (iconData != null && !isStringEmpty(title))
                ? SizedBox(
                    width: 20,
                  )
                : null,
            isStringEmpty(title)
                ? null
                : Text(title!,
                    style: TextStyle(color: textColor), textAlign: align),
          ].whereType<Widget>().toList(),
        ),
      ),
      onPressed: onPressed as void Function()?,
    );
  }
}
