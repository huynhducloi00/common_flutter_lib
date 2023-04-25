import 'dart:collection';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cloud_obj.dart';
import '../data/cloud_table.dart';
import '../loadingstate/loading_state.dart';
import '../utils.dart';
import '../utils/value_notifier.dart';
import '../widget/common.dart';
import 'auto_form_helper.dart';
import 'firebase_image_picker/image_picker_container.dart';

const InputDecoration EDIT_TEXT_INPUT_DECORATION = InputDecoration(
    fillColor: Colors.white,
    filled: true,
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0)),
    focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink, width: 2.0)));

typedef SaveClickFuture = Future? Function(Map<String, dynamic>);
typedef OnPop = void Function();

class AutoForm extends StatefulWidget {
  static final Color? disabledColor = Colors.grey[400];
  InputInfoMap inputInfoMap;
  Map<String, dynamic> initialValue;
  SaveClickFuture? saveClickFuture;
  bool isNew;
  OnPop? onPop;

  static createAutoForm(
      context, InputInfoMap inputInfoMap, Map<String, dynamic> initialValue,
      {SaveClickFuture? saveClickFuture,
      OnPop? onPop,
      LinkedHashSet<String>? calculatingOrder,
      bool isNew = false}) {
    var child = AutoForm._internal(
        context, inputInfoMap, initialValue, saveClickFuture, isNew);
    Stream<List<DataBundle>> bundleStream;
    if (inputInfoMap.relatedTables != null) {
      List<Stream<DataBundle>> streams =
          inputInfoMap.relatedTables!.map((relatedTable) {
        Stream<QuerySnapshot> streams;
        if (relatedTable.query == null) {
          streams = FirebaseFirestore.instance
              .collection(relatedTable.tableName)
              .snapshots();
        } else {
          streams = relatedTable.query!.snapshots();
        }
        return streams.map((event) {
          List<Map> a = event.docs.map((doc) {
            if (relatedTable.documentSnapshotConversion != null) {
              return relatedTable.documentSnapshotConversion!(doc);
            }
           return doc.data() as Map;
          }).toList();
          return DataBundle(relatedTable.tableName, a);
        });
      }).toList();
      bundleStream = StreamZip(streams).map((list) => list);
    } else {
      bundleStream = Stream<List<DataBundle>>.value(<DataBundle>[]);
    }
    return WillPopScope(
        onWillPop: () async {
          if (onPop != null) {
            onPop();
          }
          return true;
        },
        child: wrapLoiButtonStyle(
            context,
            bundleStream == null
                ? child
                : StreamProvider<List<DataBundle>?>(
                    initialData: null,
                    create: (BuildContext context) {
                      return bundleStream;
                    },
                    child: child,
                  )));
  }

  AutoForm._internal(context, this.inputInfoMap, this.initialValue,
      this.saveClickFuture, this.isNew);

  @override
  _AutoFormState createState() => _AutoFormState();
}

class CheckBoxController extends ValueNotifier<bool> {
  CheckBoxController(bool value) : super(value);
}

class DateTimeController extends ValueNotifier<DateTime?> {
  DateTimeController(DateTime? value) : super(value);
}

typedef FieldValueChangeCallback = void Function(
    ValueNotifier? notifier, String changedFieldName, dynamic val);

class _AutoFormState extends LoadingState<AutoForm, List<DataBundle>?> {
  _AutoFormState() : super(isRequireData: true);

  // Map from field name to TEXT/INT controller
  // Type of controller:
  // 1.TextEditingController
  // 2. CheckBoxController
  // 3. DateTimeController.
  final Map<String, ValueNotifier?> _allNotifiers = Map();
  final _formKey = GlobalKey<FormState>();
  Map<String, DataBundle> bundleMap = {};
  final SizedBox divider = SizedBox(
    width: 20,
  );

  @override
  void dispose() {
    _allNotifiers.forEach((key, value) {
      value!.dispose();
    });
    super.dispose();
  }

  bool changeCallbackActive = false;

  @override
  void initState() {
    widget.inputInfoMap.map!.forEach((fieldName, inputInfo) {
      ValueNotifier? notifier;
      switch (inputInfo.dataType) {
        case DataType.string:
        case DataType.int:
        case DataType.double:
          notifier = TextEditingController(
              text: widget.initialValue[fieldName]?.toString());
          break;
        case DataType.html:
          break;
        case DataType.timestamp:
          notifier = DateTimeController(
              (widget.initialValue[fieldName] as Timestamp?)?.toDate());
          break;
        case DataType.boolean:
          notifier =
              CheckBoxController(widget.initialValue[fieldName] ?? false);
          break;
        case DataType.firebaseImage:
          notifier = ImageValueNotifier(
              ImageCombo.fromImageLink(widget.initialValue[fieldName]));
          break;
      }
      _allNotifiers[fieldName] = notifier;
    });
    final FieldValueChangeCallback fieldValueChangeCallback =
        (ValueNotifier? notifier1, changedFieldName, val) {
      if (changeCallbackActive) {
        // only allow one callback to run at a time
        return;
      }
      changeCallbackActive = true;
      const bool DEBUG = false;
      if (DEBUG) print('gia tri thay doi: $changedFieldName $val');
      var resultBundle = getCurrentReturnedMap(filterSavingFields: false)[0];
      if (DEBUG) print('before $resultBundle');
      if (widget.inputInfoMap.fieldChangedFieldMap![changedFieldName] != null) {
        if (DEBUG)
          print(
              'affecting field: ${widget.inputInfoMap.fieldChangedFieldMap![changedFieldName]}');
        widget.inputInfoMap.fieldChangedFieldMap![changedFieldName]!
            .forEach((fieldName) {
          var result = widget.inputInfoMap.map![fieldName]!.calculate!(
              resultBundle, bundleMap);
          if (DEBUG) print('$fieldName $result');
          var notifier = _allNotifiers[fieldName];
          if (result != null) {
            // not the same as before check
            resultBundle[fieldName] = result.value;
            if (notifier is TextEditingController) {
              notifier.text = result.value?.toString() ?? '';
            } else if (notifier is DateTimeController) {
              notifier.value = result.value?.toDate();
            }
          }
        });
      }
      if (DEBUG)
        print('after ${getCurrentReturnedMap(filterSavingFields: false)[0]}');
      changeCallbackActive = false;
    };
    for (MapEntry<String, ValueNotifier?> entry in _allNotifiers.entries) {
      if (entry.value is TextEditingController) {
        entry.value!.addListener(() {
          fieldValueChangeCallback(entry.value, entry.key,
              (entry.value as TextEditingController).text);
        });
      }
    }
    super.initState();
  }

  Widget? _getWidgetFromDataType(String fieldName) {
    var resultWidget;
    var inputInfo = widget.inputInfoMap.map![fieldName]!;
    bool isEnabled = inputInfo.canUpdate;
    InputDecoration inputDecoration = EDIT_TEXT_INPUT_DECORATION.copyWith(
        fillColor: isEnabled ? Colors.white : AutoForm.disabledColor);
    switch (inputInfo.dataType) {
      case DataType.html:
        return null;
      case DataType.string:
        if (inputInfo.optionMap == null) {
          resultWidget = TextFormField(
            controller: _allNotifiers[fieldName] as TextEditingController?,
            enabled: isEnabled,
            decoration: inputDecoration,
            validator: (val) =>
                inputInfo.validator == null ? null : inputInfo.validator!(val),
            obscureText: false,
          );
          if (inputInfo.linkedData != null && isEnabled) {
            resultWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: resultWidget),
                CommonButton.createDataPickerButton(
                    context,
                    LoiAllCloudTables.getValueInMap(
                        inputInfo.linkedData!.tableName),
                    inputInfo.linkedData!.linkedFieldName, (val, _) {
                  if (val != null) {
                    (_allNotifiers[fieldName] as TextEditingController).text =
                        val;
                  }
                }, iconData: Icons.add_link)
              ],
            );
          }
        } else {
          resultWidget = AutoFormHelper.dropDownText(
              _allNotifiers[fieldName] as TextEditingController?, inputInfo);
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
      case DataType.double:
      case DataType.int:
        if (inputInfo.optionMap == null) {
          resultWidget = TextFormField(
            enabled: isEnabled,
            controller: _allNotifiers[fieldName] as TextEditingController?,
            decoration: inputDecoration,
            validator: (val) =>
                inputInfo.validator == null ? null : inputInfo.validator!(val),
            obscureText: false,
            keyboardType: TextInputType.numberWithOptions(
                decimal: inputInfo.dataType == DataType.double),
            // inputFormatters: <TextInputFormatter>[
            //   FilteringTextInputFormatter.allow(RegExp(r'[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)'))
            // ]
          );
        } else {
          resultWidget = AutoFormHelper.dropDownInt(
              _allNotifiers[fieldName] as TextEditingController?, inputInfo);
        }
        break;
      case DataType.timestamp:
        resultWidget = valueNotifierDateTime(
            context, _allNotifiers[fieldName] as ValueNotifier<DateTime?>);
        break;
      case DataType.boolean:
        resultWidget = valueNotifierCheckBox(
            _allNotifiers[fieldName] as ValueNotifier<bool?>);
        break;
      case DataType.firebaseImage:
        resultWidget = valueNotifierImageCombo(
            context, _allNotifiers[fieldName] as ImageValueNotifier);
        break;
    }
    return resultWidget;
  }

  String validateNonStrField(
      String originalErrorStr, dynamic val, InputInfo inputInfo) {
    if (inputInfo.validator == null) {
      return originalErrorStr;
    }
    var hasError = inputInfo.validator!(val);
    if (hasError != null) {
      // violation
      originalErrorStr += '$hasError:${inputInfo.fieldDes}\n';
    }
    return originalErrorStr;
  }

  @override
  Widget delegateBuild(BuildContext context) {
    bundleMap =
        data!.asMap().map((key, value) => MapEntry(value.tableName, value));
    if (widget.isNew) {
      widget.inputInfoMap.map!.forEach((fieldName, inputInfo) {
        if (inputInfo.initializeFunc != null &&
            _allNotifiers[fieldName] is TextEditingController) {
          var controller = _allNotifiers[fieldName] as TextEditingController;
          if (controller.text.isEmpty) {
            controller.text =
                inputInfo.initializeFunc!(bundleMap).value!.toString();
          }
        }
      });
    }
    List<TableRow> editBoxes = [];
    widget.inputInfoMap.map!.forEach((fieldName, inputInfo) {
      Widget? resultWidget = _getWidgetFromDataType(fieldName);
      if (resultWidget != null) {
        editBoxes.add(
          TableRow(children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(
                child: Text(inputInfo.fieldDes),
                margin: EdgeInsets.only(right: 5),
              ),
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
              if (!_formKey.currentState!.validate()) {
                return;
              }
              var resultBundle =
                  getCurrentReturnedMap(filterSavingFields: true);
              Map<String, dynamic> result = resultBundle[0];
              String? otherError = resultBundle[1];

              if (otherError?.isEmpty ?? false) {
                if (widget.saveClickFuture != null) {
                  await widget.saveClickFuture!(result);
                }
                Navigator.pop(context);
              } else {
                return showInformation(context, "Error", otherError!);
              }
            },
                regularColor: Colors.transparent,
                iconData: Icons.save,
                title: 'Save')
          ],
        ),
        backgroundColor: Colors.brown[100],
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _formKey,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                children: editBoxes,
              ),
            ),
          ),
        ));
  }

  // 1st store the map, 2nd stores the error string
  // if forSavingData then only return what is needed.
  List getCurrentReturnedMap({bool filterSavingFields = false}) {
    Map<String, dynamic> result = Map();
    String otherError = '';
    widget.inputInfoMap.map!.forEach((fieldName, inputInfo) {
      if (!filterSavingFields || inputInfo.needSaving) {
        switch (inputInfo.dataType) {
          case DataType.string:
            result[fieldName] = _allNotifiers[fieldName]!.value.text;
            break;
          case DataType.html:
            // TODO: Handle this case.
            break;
          case DataType.double:
            otherError = validateNonStrField(
                otherError, _allNotifiers[fieldName]!.value.text, inputInfo);
            result[fieldName] = _allNotifiers[fieldName]!.value.text.isEmpty
                ? null
                : double.parse(_allNotifiers[fieldName]!.value.text);
            break;
          case DataType.int:
            otherError = validateNonStrField(
                otherError, _allNotifiers[fieldName]!.value.text, inputInfo);
            result[fieldName] = _allNotifiers[fieldName]!.value.text.isEmpty
                ? null
                : int.parse(_allNotifiers[fieldName]!.value.text);
            break;
          case DataType.timestamp:
            otherError = validateNonStrField(
                otherError, _allNotifiers[fieldName]!.value, inputInfo);
            result[fieldName] = _allNotifiers[fieldName]!.value == null
                ? null
                : Timestamp.fromDate(_allNotifiers[fieldName]!.value);
            break;
          case DataType.boolean:
            result[fieldName] = _allNotifiers[fieldName]!.value;
            break;
          case DataType.firebaseImage:
            result[fieldName] =
                (_allNotifiers[fieldName]! as ImageValueNotifier)
                    .value
                    .imageLink;
            break;
        }
      }
    });
    return [result, otherError];
  }
}
