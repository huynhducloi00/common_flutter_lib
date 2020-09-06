import 'package:flutter/material.dart';
Widget createButton(Function onPressed,
    {String title,TextAlign align=TextAlign.start, IconData iconData,  Color regularColor,
      Color hoverColor, Color textColor, Color iconColor, bool isDense=false}) {
  assert(title != null || iconData != null);
  if (title == null) {
    return Container(
      color: regularColor,
      child: IconButton(
        padding: EdgeInsets.all(isDense ? 0 :8),
        iconSize: 24,
        icon: Icon(iconData, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
  return Container(
    color: regularColor,
    child: FlatButton(
      padding: EdgeInsets.all(isDense ? 0 :8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconData == null ? null : Icon(iconData, color: iconColor,),
          title == null ? null :Text(title,style:TextStyle(color: textColor), textAlign: align),
        ].where((element) => element != null).toList(),
      ),
      onPressed: onPressed,
    ),
  );
}