import 'package:flutter/material.dart';
extension HoverExtension on Widget{
  Widget get showCursorOnHover {
    return this;
  }
}
class TextWithUnderline extends StatelessWidget {
  String text;
  TextStyle style;
  TextWithUnderline(this.text, this.style);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: style,);
  }
}
