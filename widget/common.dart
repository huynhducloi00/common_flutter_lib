import 'package:flutter/cupertino.dart';
import 'mobile_mouse_hover_ext.dart'
if (dart.library.html) 'web_mouse_hover_ext.dart';

abstract class TextWithUnderline extends Widget{
  factory TextWithUnderline(text,style) => getTextWithUnderline(text,style);
}