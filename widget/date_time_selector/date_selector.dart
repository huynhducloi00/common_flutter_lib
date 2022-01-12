import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../utils.dart';
import '../common.dart';

class CurrentDateNotifier extends ValueNotifier<DateTime> {
  CurrentDateNotifier(DateTime value) : super(value);
}

class DateSelector extends StatelessWidget {
  late CurrentDateNotifier currentDateNotifier;
  double gap;

  DateSelector({this.gap = 100});

  Future<Null> _selectDate(BuildContext context) async {
    var today = DateTime.now();
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: DateTime(2015, 8),
        lastDate: today.add(Duration(days: 2)));
    if (picked != null && picked != currentDateNotifier.value)
      setSelectedDate(picked);
  }

  void setSelectedDate(DateTime date) {
    currentDateNotifier.value = date;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentDateNotifier>(
        builder: (BuildContext context, value, Widget? child) {
      currentDateNotifier = value;
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(children: [
              CommonButton.getButton(context, () {
                if (currentDateNotifier.value == null) {
                  setSelectedDate(stripTime(DateTime.now()));
                } else
                  setSelectedDate(
                      currentDateNotifier.value.subtract(Duration(days: 1)));
              }, iconData: Icons.arrow_left),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: Text(
                    value.value == null ? "" : "${showDateOnly(value.value)}"),
              ),
              CommonButton.getButton(
                context,
                () {
                  if (currentDateNotifier.value == null) {
                    setSelectedDate(stripTime(DateTime.now()));
                  } else
                    setSelectedDate(
                        currentDateNotifier.value.add(Duration(days: 1)));
                },
                iconData: Icons.arrow_right,
              ),
            ]),
            SizedBox(width: gap,),
            ScreenTypeLayout(
              mobile: CommonButton.getButton(context, () {
                _selectDate(context);
              }, iconData: Icons.date_range),
              tablet: CommonButton.getButton(context, () {
                _selectDate(context);
              }, title: 'Chọn ngày\nnhanh', iconData: Icons.date_range),
            ),
          ]);
    });
  }
}
