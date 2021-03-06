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
  static Widget printButton(context,CollectionReference databaseRef, PrintInfo printInfo,
      ParentParam fallBackParentParam,
      {isDense = false, Color backgroundColor}) {
    return CommonButton.getButtonAsync(context, () async {
      var parentParam = printInfo.parentParam ?? fallBackParentParam;
      var allQuery = applyFilterToQuery(databaseRef, parentParam).orderBy(
          parentParam.sortKey,
          descending: parentParam.sortKeyDescending) as Query;
      return allQuery.getDocuments().then((querySnapshot) async {
        var creator = create_pdf.PdfCreator();
        await creator.init();
        List<CloudObject> data = querySnapshot.documents
            .map((e) => CloudObject(e.documentID, e.data))
            .toList();
        SchemaAndData.fillInCalculatedData(data, printInfo.inputInfoMap);
        parentParam.filterDataWrappers.forEach((fieldName, filter) {
          if (filter.postFilterFunction != null) {
            data = data
                .where((row) => filter.postFilterFunction(row.dataMap))
                .toList();
          }
        });
        data.forEach((row) {
          row.dataMap = SchemaAndData.fillInOptionData(
              row.dataMap, printInfo.inputInfoMap.map);
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
      {isDense = false, Color backgroundColor}) {
    return CommonButton.getButtonAsync(context, () async {},
        title: printInfo.buttonTitle,
        iconData: Icons.print,
        isDense: isDense,
        regularColor: backgroundColor);
  }

  static void initiateNew(
      context, CollectionReference databaseRef, InputInfoMap inputInfoMap,
      {bool isPhone = false, Map<String, dynamic> initialValues}) {
    var autoForm =
        AutoForm.createAutoForm(context, inputInfoMap, initialValues ?? {},
            saveClickFuture: (resultMap) {
      return databaseRef.document().setData(resultMap);
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
          {bool isPhone = false, Map<String, dynamic> initialValues, title='Mới'}) =>
      CommonButton.getButton(context, () {
        initiateNew(context, databaseRef, inputInfoMap,
            isPhone: isPhone, initialValues: initialValues);
      }, title: title, iconData: Icons.wallpaper);

  static Widget editButton(
      context, databaseRef, SchemaAndData schemaAndData, int rowIndex,
      {bool isPhone = false}) {
    return CommonButton.getButton(context, () {
      if (isPhone) popWindow(context);
      var map = schemaAndData.cloudTableSchema.inputInfoMap.map;
      if (schemaAndData.cloudTableSchema.showDocumentId) {
        map = Map.fromEntries([
              MapEntry(
                  CloudTableSchema.DOCUMENT_ID_FIELD,
                  InputInfo(DataType.string,
                      fieldDes: 'Mã', canUpdate: false, needSaving: false))
            ] +
            map.entries.toList());
      }
      var autoForm = AutoForm.createAutoForm(
        context,
        schemaAndData.cloudTableSchema.inputInfoMap.cloneInputInfoMap(map),
        schemaAndData.data[rowIndex].dataMap,
        saveClickFuture: (resultMap) async {
          await databaseRef
              .document(schemaAndData.data[rowIndex].documentId)
              .setData(resultMap);
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
    }, title: "Chỉnh sửa", iconData: Icons.edit, isEnabled: rowIndex != null);
  }

  static Widget deleteButton(
          context, databaseRef, SchemaAndData schemaAndData, int rowIndex) =>
      CommonButton.getButton(context, () {
        popWindow(context);
        showAlertDialog(context, actions: [
          CommonButton.getButtonAsync(context, () async {
            await databaseRef
                .document(schemaAndData.data[rowIndex].documentId)
                .delete();
            popWindow(context);
          }, title: 'Có'),
          CommonButton.getCloseButton(context, 'Không')
        ], builder: (_) {
          return Text(
              'Bạn thật sự muốn xoá ${toText(context, schemaAndData.data[rowIndex].dataMap[schemaAndData.cloudTableSchema.inputInfoMap.map.keys.elementAt(0)])}?');
        });
      },
          title: "Xoá",
          isEnabled: rowIndex != null,
          iconData: Icons.delete_forever);

  static Widget printLineButton(
      BuildContext context, PrintTicket printTicket, Map data, bool isEnabled) {
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
