import 'package:flutter/material.dart';

Widget tableOfTwo(Map<String, String> map) {
  return Table(
      columnWidths: {1: IntrinsicColumnWidth()},
      children: map.entries
          .map((e) => TableRow(children: [
                Text(
                  '${e.key}:',
                  textAlign: TextAlign.start,
                ),
                Text(
                  e.value,
                  textAlign: TextAlign.end,
                )
              ]))
          .toList());
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
  if (a==null)
    return b;
  if (b==null)
    return a;
  if (a.isAfter(b)) {
    return b;
  }
  return a;
}

getMaxDate(DateTime a, DateTime b) {
  if (a==null)
    return b;
  if (b==null)
    return a;
  if (a.isAfter(b)) return a;
  return b;
}
