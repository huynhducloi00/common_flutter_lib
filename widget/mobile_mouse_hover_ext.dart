import 'package:flutter/material.dart';

import 'common.dart';
extension HoverExtension on Widget{
  Widget get showCursorOnHover {
    return this;
  }
}
class TextWithUnderlineMobile extends StatelessWidget implements TextWithUnderline {
  String text;
  TextStyle style;
  TextWithUnderlineMobile(this.text, this.style);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: style,);
  }
}
TextWithUnderline getTextWithUnderline(text, style)=> TextWithUnderlineMobile(text, style);
