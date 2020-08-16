import '../widget/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils.dart';

Widget valueNotifierCheckBox<V extends ValueNotifier<bool>>(V valueNotifier) {
  return ChangeNotifierProvider<V>.value(
      value: valueNotifier,
      child: Consumer<V>(builder: (_, __, ___) {
        return Checkbox(
          onChanged: (bool value) {
            valueNotifier.value = value;
          },
          value: valueNotifier.value,
        );
      }));
}

Widget valueNotifierDateTime<V extends ValueNotifier<DateTime>>(
    context, V valueNotifier) {
  return ChangeNotifierProvider<V>.value(
      value: valueNotifier,
      child: Consumer<V>(builder: (_, __, ___) {
        var currentDateTime = valueNotifier.value;
        final initialTime = currentDateTime == null
            ? null
            : TimeOfDay.fromDateTime(currentDateTime);
        var firstDate = DateTime.now().subtract(Duration(days: 365 * 2));
        var lastDate = DateTime.now().add(Duration(days: 365 * 2));
        return Row(
            children: [
              currentDateTime == null
                  ? null
                  : Text('${formatDateOnly(context, currentDateTime)}'),
              CommonButton.getButtonAsync(context, () async {
                final DateTime picked = await showDatePicker(
                    context: context,
                    initialDate: currentDateTime ?? DateTime.now(),
                    firstDate: firstDate,
                    lastDate: lastDate);
                if (picked != null) {
                  valueNotifier.value = DateTime(picked.year, picked.month,
                      picked.day, currentDateTime?.hour ?? 0, currentDateTime?.minute ?? 0);
                }
              }, iconData: Icons.date_range),
              initialTime == null ? null : Text(initialTime.format(context)),
              CommonButton.getButton(context,
                      () async {
                    final TimeOfDay picked_s = await showTimePicker(
                        context: context,
                        initialTime: initialTime == null
                            ? TimeOfDay.fromDateTime(DateTime.now())
                            : initialTime,
                        builder: (BuildContext context, Widget child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: false),
                            child: child,
                          );
                        });

                    if (picked_s != null) {
                      valueNotifier.value = DateTime(
                          currentDateTime.year,
                          currentDateTime.month,
                          currentDateTime.day,
                          picked_s.hour,
                          picked_s.minute);
                    }
                  },isEnabled: currentDateTime!=null, iconData: Icons.timer),
            ].where((element) => element != null).toList());
      }));
}
