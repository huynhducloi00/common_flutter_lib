import '../data/cloud_table.dart';
import 'package:flutter/material.dart';

import 'auto_form.dart';

class AutoFormHelper {
  static Widget dropDownText(
      TextEditingController controller, InputInfo inputInfo) {
    return StatefulBuilder(builder: (BuildContext context, setState) {
      return DropdownButtonHideUnderline(
        child: DropdownButtonFormField(
          validator: (val) =>
              inputInfo.validator == null ? null : inputInfo.validator(val),
          isExpanded: true,
          focusColor: Colors.white,
          value: controller.text,
          items: [
                DropdownMenuItem(
                    value: controller.text,
                    child: TextField(
                      decoration: EDIT_TEXT_INPUT_DECORATION.copyWith(
                          fillColor: inputInfo.canUpdate
                              ? Colors.white
                              : AutoForm.disabledColor),
                      controller: controller,
                    ))
              ] +
              inputInfo.optionMap.keys
                  .where((option) => option != controller.text)
                  .map((option) => DropdownMenuItem(
                      value: option as String, child: Text(option)))
                  .toList(),
          onChanged: (value) {
            controller.value = controller.value.copyWith(text: value);
            setState(() {});
          },
        ),
      );
    });
  }

  static Widget dropDownInt(
      TextEditingController controller, InputInfo inputInfo) {
    return StatefulBuilder(builder: (BuildContext context, setState) {
      return DropdownButtonHideUnderline(
        child: DropdownButtonFormField(
          validator: (val) =>
              inputInfo.validator == null ? null : inputInfo.validator(val),
          isExpanded: true,
          focusColor: Colors.white,
          value: controller.text.isEmpty ? null : controller.text,
          items: inputInfo.optionMap
              .entries
              .map((pair) => DropdownMenuItem(
                  value: pair.key.toString(),
                  child: Text(pair.value)))
              .toList(),
          onChanged: (value) {
            controller.value = controller.value.copyWith(text: value);
          },
        ),
      );
    });
  }
}
