import '../utils.dart';

import '../data/cloud_table.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'edit_table/common_child_table.dart';
import 'edit_table/edit_table_wrapper.dart';
import 'edit_table/parent_param.dart';
import 'mobile_hover_button.dart' if (dart.library.html) 'web_hover_button.dart'
    as hover_button;
import 'mobile_mouse_hover_ext.dart'
    if (dart.library.html) 'web_mouse_hover_ext.dart';

abstract class TextWithUnderline extends Widget {
  factory TextWithUnderline(text, style) => getTextWithUnderline(text, style);
}

typedef DialogReturnedValue = void Function(
    dynamic val, Map<String, dynamic>? allData);

class LoiButtonStyle {
  Color? regularColor, hoverColor, textColor, iconColor, disabledColor;

  LoiButtonStyle(
      {this.regularColor,
      this.hoverColor,
      this.textColor,
      this.iconColor,
      this.disabledColor});
}

abstract class CommonButton {
  static Widget createDataListWidget(
      context,
      CloudTableSchema table,
  {Map<String, FilterDataWrapper>? filter,
      PostColorDecorationCondition? postColorDecorationCondition}) {
    return EditTableWrapper(
        table,
        ParentParam(sortKey: table.sortKey,
            sortKeyDescending: table.sortDescending,
            postColorDecorationCondition: postColorDecorationCondition,
            filterDataWrappers: filter));
  }

  static Widget createOpenButton(context, CloudTableSchema table, title,
      {IconData? icon,
      Map<String, FilterDataWrapper>? filter,
      PostColorDecorationCondition? postColorDecorationCondition,
      bool isDense = false}) {
    return CommonButton.getOpenButton(
        context,
        createDataListWidget(
            context, table,filter: filter,
        postColorDecorationCondition: postColorDecorationCondition),
        title,
        icon,
        isDense: isDense);
  }

  static Widget getOpenButton(context, Widget page, title, iconData,
      {regularColor, hoverColor, bool isDense = false}) {
    return getButton(context, () {
      Navigator.push(
        context,
        createMaterialPageRoute(
            context,
            (_) => Scaffold(
                appBar: AppBar(
                  title: Row(children: [
                    Icon(iconData),
                    SizedBox(
                      width: 20,
                    ),
                    Text(title)
                  ]),
                ),
                body: page)),
      );
    },
        title: title,
        iconData: iconData,
        isDense: isDense,
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
      String? title,
      TextAlign align = TextAlign.start,
      IconData? iconData,
      Color? regularColor,
      Color? hoverColor,
      Color? textColor,
      Color? iconColor,
      Color? disabledColor,
      bool isDense = false}) {
    assert(title != null || iconData != null);
    var style = getLoiButtonStyle(buildContext);
    regularColor = regularColor ?? style.regularColor;
    hoverColor = hoverColor ?? style.hoverColor;
    textColor = textColor ?? style.textColor;
    iconColor = iconColor ?? style.iconColor;
    disabledColor = disabledColor ?? style.disabledColor;
    String? titleChanging = title;
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

  static Widget getButton(BuildContext buildContext, Function? onPressed,
      {String? title,
      TextAlign align = TextAlign.start,
      IconData? iconData,
      Color? regularColor,
      Color? hoverColor,
      Color? textColor,
      Color? iconColor,
      Color? disabledColor,
      bool isEnabled = true,
      bool isDense = false}) {
    var style = getLoiButtonStyle(buildContext);
    regularColor = regularColor ?? style.regularColor;
    hoverColor = hoverColor ?? style.hoverColor;
    textColor = textColor ?? style.textColor;
    iconColor = iconColor ?? style.iconColor;
    disabledColor = disabledColor ?? style.disabledColor;
    if (isEnabled) {
      return (hover_button.HoverButtonImpl()).createButton(onPressed!,
          title: title,
          align: align,
          iconData: iconData,
          regularColor: regularColor,
          hoverColor: hoverColor,
          textColor: textColor,
          iconColor: iconColor,
          isDense: isDense);
    }
    return (hover_button.HoverButtonImpl()).createButton(null,
        title: title,
        align: align,
        iconData: iconData,
        regularColor: disabledColor,
        hoverColor: disabledColor,
        textColor: textColor,
        iconColor: iconColor,
        isDense: isDense);
  }

  static Widget createDataPickerButton(context, CloudTableSchema? table,
      String selectedField, DialogReturnedValue dialogReturnedValue,
      {String? title, IconData? iconData, bool isDense=false}) {
    return CommonButton.getButtonAsync(context, () async {
      var results = await Navigator.push(
          context,
          createMaterialPageRoute(context, (context) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                    'Chọn một ${table!.inputInfoMap.map![selectedField]?.fieldDes ?? ''}'),
              ),
              body: EditTableWrapper(
                table,
                ParentParam(
                  sortKey: table.inputInfoMap.map!.keys.first,
                  sortKeyDescending: true,
                ),
                dataPickerBundle: DataPickerBundle(selectedField),
              ),
            );
          }));
      if (results != null)
        dialogReturnedValue(results[0], /* full list= */ results[1]);
    }, title: title, iconData: iconData, isDense: isDense);
  }
}

class CloudTableUtils {
  static Widget listAllCloudTable(context, List<CloudTableSchema> tables,
      {isTwoColumns = true,
      isDense = true,
      CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    List buttons = tables
        .map((table) => CommonButton.createOpenButton(
            context, table, table.tableDescription,
            icon: table.iconData, isDense: isDense))
        .toList();
    if (isTwoColumns) {
      return splitAnyColumns(buttons as List<Widget>, 2);
    }
    return columnWithGap(buttons as List<Widget>, crossAxisAlignment: crossAxisAlignment);
  }
}
