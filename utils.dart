import 'widget/edit_table/parent_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/cloud_table.dart';
import 'widget/common.dart';

final NumberFormat NUM_FORMAT = NumberFormat("#,###");
final TABLE_OF_TWO_DIVIDER = "TABLE_OF_TWO_DIVIDER";

final TextStyle BIG_FONT = TextStyle(fontSize: 18);
final TextStyle MEDIUM_FONT = TextStyle(fontSize: 14);

const EDIT_TABLE_BORDER_SIDE =
    BorderSide(width: 1, color: Colors.brown, style: BorderStyle.solid);

class TableWidthAndSize {
  double width;
  Map<int, TableColumnWidth> colWidths;

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
    double width = inputInfo.flex * standardColWidth;
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

String formatDatetime(context, DateTime dateTime) {
  if (dateTime == null) return "";

  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
  return '${formatDateOnly(context, dateTime)} $time';
}

String formatNumber(int num) {
  return num == null ? "" : NUM_FORMAT.format(num);
}

int sum(List args) {
  return args.reduce((value, element) {
    return (value ?? 0) + (element ?? 0);
  });
}

String formatTimestamp(BuildContext context, Timestamp timestamp) {
  if (timestamp == null) return "";
  DateTime dateTime = timestamp.toDate();
  return formatDatetime(context, dateTime);
}

String toText(context, dynamic val) {
  if (val is String) {
    return val;
  } else if (val is int) {
    return formatNumber(val);
  } else if (val is Timestamp) {
    return formatTimestamp(context, val);
  }
  return null;
}

double screenHeight(context) {
  return MediaQuery.of(context).size.height;
}

double screenWidth(context) {
  return MediaQuery.of(context).size.width;
}

Widget tableOfTwo(Map<String, String> map,
    {bool boldLeft = false, bool boldRight = false}) {
  List<TableRow> list = [];
  for (int i = 0; i < map.entries.length; i++) {
    var e = map.entries.elementAt(i);
    if (e.value != null && e.value != TABLE_OF_TWO_DIVIDER) {
      list.add(TableRow(
          decoration: i < map.entries.length - 1 &&
                  map.entries.elementAt(i + 1).value == TABLE_OF_TWO_DIVIDER
              ? BoxDecoration(border: Border(bottom: EDIT_TABLE_BORDER_SIDE))
              : null,
          children: [
            Text(
              '${e.key}:',
              textAlign: TextAlign.start,
            ),
            Text(
              e.value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: boldRight ? FontWeight.bold : FontWeight.normal),
            )
          ]));
    }
  }
  return Table(columnWidths: {1: IntrinsicColumnWidth()}, children: list);
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

getMinDate(DateTime a, DateTime b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.isAfter(b)) {
    return b;
  }
  return a;
}

getMaxDate(DateTime a, DateTime b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.isAfter(b)) return a;
  return b;
}

List<Map<V, D>> partitionMap<V, D>(Map<V, D> map, int size) {
  var lists = partitionList<MapEntry<V, D>>(map.entries.toList(), size);
  List<Map<V, D>> maps = List(lists.length);
  lists.asMap().forEach((index, list) {
    maps[index] = Map();
    maps[index].addEntries(list);
  });
  return maps;
}

List<List<T>> partitionList<T>(List<T> list, int size) {
  var len = list.length;
  List<List<T>> chunks = [];
  for (var i = 0; i < len; i += size) {
    var end = (i + size < len) ? i + size : len;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}

class CurrentLastNextMonthInfo {
  int month, year, pMonth, pYear, nMonth, nYear;
  Timestamp thisMonthTimeStamp, nextMonthTimeStamp, lastMonthTimeStamp;
}

CurrentLastNextMonthInfo getCurrentLastNextMonthInfo() {
  CurrentLastNextMonthInfo info = CurrentLastNextMonthInfo();
  Timestamp now = Timestamp.now();
  DateTime dtNow = now.toDate();
  info.month = dtNow.month;
  info.year = dtNow.year;
  if (info.month == 0) {
    info.pMonth = 12;
    info.pYear = info.year - 1;
    info.nMonth = 1;
    info.nYear = info.year;
  } else if (info.month == 12) {
    info.pMonth = 11;
    info.pYear = info.year;
    info.nMonth = 1;
    info.nYear = info.year + 1;
  } else {
    info.pMonth = info.month - 1;
    info.pYear = info.year;
    info.nMonth = info.month + 1;
    info.nYear = info.year;
  }
  info.thisMonthTimeStamp = Timestamp.fromDate(DateTime(info.year, info.month));
  info.nextMonthTimeStamp =
      Timestamp.fromDate(DateTime(info.nYear, info.nMonth));
  info.lastMonthTimeStamp =
      Timestamp.fromDate(DateTime(info.pYear, info.pMonth));
  return info;
}
FilterDataWrapper createFilterDataWrapperThisMonth(CurrentLastNextMonthInfo currentMonthInfo){
  return FilterDataWrapper(
      filterStartValue: currentMonthInfo.thisMonthTimeStamp,
      filterEndValue: currentMonthInfo.nextMonthTimeStamp,
      filterEndIncludeValue: false);
}
FilterDataWrapper createFilterDataWrapperLastMonth(CurrentLastNextMonthInfo currentMonthInfo){
  return FilterDataWrapper(
      filterStartValue: currentMonthInfo.lastMonthTimeStamp,
      filterEndValue: currentMonthInfo.thisMonthTimeStamp,
      filterEndIncludeValue: false);
}
Future showInformation(context, title, content) {
  return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CommonButton.getButton(context, () {
              Navigator.pop(context);
            }, title:'Ok')
          ],
        );
      });
}