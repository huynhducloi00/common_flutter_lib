import 'package:flutter/cupertino.dart';

class CurrentFilterDateNotifier extends ValueNotifier<DateTime> {
  CurrentFilterDateNotifier(DateTime intialValue)
      : super(DateTime(intialValue.year, intialValue.month, intialValue.day));
}

class CurrentMonthYearNotifier extends ValueNotifier<DateTime> {
  CurrentMonthYearNotifier(DateTime intialValue)
      : super(DateTime(intialValue.year, intialValue.month));
}
