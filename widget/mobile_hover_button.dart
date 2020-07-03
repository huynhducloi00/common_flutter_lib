import 'package:flutter/material.dart';
Widget createButton(Function onPressed,
    {String title,TextAlign align=TextAlign.start, IconData iconData,  Color regularColor, Color hoverColor, Color textColor}) {
  assert(title != null || iconData != null);
  if (title == null) {
    return Container(
      color: regularColor,
      width: 24,
      child: IconButton(
        iconSize: 24,
        padding: EdgeInsets.all(0),
        icon: Icon(iconData),
        onPressed: onPressed,
      ),
    );
  }
  return Container(
    color: regularColor,
    child: FlatButton(
      child: Row(
        children: <Widget>[
          iconData == null ? null : Icon(iconData),
          title == null ? null : Text(title, textAlign: align,),
        ].where((element) => element != null).toList(),
      ),
      onPressed: onPressed,
    ),
  );
}