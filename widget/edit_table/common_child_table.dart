import '../../data/cloud_obj.dart';
import '../../loadingstate/loading_stream_builder.dart';
import '../../utils.dart';
import '../../widget/edit_table/child_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pdf/no_op_create_pdf.dart'
    if (dart.library.html) '../../pdf/pdf_creator.dart' as create_pdf;
import '../../data/cloud_table.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class ChildTableUtils {
  static Widget printDefault(context, databaseRef, PrintInfo printInfo,
      ParentParam fallBackParentParam) {
    return CommonButton.getButtonAsync(context, () async {
      var parentParam = printInfo.parentParam ?? fallBackParentParam;
      var allQuery = applyFilterToQuery(databaseRef, parentParam).orderBy(
          parentParam.sortKey,
          descending: parentParam.sortKeyDescending) as Query;
      allQuery.getDocuments().then((querySnapshot) async {
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
        SchemaAndData.fillInOptionData(data, printInfo.inputInfoMap);
        await creator.createPdfSummary(
            context, DateTime.now(), printInfo, data);
      });
    }, title: printInfo.buttonTitle, iconData: Icons.print, isDense: true);
  }

  static Widget newButton(context, databaseRef, SchemaAndData schemaAndData) =>
      CommonButton.getButton(context, () {
        showAlertDialog(context, builder: (_) {
          return AutoForm.createAutoForm(
              context, schemaAndData.cloudTableSchema.inputInfoMap, {},
              saveClickFuture: (resultMap) {
            return databaseRef.document().setData(resultMap);
          });
        });
      }, title: 'Mới', iconData: Icons.create);

  static Widget editButton(context, databaseRef, SchemaAndData schemaAndData,
      int rowIndex) {
    return CommonButton.getButton(context, () {
      showAlertDialog(context, builder: (_) {
        return AutoForm.createAutoForm(
          context,
          schemaAndData.cloudTableSchema.inputInfoMap,
          schemaAndData.data[rowIndex].dataMap,
          saveClickFuture: (resultMap) async {
            await databaseRef
                .document(schemaAndData
                    .data[rowIndex].documentId)
                .setData(resultMap);
          },
        );
      });
    },
        title: "Chỉnh sửa",
        isEnabled: rowIndex != null);
  }

  static Widget deleteButton(context, databaseRef, SchemaAndData schemaAndData,
          int rowIndex) =>
      CommonButton.getButton(context, () {
        showAlertDialog(context, actions: [
          CommonButton.getButtonAsync(context, () async {
            await databaseRef
                .document(schemaAndData
                    .data[rowIndex].documentId)
                .delete();
            Navigator.of(context).pop();
          }, title: 'Có'),
          CommonButton.getCloseButton(context, 'Không')
        ], builder: (_) {
          return Text(
              'Bạn thật sự muốn xoá ${schemaAndData.data[rowIndex].dataMap[schemaAndData.cloudTableSchema.inputInfoMap.keys.elementAt(0)]}?');
        });
      }, title: "Xoá", isEnabled: rowIndex != null);
}
