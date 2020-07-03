import 'package:flutter/cupertino.dart';
import 'package:lucidgoft/common/mobile_mouse_hover_ext.dart'
if (dart.library.html) 'package:lucidgoft/common/web_mouse_hover_ext.dart';

abstract class TextWithUnderline extends Widget{
  factory TextWithUnderline(text,style) => getTextWithUnderline(text,style);
}