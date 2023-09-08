import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart' as res_builder;

import 'auth/auth_service.dart';
import 'data/cloud_obj.dart';
import 'data/cloud_table.dart';
import 'widget/common.dart';
import 'widget/edit_table/parent_param.dart';
/// abc

final NumberFormat NUM_FORMAT = NumberFormat("#,###");
final TABLE_OF_TWO_DIVIDER = "TABLE_OF_TWO_DIVIDER";

final TextStyle BIG_FONT = TextStyle(fontSize: 18);
final TextStyle MEDIUM_FONT = TextStyle(fontSize: 14);

const EDIT_TABLE_HORIZONTAL_BORDER_SIDE =
    BorderSide(width: 1, color: Colors.brown, style: BorderStyle.solid);

class LoiAllCloudTables {
  static late List<CloudTableSchema> cloudTables;
  static late Map<String?, CloudTableSchema> maps;

  static void init(List<CloudTableSchema> list) {
    cloudTables = list;
    maps = list.asMap().map((_, value) => MapEntry(value.tableName, value));
  }

  static CloudTableSchema<T> getValueInMap<T extends CloudObject>(
      String cloudTableName) {
    return maps[cloudTableName]! as CloudTableSchema<T>;
  }
}

class TableWidthAndSize {
  double? width;
  Map<int, TableColumnWidth>? colWidths;

  TableWidthAndSize({this.width, this.colWidths});
}

TableWidthAndSize getEditTableColWidths(
    context, Map<String, InputInfo> inputInfoMap) {
  int numDevide = inputInfoMap.keys.length <= 7 ? inputInfoMap.keys.length : 7;
  double standardColWidth = screenWidth(context) / numDevide;
  Map<int, TableColumnWidth> colWidths = Map();
  int index = 0;
  double sumWidth = 0;
  inputInfoMap.forEach((fieldName, inputInfo) {
    double width = inputInfo.displayFlex! * standardColWidth;
    sumWidth += width;
    colWidths[index] = FixedColumnWidth(width);
    index++;
  });
  return TableWidthAndSize(width: sumWidth, colWidths: colWidths);
}

String formatDateOnly(context, DateTime dt) {
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  return localizations.formatCompactDate(dt);
}

/// ----- [Start] old format for phieu can by car, ...
///
String formatDatetime(context, DateTime? dateTime) {
  if (dateTime == null) return "";

  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
  return '${formatDateOnly(context, dateTime)} $time';
}

String formatNumber(int? num) {
  return num == null ? "" : NUM_FORMAT.format(num);
}

double? sum(List args) {
  return args.reduce((value, element) {
    return (value ?? 0) + (element ?? 0);
  });
}

String formatTimestamp(BuildContext context, Timestamp? timestamp,
    {format = formatDatetime}) {
  if (timestamp == null) return "";
  DateTime dateTime = timestamp.toDate();
  return format(context, dateTime);
}

String? toText(BuildContext context, dynamic val) {
  if (val is String) {
    return val;
  } else if (val is int) {
    return formatNumber(val);
  } else if (val is double) {
    return val.toStringAsFixed(2);
  } else if (val is Timestamp) {
    return formatTimestamp(context, val);
  } else if (val is bool) {
    return val ? '\u2713' : '';
    // throw Exception('Not allowed to have boolean in here, please use Image to show it');
  }
  return null;
}

/// ----- [End] old format for phieu can by car, ...
/// ----- [Start] new format for phieu can by date (export excel)
DateTime parseTimestampToDateTime(Timestamp? timestamp) {
  if (timestamp == null) return DateTime.now();
  DateTime dateTime = timestamp.toDate();
  return dateTime;
}

String formatTime(context, Timestamp? timestamp) {
  if (timestamp == null) return "";
  DateTime dateTime = parseTimestampToDateTime(timestamp);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
  return time;
}

String formatDate(context, Timestamp? timestamp) {
  if (timestamp == null) return "";
  DateTime dateTime = parseTimestampToDateTime(timestamp);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  return localizations.formatCompactDate(dateTime);
}

String? toTextExportExcel(BuildContext context, dynamic val) {
  if (val is String) {
    return val;
  } else if (val is int) {
    return formatNumber(val);
  } else if (val is double) {
    return val.toStringAsFixed(2);
  } else if (val is Timestamp) {
    return formatTimestamp(context, val);
  } else if (val is bool) {
    return val ? '\u2713' : '';
    // throw Exception('Not allowed to have boolean in here, please use Image to show it');
  }
  return null;
}

/// ----- [End]new format for phieu can by date (export excel)

double screenHeight(context) {
  return MediaQuery.of(context).size.height;
}

double screenWidth(context) {
  return MediaQuery.of(context).size.width;
}

String dateShortMonthTimestampConvert(context, value) {
  return dateShortMonthDateTimeConvert(context, (value as Timestamp).toDate());
}

String dateShortMonthDateTimeConvert(context, value) {
  return DateFormat('dd-MMM-yyyy').format(value);
}

double? convertUnknownNumberToDouble(data) {
  if (data is int) {
    return data * 1.0;
  } else {
    return data;
  }
}

Widget tableOfTwo(Map<String, String?> map,
    {bool boldLeft = false, bool boldRight = false, double? fontSize}) {
  List<TableRow> list = [];
  for (int i = 0; i < map.entries.length; i++) {
    var e = map.entries.elementAt(i);
    if (e.value != null && e.value != TABLE_OF_TWO_DIVIDER) {
      list.add(TableRow(
          decoration: i < map.entries.length - 1 &&
                  map.entries.elementAt(i + 1).value == TABLE_OF_TWO_DIVIDER
              ? BoxDecoration(
                  border: Border(bottom: EDIT_TABLE_HORIZONTAL_BORDER_SIDE))
              : null,
          children: [
            Text(
              '${e.key}:',
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize),
            ),
            Text(
              e.value!,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: boldRight ? FontWeight.bold : FontWeight.normal),
            )
          ]));
    }
  }
  return Table(
      columnWidths: {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      children: list);
}

Widget tableOfInfinite(Map<String, List<String>> map) {
  return Table(
      columnWidths: {1: IntrinsicColumnWidth()},
      children: map.entries.map((e) {
        final children = [
          Text(
            '${e.key}:',
            textAlign: TextAlign.start,
          )
        ];
        e.value.forEach((element) {
          children.add(Text(
            element,
            textAlign: TextAlign.end,
          ));
        });
        return TableRow(children: children);
      }).toList());
}

getMinDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.isAfter(b)) {
    return b;
  }
  return a;
}

getMaxDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.isAfter(b)) return a;
  return b;
}

List<Map<V, D>?> partitionMap<V, D>(Map<V, D> map, int size) {
  var lists = partitionList<MapEntry<V, D>>(map.entries.toList(), size);
  List<Map<V, D>?> maps = List.filled(lists.length, null);
  lists.asMap().forEach((index, list) {
    maps[index] = {};
    maps[index]!.addEntries(list);
  });
  return maps;
}

List<List<T>> partitionList<T>(List<T> list, int partitionSize) {
  var len = list.length;
  List<List<T>> chunks = [];
  for (var i = 0; i < len; i += partitionSize) {
    var end = (i + partitionSize < len) ? i + partitionSize : len;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}

const int DOT_PER_INCH = 72;
const int DOT_PER_CM = 72 ~/ 2.54;

List<List<T>> partitionListToBin<T>(List<T> list, int binNum) {
  List<List<T>> chunks = [];
  int start = 0;
  int size = (list.length + 1) ~/ binNum;
  for (int i = 0; i < binNum; i++) {
    int end = min(start + size, list.length);
    chunks.add(list.sublist(start, end));
    start = start + size;
  }
  return chunks;
}

// getLastYearFilterDataWrapper() {
//   var startDateLastYear =
//       Jiffy().startOf(Units.YEAR).subtract(years: 1).dateTime;
//   var endDateLastYear = Jiffy().endOf(Units.YEAR).subtract(years: 1).dateTime;
//   return FilterDataWrapper(
//       filterStartValue: Timestamp.fromDate(startDateLastYear),
//       filterEndValue: Timestamp.fromDate(endDateLastYear),
//       filterEndIncludeValue: false);
// }

// getThisYearFilterDataWrapper() {
//   var startDateLastYear = Jiffy().startOf(Units.YEAR).dateTime;
//   var endDateLastYear = Jiffy().endOf(Units.YEAR).dateTime;
//   return FilterDataWrapper(
//       filterStartValue: Timestamp.fromDate(startDateLastYear),
//       filterEndValue: Timestamp.fromDate(endDateLastYear),
//       filterEndIncludeValue: false);
// }

class CurrentLastNextMonthInfo {
  int? month, year, pMonth, pYear, nMonth, nYear;
  Timestamp? thisMonthTimeStamp, nextMonthTimeStamp, lastMonthTimeStamp;
}

CurrentLastNextMonthInfo getCurrentLastNextMonthInfo() {
  CurrentLastNextMonthInfo info = CurrentLastNextMonthInfo();
  Timestamp now = Timestamp.now();
  DateTime dtNow = now.toDate();
  info.month = dtNow.month;
  info.year = dtNow.year;
  if (info.month == 0) {
    info.pMonth = 12;
    info.pYear = info.year! - 1;
    info.nMonth = 1;
    info.nYear = info.year;
  } else if (info.month == 12) {
    info.pMonth = 11;
    info.pYear = info.year;
    info.nMonth = 1;
    info.nYear = info.year! + 1;
  } else {
    info.pMonth = info.month! - 1;
    info.pYear = info.year;
    info.nMonth = info.month! + 1;
    info.nYear = info.year;
  }
  info.thisMonthTimeStamp =
      Timestamp.fromDate(DateTime(info.year!, info.month!));
  info.nextMonthTimeStamp =
      Timestamp.fromDate(DateTime(info.nYear!, info.nMonth!));
  info.lastMonthTimeStamp =
      Timestamp.fromDate(DateTime(info.pYear!, info.pMonth!));
  return info;
}

FilterDataWrapper createFilterDataWrapperThisMonth(
    CurrentLastNextMonthInfo currentMonthInfo) {
  return FilterDataWrapper(
      filterStartValue: currentMonthInfo.thisMonthTimeStamp,
      filterEndValue: currentMonthInfo.nextMonthTimeStamp,
      filterEndIncludeValue: false);
}

FilterDataWrapper createFilterDataWrapperLastMonth(
    CurrentLastNextMonthInfo currentMonthInfo) {
  return FilterDataWrapper(
      filterStartValue: currentMonthInfo.lastMonthTimeStamp,
      filterEndValue: currentMonthInfo.thisMonthTimeStamp,
      filterEndIncludeValue: false);
}

Future showInformation(context, String title, String content) {
  return showAlertDialog(context, title: title, builder: (_) {
    return Text(content);
  }, actions: [
    CommonButton.getButton(context, () {
      Navigator.pop(context);
    }, title: 'Ok', iconData: Icons.close)
  ]);
}

Future showFullSizeImage(context, Image image) {
  return showAlertDialog(context, builder: (_) {
    return SizedBox.expand(child: image);
  }, actions: [
    CommonButton.getButton(context, () {
      Navigator.pop(context);
    }, title: 'Close', iconData: Icons.close)
  ]);
}

Column columnWithGap(List<Widget> children,
    {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double gap = 8}) {
  List<Widget> result = [];
  children.forEach((element) {
    result.add(element);
    result.add(SizedBox(
      height: gap,
    ));
  });
  if (result.isNotEmpty) result.removeLast();
  return Column(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: MainAxisSize.min,
    children: result,
  );
}

Widget splitAnyColumns(List<Widget> widgets, int numBin, {double gap = 10}) {
  List<List<Widget>> lists = partitionListToBin(widgets, numBin);
  List<Widget> widgetList = lists
      .map((list) => Expanded(
            child: columnWithGap(list,
                crossAxisAlignment: CrossAxisAlignment.stretch),
          ) as Widget)
      .toList();
  for (int i = widgetList.length - 1; i >= 1; i--) {
    widgetList.insert(
        i,
        SizedBox(
          width: gap,
        ));
  }
  // a b c d e
  // 0 1 2 3 4
  return Row(mainAxisSize: MainAxisSize.max, children: widgetList);
}

LoiButtonStyle getLoiButtonStyle(BuildContext context) {
  return Provider.of<LoiButtonStyle>(context, listen: false);
}

Widget wrapLoiButtonStyle(context, child) {
  return Provider.value(
    value: getLoiButtonStyle(context),
    child: child,
  );
}

bool isStringEmpty(String? val) {
  return val?.isEmpty ?? true;
}

void popWindow(context) {
  Navigator.of(context).pop();
}

Route createMaterialPageRoute(parentContext, WidgetBuilder builder) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return wrapLoiButtonStyle(parentContext, builder(context));
    },
    transitionDuration: Duration(seconds: 0),
  );
}

Future showAlertDialog(BuildContext context,
    {required WidgetBuilder builder,
    String? title,
    List<Widget>? actions,
    double? percentageWidth}) {
  return showDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: title == null ? null : Text(title),
          content: percentageWidth == null
              ? builder(context)
              : Container(
                  width: screenWidth(context) * percentageWidth,
                  child: builder(context)),
          contentPadding: EdgeInsets.zero,
          actions: actions,
        );
      });
}

createSignOutButton<USER>(context, showErrorFunc) {
  var onPressSignOut = () {
    Provider.of<AuthService<USER>>(context, listen: false)
        .signOut()
        .catchError((error) {
      showErrorFunc(context, error);
    });
  };
  return res_builder.ScreenTypeLayout(
      mobile: CommonButton.getButton(context, onPressSignOut,
          iconData: Icons.exit_to_app),
      tablet:
          CommonButton.getButton(context, onPressSignOut, title: 'Đăng xuất'));
}

res_builder.ScreenBreakpoints forDebuggingScreenBreakpoints() {
  return res_builder.ScreenBreakpoints(tablet: 400, desktop: 800, watch: 200);
}

DateTime stripTime(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

int? multiply(int? val1, int? val2) {
  if (val1 == null || val2 == null) return null;
  return val1 * val2;
}

int? minus(int val1, int? val2) {
  if (val2 == null) return null;
  return val1 - val2;
}

int? absMinus(int val1, int? val2) {
  int? minusRes = minus(val1, val2);
  return minusRes == null ? null : minusRes.abs();
}

String showMonthYearOnly(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month}';
}

String showDateOnly(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
}
//
// Query cloneQuery(CollectionReference ref, InputInfoMap inputInfoMap, Query q) {
//   Map<String, dynamic> map = q.buildArguments();
//   List<List> where = map['where'];
//   List<List> orderBy = map['orderBy'];
//   dynamic query = ref;
//   Map<String, bool> orderByMap = Map.fromEntries(
//       orderBy.map((list) => MapEntry<String, bool>(list[0], list[1])));
//   inputInfoMap.map.keys.forEach((field) {
//     if (orderByMap.containsKey(field))
//       query = query.orderBy(field, descending: orderByMap[field]);
//   });
//   where.forEach((list) {
//     var greater, greaterOrEqual, smaller, smallerOrEqual, equal;
//     switch (list[1]) {
//       case '>':
//         greater = list[2];
//         break;
//       case '>=':
//         greaterOrEqual = list[2];
//         break;
//       case '<':
//         smaller = list[2];
//         break;
//       case '<=':
//         smallerOrEqual = list[2];
//         break;
//       case '=':
//         equal = list[2];
//         break;
//       default:
//     }
//     // query = query.where(list[0],
//     //     isEqualTo: equal,
//     //     isLessThanOrEqualTo: smallerOrEqual,
//     //     isLessThan: smaller,
//     //     isGreaterThanOrEqualTo: greaterOrEqual,
//     //     isGreaterThan: greater);
//   });
//
//   query = query.limit(map['limit']);
//   query=query.startAfter([null,null]);
//   query=query.startAt([null,'anh']);
//   query=query.endBefore([null,'ani']);
//   if (map['startAfter'] != null) query = query.startAfter(map['startAfter']);
//   if (map['endBefore'] != null) {
//     query = query.endBefore(map['endBefore']);
//   }
//   return query;
// }
