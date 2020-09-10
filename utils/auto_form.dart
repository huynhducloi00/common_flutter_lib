import '../utils/auto_form_helper.dart';

import '../utils.dart';
import '../utils/value_notifier.dart';
import '../widget/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/cloud_obj.dart';
import '../data/cloud_table.dart';

const InputDecoration EDIT_TEXT_INPUT_DECORATION = InputDecoration(
    fillColor: Colors.white,
    filled: true,
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0)),
    focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink, width: 2.0)));

typedef SaveClickFuture = Future Function(Map<String, dynamic>);
typedef OnPop = void Function();

class AutoForm extends StatefulWidget {
  static final Color disabledColor = Colors.grey[400];
  Map<String, InputInfo> inputInfoMap;
  Map<String, dynamic> initialValue;
  SaveClickFuture saveClickFuture;
  OnPop onPop;

  static createAutoForm(context, Map<String, InputInfo> inputInfoMap,
      Map<String, dynamic> initialValue,
      {SaveClickFuture saveClickFuture, OnPop onPop}) {
    return WillPopScope(
      onWillPop: () async {
        if (onPop != null) {
          onPop();
        }
        return true;
      },
      child: wrapLoiButtonStyle(context,  AutoForm._internal(
              context, inputInfoMap, initialValue, saveClickFuture))
    );
  }

  AutoForm._internal(
      context, this.inputInfoMap, this.initialValue, this.saveClickFuture);

  @override
  _AutoFormState createState() => _AutoFormState();
}

class CheckBoxController extends ValueNotifier<bool> {
  CheckBoxController(bool value) : super(value);
}

class DateTimeController extends ValueNotifier<DateTime> {
  DateTimeController(DateTime value) : super(value);
}

class _AutoFormState extends State<AutoForm> {
  // Map from field name to TEXT/INT controller
  Map<String, TextEditingController> _textEditingControllers = Map();

  // Map for checkboxes
  Map<String, CheckBoxController> _checkBoxControllers = Map();
  Map<String, DateTimeController> _dateTimeControllers = Map();
  final _formKey = GlobalKey<FormState>();

  final SizedBox divider = SizedBox(
    width: 20,
  );

  @override
  void dispose() {
    _textEditingControllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    widget.inputInfoMap.forEach((fieldName, inputInfo) {
      if (inputInfo.dataType == DataType.string ||
          inputInfo.dataType == DataType.int) {
        _textEditingControllers[fieldName] = TextEditingController(
            text: widget.initialValue[fieldName]?.toString());
      } else if (inputInfo.dataType == DataType.boolean) {
        _checkBoxControllers[fieldName] =
            CheckBoxController(widget.initialValue[fieldName] ?? false);
      } else if (inputInfo.dataType == DataType.timestamp) {
        _dateTimeControllers[fieldName] = DateTimeController(
            (widget.initialValue[fieldName] as Timestamp)?.toDate());
      }
    });
    super.initState();
  }

  Widget _getWidgetFromDataType(String fieldName) {
    var resultWidget;
    var inputInfo = widget.inputInfoMap[fieldName];
    if (inputInfo.calculate != null) return null;
    switch (inputInfo.dataType) {
      case DataType.html:
        return null;
        break;
      case DataType.string:
        if (inputInfo.optionMap == null) {
          resultWidget = TextFormField(
            controller: _textEditingControllers[fieldName],
            enabled: inputInfo.canUpdate,
            decoration: EDIT_TEXT_INPUT_DECORATION.copyWith(
                fillColor: inputInfo.canUpdate
                    ? Colors.white
                    : AutoForm.disabledColor),
            validator: (val) =>
                inputInfo.validator == null ? null : inputInfo.validator(val),
            obscureText: false,
          );
        } else {
          resultWidget = AutoFormHelper.dropDownText(
              _textEditingControllers[fieldName], inputInfo);
        }
        break;
//      case DataType.html:
//        resultWidget = Row(
//          crossAxisAlignment: CrossAxisAlignment.center,
//          children: [
//            Flexible(
//              child: TextFormField(
//                controller: _textEditingControllers[fieldName],
//                decoration: EDIT_TEXT_INPUT_DECORATION,
//                maxLines: 1,
//                validator: (val) => inputInfo.validator == null
//                    ? null
//                    : inputInfo.validator(val),
//                obscureText: false,
//                enabled: false,
//              ),
//            ),
//            divider,
//            CommonButton.getButton(context,
//              () async {
//                String result = await Navigator.push(context,
//                    MaterialPageRoute(builder: (context) {
//                  return HtmlEditor(inputInfo.value);
//                }));
//                if (result == null || result.isEmpty) {
//                  return;
//                }
//                setState(() {
//                  inputInfo.value = result;
//                });
//
//                _textEditingControllers[fieldName].value =
//                    _textEditingControllers[fieldName].value.copyWith(text: result);
//              },
//              iconData: Icons.edit,
//            ),
//            divider,
//            CommonButton.getButton(context,
//              null,
//              iconData: Icons.content_paste,
//            )
//          ],
//        );
        break;
      case DataType.int:
        if (inputInfo.optionMap == null) {
          resultWidget = TextFormField(
              enabled: inputInfo.canUpdate,
              controller: _textEditingControllers[fieldName],
              decoration: EDIT_TEXT_INPUT_DECORATION,
              validator: (val) =>
                  inputInfo.validator == null ? null : inputInfo.validator(val),
              obscureText: false,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly
              ]);
        } else {
          resultWidget = AutoFormHelper.dropDownInt(
              _textEditingControllers[fieldName], inputInfo);
        }
        break;
      case DataType.timestamp:
        resultWidget =
            valueNotifierDateTime(context, _dateTimeControllers[fieldName]);
        break;
      case DataType.boolean:
        resultWidget = valueNotifierCheckBox(_checkBoxControllers[fieldName]);
        break;
    }
    return resultWidget;
  }

  String validateNonStrField(String originalErrorStr, dynamic val, inputInfo) {
    var hasError = inputInfo.validator(val);
    if (inputInfo.validator != null && hasError != null) {
      // violation
      originalErrorStr += '$hasError:${inputInfo.fieldDes}\n';
    }
    return originalErrorStr;
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> editBoxes = new List();
    widget.inputInfoMap.forEach((fieldName, inputInfo) {
      Widget resultWidget = _getWidgetFromDataType(fieldName);
      if (resultWidget != null) {
        editBoxes.add(
          TableRow(children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(child: Text(inputInfo.fieldDes), margin: EdgeInsets.only(right: 5),),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: resultWidget),
            ),
          ]),
        );
      }
    });
    return Scaffold(
        appBar: AppBar(
          actions: [
            CommonButton.getButtonAsync(context, () async {
              if (!_formKey.currentState.validate()) {
                return;
              }
              Map<String, dynamic> result = Map();
              String otherError = '';
              widget.inputInfoMap.forEach((fieldName, inputInfo) {
                if (inputInfo.calculate == null) {
                  switch (inputInfo.dataType) {
                    case DataType.string:
                      result[fieldName] =
                          _textEditingControllers[fieldName].text;
                      break;
                    case DataType.html:
                      // TODO: Handle this case.
                      break;
                    case DataType.int:
                      otherError = validateNonStrField(otherError,
                          _textEditingControllers[fieldName].text, inputInfo);
                      if (_textEditingControllers[fieldName].text.isNotEmpty)
                        result[fieldName] = int.parse(
                            _textEditingControllers[fieldName].text);
                      break;
                    case DataType.timestamp:
                      otherError = validateNonStrField(otherError,
                          _dateTimeControllers[fieldName].value, inputInfo);
                      result[fieldName] =
                          _dateTimeControllers[fieldName].value == null
                              ? null
                              : Timestamp.fromDate(
                                  _dateTimeControllers[fieldName].value);
                      break;
                    case DataType.boolean:
                      result[fieldName] =
                          _checkBoxControllers[fieldName].value == null
                              ? null
                              : _checkBoxControllers[fieldName].value;
                      break;
                  }
                }
              });
              if (otherError?.isEmpty ?? false) {
                if (widget.saveClickFuture != null) {
                  await widget.saveClickFuture(result);
                }
                Navigator.pop(context);
              } else {
                return showInformation(context, "Lỗi", otherError);
              }
            },
                regularColor: Colors.transparent,
                iconData: Icons.save,
                title: 'Lưu')
          ],
        ),
        backgroundColor: Colors.brown[100],
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _formKey,
              child: Table(
                defaultVerticalAlignment:
                    TableCellVerticalAlignment.middle,
                columnWidths: {0: IntrinsicColumnWidth()},
                children: editBoxes,
              ),
            ),
          ),
        ));
  }
}
