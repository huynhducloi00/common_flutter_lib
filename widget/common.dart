import 'package:flutter/cupertino.dart';

import 'mobile_hover_button.dart'
    if (dart.library.html) 'web_hover_button.dart';
import 'mobile_mouse_hover_ext.dart'
    if (dart.library.html) 'web_mouse_hover_ext.dart';

abstract class TextWithUnderline extends Widget {
  factory TextWithUnderline(text, style) => getTextWithUnderline(text, style);
}

abstract class CommonButton {
  static Widget getCommonButton(Function onPressed,
          {String title,
          TextAlign align = TextAlign.start,
          IconData iconData,
          Color regularColor,
          Color hoverColor,
          Color textColor}) =>
      createButton(onPressed,
          title: title,
          align: align,
          iconData: iconData,
          regularColor: regularColor,
          hoverColor: hoverColor,
          textColor: textColor);
}
