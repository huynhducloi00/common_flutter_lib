import 'package:canxe/common/data/cloud_table.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_table/edit_table_wrapper.dart';
import 'edit_table/parent_param.dart';
import 'mobile_hover_button.dart' if (dart.library.html) 'web_hover_button.dart'
    as hover_button;
import 'mobile_mouse_hover_ext.dart'
    if (dart.library.html) 'web_mouse_hover_ext.dart';

abstract class TextWithUnderline extends Widget {
  factory TextWithUnderline(text, style) => getTextWithUnderline(text, style);
}

class LoiButtonStyle {
  Color regularColor, hoverColor, textColor, iconColor, disabledColor;

  LoiButtonStyle(
      {this.regularColor,
      this.hoverColor,
      this.textColor,
      this.iconColor,
      this.disabledColor});
}

Route createMaterialPageRoute(parentContext, WidgetBuilder builder) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Provider.value(
          value: Provider.of<LoiButtonStyle>(parentContext, listen: false),
          child: builder(context));
    },
    transitionDuration: Duration(seconds: 0),
  );
//    MaterialPageRoute( builder: (context) {
//    return Provider.value(
//        value: Provider.of<LoiButtonStyle>(parentContext, listen: false),
//        child: builder(context));
//  });
}

abstract class CommonButton {
  static Widget createOpenButton(context,CloudTableSchema table, title, icon) {
    return CommonButton.getOpenButton(
        context,
        EditTableWrapper(table, ParentParam(
            sortKey: 'date',
            sortKeyDescending: true,
            filterDataWrappers: {
        })),
        title,
        icon);
  }

  static Widget getOpenButton(context, Widget page, title, iconData,
      {regularColor, hoverColor}) {
    return getButton(context, () {
      Navigator.push(
        context,
        createMaterialPageRoute(
            context, (_) => Scaffold(appBar: AppBar(title: Text(title),), body: page)),
      );
    },
        title: title,
        iconData: iconData,
        regularColor: regularColor,
        hoverColor: hoverColor);
  }

  static Widget getCloseButton(context, String title) {
    return getButton(context, () {
      Navigator.of(context).pop();
    }, title: title);
  }

  static Widget getButtonAsync(
      BuildContext buildContext, Future Function() onPressedFuture,
      {bool isEnabled = true,
      String title,
      TextAlign align = TextAlign.start,
      IconData iconData,
      Color regularColor,
      Color hoverColor,
      Color textColor,
      Color iconColor,
      Color disabledColor,
      bool isDense = false}) {
    assert(title != null || iconData != null);
    var style = Provider.of<LoiButtonStyle>(buildContext, listen: false);
    regularColor = regularColor ?? style.regularColor;
    hoverColor = hoverColor ?? style.hoverColor;
    textColor = textColor ?? style.textColor;
    iconColor = iconColor ?? style.iconColor;
    disabledColor = disabledColor ?? style.disabledColor;
    String titleChanging = title;
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        final onPressedChanging = () async {
          titleChanging = (title ?? '') + "...";
          setState(() {});
          //this is Async
          await onPressedFuture();
          titleChanging = title;
          setState(() {});
        };
        if (isEnabled) {
          return getButton(buildContext, onPressedChanging,
              title: titleChanging,
              align: align,
              iconData: iconData,
              regularColor: regularColor,
              hoverColor: hoverColor,
              textColor: textColor,
              iconColor: iconColor,
              isDense: isDense);
        }
        return getButton(buildContext, null,
            title: titleChanging,
            align: align,
            iconData: iconData,
            regularColor: disabledColor,
            hoverColor: disabledColor,
            textColor: textColor,
            iconColor: iconColor,
            isDense: isDense);
      },
    );
  }

  static Widget getButton(BuildContext buildContext, Function onPressed,
      {String title,
      TextAlign align = TextAlign.start,
      IconData iconData,
      Color regularColor,
      Color hoverColor,
      Color textColor,
      Color iconColor,
      Color disabledColor,
      bool isEnabled = true,
      bool isDense = false}) {
    var style = Provider.of<LoiButtonStyle>(buildContext, listen: false);
    regularColor = regularColor ?? style.regularColor;
    hoverColor = hoverColor ?? style.hoverColor;
    textColor = textColor ?? style.textColor;
    iconColor = iconColor ?? style.iconColor;
    disabledColor = disabledColor ?? style.disabledColor;
    if (isEnabled) {
      return hover_button.createButton(onPressed,
          title: title,
          align: align,
          iconData: iconData,
          regularColor: regularColor,
          hoverColor: hoverColor,
          textColor: textColor,
          iconColor: iconColor,
          isDense: isDense);
    }
    return hover_button.createButton(null,
        title: title,
        align: align,
        iconData: iconData,
        regularColor: disabledColor,
        hoverColor: disabledColor,
        textColor: textColor,
        iconColor: iconColor,
        isDense: isDense);
  }
}
