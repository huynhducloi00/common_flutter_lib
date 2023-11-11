import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils.dart';
import '../widget/common.dart';
import 'firebase_image_picker/image_picker_container.dart';

Widget valueNotifierCheckBox<V extends ValueNotifier<bool?>>(V valueNotifier,
    {String? title, TextStyle? style}) {
  return ChangeNotifierProvider<V>.value(
      value: valueNotifier,
      child: Consumer<V>(builder: (_, __, ___) {
        Widget checkbox = Checkbox(
          tristate: false,
          onChanged: (bool? value) {
            valueNotifier.value = value;
          },
          value: valueNotifier.value,
        );
        if (title == null)
          return checkbox;
        else {
          return Row(children: [Text(title, style: style), checkbox]);
        }
      }));
}

Widget valueNotifierImageCombo(
    context, ImageValueNotifier valueNotifier) {
  return ChangeNotifierProvider.value(
      value: valueNotifier, child: ImageValuePicker());
}

Widget valueNotifierDateTime<V extends ValueNotifier<DateTime?>>(
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
        return Wrap(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(currentDateTime == null
                ? ''
                : '${formatDateOnly(context, currentDateTime)} '),
            CommonButton.getButtonAsync(context, () async {
              final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: currentDateTime ?? DateTime.now(),
                  firstDate: firstDate,
                  lastDate: lastDate);
              if (picked != null) {
                valueNotifier.value = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    currentDateTime?.hour ?? 0,
                    currentDateTime?.minute ?? 0);
              }
            }, iconData: Icons.date_range),
          ]),
          Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(initialTime == null
                    ? ''
                    : '${initialTime.format(context)} '),
                CommonButton.getButton(context, () async {
                  final TimeOfDay? pickedS = await showTimePicker(
                      context: context,
                      initialTime: initialTime == null
                          ? TimeOfDay.fromDateTime(DateTime.now())
                          : initialTime,
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        );
                      });

                  if (pickedS != null) {
                    valueNotifier.value = DateTime(
                        currentDateTime!.year,
                        currentDateTime.month,
                        currentDateTime.day,
                        pickedS.hour,
                        pickedS.minute);
                  }
                }, isEnabled: currentDateTime != null, iconData: Icons.timer),
              ].whereType<Widget>().toList())
        ]);
      }));
}
