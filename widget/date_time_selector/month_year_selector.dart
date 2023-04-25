import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils.dart';
import '../common.dart';

class MonthYear {
  int month, year;

  MonthYear(this.month, this.year);

  MonthYear deltaMonth(int monthDelta) {
    var newMonth = month + monthDelta;
    var newYear = year;
    if (newMonth == 0) {
      newMonth = 12;
      newYear--;
    } else if (newMonth == 13) {
      newMonth = 1;
      newYear++;
    }

    return MonthYear(newMonth, newYear);
  }

  static getMonthYearNow() {
    var currentDate = stripTime(DateTime.now());
    return MonthYear(currentDate.month, currentDate.year);
  }
}

class CurrentMonthYearNotifier extends ValueNotifier<MonthYear> {
  CurrentMonthYearNotifier(MonthYear value) : super(value);
}

class MonthYearSelector extends StatelessWidget {
  late CurrentMonthYearNotifier currentMonthYearNotifier;
  double gap;

  MonthYearSelector({this.gap = 100});

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMonthYearNotifier>(
        builder: (BuildContext context, _value, Widget? child) {
      currentMonthYearNotifier = _value;

      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(children: [
              CommonButton.getButton(context, () {
                if (currentMonthYearNotifier.value == null) {
                  currentMonthYearNotifier.value = MonthYear.getMonthYearNow();
                } else
                  currentMonthYearNotifier.value =
                      currentMonthYearNotifier.value.deltaMonth(-1);
              }, iconData: Icons.arrow_left),
              SizedBox(
                width: gap,
              ),
              Text(currentMonthYearNotifier.value == null
                  ? ""
                  : "${currentMonthYearNotifier.value.month}-${currentMonthYearNotifier.value.year}"),
              SizedBox(
                width: gap,
              ),
              CommonButton.getButton(
                context,
                () {
                  if (currentMonthYearNotifier.value == null) {
                    currentMonthYearNotifier.value =
                        MonthYear.getMonthYearNow();
                  } else
                    currentMonthYearNotifier.value =
                        currentMonthYearNotifier.value.deltaMonth(1);
                },
                iconData: Icons.arrow_right,
              ),
            ]),
            // ScreenTypeLayout(
            //   mobile: CommonButton.getButton(context, () {
            //     _selectDate(context);
            //   }, iconData: Icons.date_range),
            //   tablet: CommonButton.getButton(context, () {
            //     _selectDate(context);
            //   }, title: 'Chọn ngày\nnhanh', iconData: Icons.date_range),
            // ),
          ]);
    });
  }
}
