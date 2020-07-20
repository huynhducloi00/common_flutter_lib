import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/mobile_hover_button.dart';

import '../data/cloud_obj.dart';
import 'html_editor.dart';
const InputDecoration EDIT_TEXT_INPUT_DECORATION = InputDecoration(
    fillColor: Colors.white,
    filled:true,
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0)
    ),
    focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink, width:2.0)
    )
);
class AutoForm extends StatefulWidget {
  Map<String, InputInfo> callerMap;
  Map<String, InputInfo> _map;
  Function saveClick;
  Function overrideOnNew;

  AutoForm({this.callerMap, this.overrideOnNew, this.saveClick}) {
    this._map = new Map();
    callerMap.forEach((key, value) {
      _map[key] = value;
    });
    if (overrideOnNew != null) {
      overrideOnNew(_map);
    }
  }

  @override
  _AutoFormState createState() => _AutoFormState();
}

class _AutoFormState extends State<AutoForm> {
  List<TableRow> editBoxes = new List();
  Map<String, TextEditingController> _textEditingControllers = Map();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> simplifyMap(Map<String, InputInfo> usedMap) {
    Map<String, dynamic> result = new Map();
    usedMap.forEach((key, value) {
      result[key] = value.value;
    });
    return result;
  }

  final SizedBox divider = SizedBox(
    width: 20,
  );
  final Color disabledColor = Colors.grey[400];

  @override
  void dispose() {
    _textEditingControllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    widget._map.forEach((key, value) {
      if (value.datatype == Datatype.html) {
        _textEditingControllers[key] =
            TextEditingController(text: value.value ?? "");
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    editBoxes.clear();
    widget._map.forEach((key, value) {
      dynamic result;
      switch (value.datatype) {
        case Datatype.string:
          result = TextFormField(
            enabled: value.canUpdate,
            initialValue: value.value,
            decoration: EDIT_TEXT_INPUT_DECORATION.copyWith(
                fillColor: value.canUpdate ? Colors.white : disabledColor),
            validator: (val) =>
                value.validator == null ? null : value.validator(val),
            obscureText: false,
            onChanged: (val) {
              value.value = val;
            },
          );
          break;
        case Datatype.html:
          result = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: TextFormField(
                  controller: _textEditingControllers[key],
                  decoration: EDIT_TEXT_INPUT_DECORATION,
                  maxLines: 1,
                  validator: (val) =>
                      value.validator == null ? null : value.validator(val),
                  obscureText: false,
                  enabled: false,
                ),
              ),
              divider,
              createButton(
                () async {
                  String result = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                    return HtmlEditor(value.value);
                  }));
                  if (result == null || result.isEmpty) {
                    return;
                  }
                  setState(() {
                    value.value = result;
                  });

                  _textEditingControllers[key].value =
                      _textEditingControllers[key].value.copyWith(text: result);
                },
                iconData: Icons.edit,
              ),
              divider,
              createButton(
                null,
                iconData: Icons.content_paste,
              )
            ],
          );
          break;
        case Datatype.int:
          result = TextFormField(
              enabled: value.canUpdate,
              initialValue: value.value.toString(),
              decoration: EDIT_TEXT_INPUT_DECORATION,
              validator: (val) =>
                  value.validator == null ? null : value.validator(val),
              obscureText: false,
              onChanged: (val) {
                value.value = int.parse(val);
              },
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly
              ]);
          break;
        case Datatype.timestamp:
          result = Text(value.value.toDate().toString());
          break;
      }
      if (result != null) {
        editBoxes.add(
          TableRow(children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Text(value.hint),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20), child: result),
            ),
          ]),
        );
      }
    });
    return Scaffold(
        appBar: AppBar(
          actions: [
            createButton(() {
              if (!_formKey.currentState.validate()) {
                return;
              }
              widget.saveClick(simplifyMap(widget._map));
              Navigator.pop(context);
            },
                regularColor: Colors.transparent,
                iconData: Icons.save,
                title: 'Save')
          ],
        ),
        backgroundColor: Colors.brown[100],
        body: SingleChildScrollView(
          child: Center(
            child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Container(
                  height: 900,
                  child: Form(
                    key: _formKey,
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: {0: IntrinsicColumnWidth()},
                      children: editBoxes,
                    ),
                  ),
                )),
          ),
        ));
  }
}
