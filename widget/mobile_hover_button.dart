import 'package:canxe/common/widget/hover_button_interface.dart';
import 'package:canxe/constants.dart';
import 'package:flutter/material.dart';

class HoverButtonImpl extends HoverButtonInterface {
  @override
  Widget createButton(Function onPressed,
      {String title,
      TextAlign align = TextAlign.start,
      IconData iconData,
      Color regularColor,
      Color hoverColor,
      Color textColor = Colors.white,
      Color iconColor = Colors.black,
      bool isDense = false}) {
    assert(title != null || iconData != null);
    return FlatButton(
      disabledColor: regularColor,
      color: regularColor,
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(10.0)),
      padding: EdgeInsets.all(isDense ? 0 : 8),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              iconData,
              color: iconColor,
            ),
            isStringEmpty(title)
                ? null
                : Text(title,
                    style: TextStyle(color: textColor), textAlign: align),
          ].where((element) => element != null).toList(),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
