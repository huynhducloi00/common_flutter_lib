import '../../utils.dart';

import '../../data/cloud_obj.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// import '../../pdf/no_op_create_pdf.dart'
//     if (dart.library.html) '../../pdf/pdf_creator.dart' as create_pdf;
import '../../pdf/pdf_creator.dart' as create_pdf;
import '../../data/cloud_table.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'parent_param.dart';

class ChildTableUtils {
  static String reportTitle = '';
  static String reportSubtitle = '';

  static Widget printButton(context, CollectionReference databaseRef,
      PrintInfo printInfo, ParentParam? fallBackParentParam,
      {isDense = false, Color? backgroundColor}) {
    return CommonButton.getButtonAsync(context, () async {
      var parentParam = printInfo.parentParam ?? fallBackParentParam!;
      var allQuery = applyFilterToQuery(databaseRef, parentParam).orderBy(
          parentParam.sortKey,
          descending: parentParam.sortKeyDescending) as Query;
      return allQuery.get().then((querySnapshot) async {
        var creator = create_pdf.PdfCreator();
        await creator.init();
        List<CloudObject> data = querySnapshot.docs
            .map((e) => CloudObject(e.id, e.data() as Map<String, dynamic>))
            .toList();
        SchemaAndData.fillInCalculatedData(data, printInfo.inputInfoMap);
        parentParam.filterDataWrappers!.forEach((fieldName, filter) {
          if (filter!.postFilterFunction != null) {
            data = data
                .where((row) => filter.postFilterFunction!(row.dataMap))
                .toList();
          }
        });
        data.forEach((row) {
          row.dataMap = SchemaAndData.fillInOptionData(
              row.dataMap, printInfo.inputInfoMap.map) as Map<String, dynamic>;
        });
        await creator.createPdfSummary(
            context, DateTime.now(), printInfo, data);
      });
    },
        title: printInfo.buttonTitle,
        iconData: Icons.print,
        isDense: isDense,
        regularColor: backgroundColor);
  }

  static Widget printCurrent(context, PrintInfo printInfo, Map dataMap,
      {isDense = false, Color? backgroundColor}) {
    return CommonButton.getButtonAsync(context, () async {},
        title: printInfo.buttonTitle,
        iconData: Icons.print,
        isDense: isDense,
        regularColor: backgroundColor);
  }

  static void initiateNew(
      context, CollectionReference databaseRef, InputInfoMap inputInfoMap,
      {bool isPhone = false, Map<String, dynamic>? initialValues}) {
    var autoForm =
        AutoForm.createAutoForm(context, inputInfoMap, initialValues ?? {},
            saveClickFuture: (resultMap) {
      return databaseRef.doc().set(resultMap);
    }, isNew: true);
    if (isPhone) {
      Navigator.push(
          context,
          createMaterialPageRoute(context, (_) {
            return autoForm;
          }));
    } else {
      showAlertDialog(context, builder: (_) {
        return autoForm;
      }, percentageWidth: 0.8);
    }
  }

  static Widget newButton(
      context, CollectionReference databaseRef, InputInfoMap inputInfoMap,
      {bool isPhone = false,
      title = 'Mới'}) {
    return CommonButton.getButton(context, () {
      Map<String,dynamic> initialData = {};
      inputInfoMap.map!.forEach((key, value) {
        if (value.onNewData != null) {
          initialData[key] = value.onNewData!();
        }
      });
      initiateNew(context, databaseRef, inputInfoMap,
          isPhone: isPhone,
          initialValues: initialData.isEmpty ? null : initialData);
    }, title: title, iconData: Icons.wallpaper);
  }

  static Widget duplicate(
      context, databaseRef, SchemaAndData schemaAndData, List<int> rowIndices,
      {bool isPhone = false}) {
    return CommonButton.getButton(context, () {
      initiateNew(
          context, databaseRef, schemaAndData.cloudTableSchema.inputInfoMap,
          isPhone: isPhone,
          initialValues: schemaAndData.data[rowIndices[0]].dataMap);
    },
        title: "Duplicate",
        iconData: Icons.accessible_forward_outlined,
        isEnabled: rowIndices.length == 1);
  }

  static Widget editButton(
      context, databaseRef, SchemaAndData schemaAndData, List<int> rowIndices,
      {bool isPhone = false}) {
    return CommonButton.getButton(context, () {
      if (isPhone) popWindow(context);
      var map = schemaAndData.cloudTableSchema.inputInfoMap.map;
      if (schemaAndData.cloudTableSchema.showDocumentId) {
        map = Map.fromEntries([
              MapEntry(
                  CloudTableSchema.documentIdField,
                  InputInfo(DataType.string,
                      fieldDes: 'Mã', canUpdate: false, needSaving: false))
            ] +
            map!.entries.toList());
      }
      var autoForm = AutoForm.createAutoForm(
        context,
        schemaAndData.cloudTableSchema.inputInfoMap.cloneInputInfoMap(map),
        schemaAndData.data[rowIndices[0]].dataMap,
        saveClickFuture: (resultMap) async {
          await (databaseRef as CollectionReference)
              .doc(schemaAndData.data[rowIndices[0]].documentId)
              .set(resultMap);
        },
      );
      if (isPhone) {
        // use full screen for phone
        Navigator.push(
            context,
            createMaterialPageRoute(context, (_) {
              return autoForm;
            }));
      } else {
        showAlertDialog(context, builder: (_) {
          return autoForm;
        }, percentageWidth: 0.8);
      }
    },
        title: "Chỉnh sửa",
        iconData: Icons.edit,
        isEnabled: rowIndices.length == 1);
  }

  static Widget deleteButton(context, CollectionReference databaseRef,
          SchemaAndData schemaAndData, List<int> rowIndices,
          {bool toPopWindow = true}) =>
      CommonButton.getButton(context, () {
        if (toPopWindow) {
          popWindow(context);
        }
        showAlertDialog(context, actions: [
          CommonButton.getButtonAsync(context, () async {
            await Future.wait(rowIndices.map((index) => databaseRef
                .doc(schemaAndData.data[index].documentId)
                .delete()));
            popWindow(context);
          }, title: 'Có'),
          CommonButton.getCloseButton(context, 'Không')
        ], builder: (_) {
          var items = rowIndices
              .map((index) => toText(
                  context,
                  schemaAndData.data[index].dataMap[schemaAndData
                      .cloudTableSchema.inputInfoMap.map!.keys
                      .elementAt(0)]))
              .toList()
              .asMap()
              .entries
              .map((e) => "${e.key}.\"${e.value}\"");
          return Text(
              'Bạn thật sự muốn xoá ${rowIndices.length} items?\n${items.join('\n')}');
        });
      },
          title: "Xoá",
          isEnabled: rowIndices.isNotEmpty,
          iconData: Icons.delete_forever);

  static Widget printLineButton(BuildContext context, PrintTicket? printTicket,
      Map? data, bool isEnabled) {
    return CommonButton.getButtonAsync(context, () async {
      var creator = create_pdf.PdfCreator();
      await creator.init();
      await creator.createPdfTicket(context, DateTime.now(), printTicket, data);
    }, title: 'In dòng', isEnabled: isEnabled, iconData: Icons.line_style);
  }
}

class DataPickerBundle {
  String fieldName;

  DataPickerBundle(this.fieldName);
}
