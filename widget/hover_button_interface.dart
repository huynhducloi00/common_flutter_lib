import 'package:flutter/material.dart';
abstract class HoverButtonInterface{
  Widget createButton(Function onPressed,
      {String title,
        TextAlign align = TextAlign.start,
        IconData iconData,
        Color regularColor,
        Color hoverColor,
        Color textColor = Colors.white,
        Color iconColor = Colors.black,
        bool isDense = false});
}