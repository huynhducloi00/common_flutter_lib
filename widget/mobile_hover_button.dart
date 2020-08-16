import 'package:flutter/material.dart';
Widget createButton(Function onPressed,
    {String title,TextAlign align=TextAlign.start, IconData iconData,  Color regularColor,
      Color hoverColor, Color textColor, Color iconColor, bool isDense=false}) {
  assert(title != null || iconData != null);
  if (title == null) {
    return Container(
      color: regularColor,
      child: IconButton(
        iconSize: 24,
        padding: EdgeInsets.all(0),
        icon: Icon(iconData, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
  return Container(
    color: regularColor,
    child: FlatButton(
      child: Row(
        children: <Widget>[
          iconData == null ? null : Icon(iconData, color: iconColor,),
          title == null ? null :Text(title,style:TextStyle(color: textColor), textAlign: align),
        ].where((element) => element != null).toList(),
      ),
      onPressed: onPressed,
    ),
  );
}