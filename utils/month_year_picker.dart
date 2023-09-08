import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../utils.dart';
import '../widget/common.dart';
// import 'package:month_picker_dialog/month_picker_dialog.dart';

import 'all_notifiers.dart';

class MonthYearPicker extends StatefulWidget {
  const MonthYearPicker({Key? key}) : super(key: key);

  @override
  _MonthYearPickerState createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  CurrentMonthYearNotifier? currentMonthYearNotifier;
  void selectMonthYear() {
    var today = Timestamp.now().toDate();
    // showMonthPicker(
    //   context: context,
    //   firstDate: DateTime(today.year - 5, 1),
    //   lastDate: DateTime(today.year + 1, 12),
    //   initialDate: today,
    //   locale: Locale("en"),
    // ).then((date) {
    //   if (date != null) {
    //     setSelectedDate(date);
    //   }
    // });
  }

  void setSelectedDate(DateTime date) {
    currentMonthYearNotifier!.value = date;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentMonthYearNotifier>(
        builder: (BuildContext context, value, Widget? child) {
      currentMonthYearNotifier = value;
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(children: [
              CommonButton.getButton(context, () {
                  setSelectedDate(Jiffy(currentMonthYearNotifier!.value)
                      .subtract(months: 1)
                      .dateTime);
              }, iconData: Icons.arrow_left),
              Container(
                  width: 100,
                  alignment: Alignment.center,
                  child: Consumer<CurrentMonthYearNotifier>(
                    builder:
                        (BuildContext context, dateNotifier, Widget? child) {
                      return Text(showMonthYearOnly(value.value));
                    },
                  )),
              CommonButton.getButton(
                context,
                () {
                  setSelectedDate(Jiffy(currentMonthYearNotifier!.value)
                      .add(months: 1)
                      .dateTime);
                },
                iconData: Icons.arrow_right,
              ),
            ]),
            ScreenTypeLayout(
              mobile: CommonButton.getButton(context, () {
                selectMonthYear();
              }, iconData: Icons.date_range),
              tablet: CommonButton.getButton(context, () {
                selectMonthYear();
              }, title: 'Chọn \nnhanh', iconData: Icons.date_range),
            ),
          ]);
    });
  }
}
