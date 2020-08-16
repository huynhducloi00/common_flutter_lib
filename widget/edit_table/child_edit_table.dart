import 'package:canxe/common/data/cloud_obj.dart';
import 'package:canxe/common/loadingstate/loading_stream_builder.dart';
import 'package:canxe/common/utils.dart';
import 'package:canxe/common/widget/edit_table/child_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canxe/fake_files/no_op_create_pdf.dart'
    if (dart.library.html) 'package:canxe/pdf/pdf_creator.dart' as create_pdf;
import '../../../constants.dart';
import '../../data/cloud_table.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class SelectedIndexChangeNotifier extends ValueNotifier<int> {
  SelectedIndexChangeNotifier(int value) : super(value);
}

class ChildEditTable<SchemaAndData> extends StatefulWidget {
  CollectionReference databaseRef;

  ChildEditTable(this.databaseRef);

  @override
  _ChildEditTableState createState() => _ChildEditTableState();
}

class _ChildEditTableState
    extends StreamStatefulChildState<ChildEditTable, SchemaAndData> {
  SelectedIndexChangeNotifier _selectedIndexChangeNotifier =
      SelectedIndexChangeNotifier(null);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget delegateBuild(BuildContext context) {
    _selectedIndexChangeNotifier.value = null;
    ParentParam parentParam = Provider.of<ParentParam>(context, listen: false);
    var schemaAndData = data;
    TableWidthAndSize tableWidthAndSize = getEditTableColWidths(
        context, schemaAndData.cloudTableSchema.inputInfoMap);
    return Material(
      child: ChangeNotifierProvider(
          create: (BuildContext context) {
            return _selectedIndexChangeNotifier;
          },
          child: Column(children: [
            Container(
                width: tableWidthAndSize.width,
                child: Consumer<SelectedIndexChangeNotifier>(
                  builder: (BuildContext context,
                      SelectedIndexChangeNotifier selectedIndexNotifier,
                      Widget child) {
                    return Table(
                        columnWidths: tableWidthAndSize.colWidths,
                        border: TableBorder(
                            top: EDIT_TABLE_BORDER_SIDE,
                            bottom: EDIT_TABLE_BORDER_SIDE,
                            horizontalInside: EDIT_TABLE_BORDER_SIDE),
                        children:
                            schemaAndData.data.asMap().entries.map((entry) {
                          int index = entry.key;
                          var eachRowMap = entry.value;
                          var dataRow = TableRow(
                              children: schemaAndData
                                  .cloudTableSchema.inputInfoMap.keys
                                  .map((field) => TableCell(
                                          child: InkWell(
                                        onTap: () {
                                          selectedIndexNotifier.value = index;
                                        },
                                        child: Container(
                                          color: index ==
                                                  selectedIndexNotifier.value
                                              ? Colors.red[50]
                                              : Colors.white,
                                          alignment: schemaAndData
                                                      .cloudTableSchema
                                                      .inputInfoMap[field]
                                                      .dataType ==
                                                  DataType.int
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Text(
                                            toText(
                                                    context,
                                                    eachRowMap
                                                        .dataMap[field]) ??
                                                '',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )))
                                  .toList());
                          return dataRow;
                        }).toList());
                  },
                )),
            Consumer<DatabasePagerNotifier>(builder: (BuildContext context,
                DatabasePagerNotifier databasePagerNotifier, Widget child) {
              return Consumer<SelectedIndexChangeNotifier>(builder:
                  (BuildContext context,
                      SelectedIndexChangeNotifier selectedIndexChangeNotifier,
                      Widget child) {
//                print(
//                    '${isLoading} ${parentParam.sortKeyDescending} ${schemaAndData.data.first.dataMap[parentParam.sortKey]}');
//                  ' ${StackTrace.current}');
                if (schemaAndData.data.length == 0) {
                  return CommonButton.getButton(context, () {
                    databasePagerNotifier.value = ChildParam();
                  }, title: 'Về trang đầu');
                }
                var beforeQuery =
                    applyFilterToQuery(widget.databaseRef, parentParam)
                        .orderBy(parentParam.sortKey,
                            descending: parentParam.sortKeyDescending)
                        .endBefore([
                  schemaAndData.data.first.dataMap[parentParam.sortKey]
                ]).limit(1) as Query;
                var afterQuery =
                    applyFilterToQuery(widget.databaseRef, parentParam)
                        .orderBy(parentParam.sortKey,
                            descending: parentParam.sortKeyDescending)
                        .startAfter([
                  schemaAndData.data.last.dataMap[parentParam.sortKey]
                ]).limit(1) as Query;
                return Column(children: [
                  SizedBox(
                    width: screenWidth(context) * 0.3,
                    height: screenHeight(context) * 0.1,
                    child: tableOfTwo({
                      'Trường sắp xếp':
                          '${schemaAndData.cloudTableSchema.inputInfoMap[parentParam.sortKey].fieldDes}-${parentParam.sortKeyDescending ? "Giảm dần" : "Tăng dần"}',
                      'Hiển thị sau': toText(
                          context, databasePagerNotifier.value.startAfter),
                      'Hiển thị trước': toText(
                          context, databasePagerNotifier.value.endBefore),
                      'Số lượng hiển thị': '${schemaAndData.data.length}',
                    }, boldRight: true),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamProvider<bool>.value(
                        value: isLoading
                            ? Stream<bool>.value(false)
                            : beforeQuery.snapshots().map((event) {
                                return event.documents.length > 0;
                              }),
                        child: Builder(
                          builder: (BuildContext context) {
                            bool existBefore =
                                Provider.of<bool>(context) ?? false;
                            return CommonButton.getButton(context, () {
                              // go back
                              databasePagerNotifier.value = ChildParam(
                                  endBefore: schemaAndData
                                      .data.first.dataMap[parentParam.sortKey]);
                            },
                                title: "",
                                iconData:
                                    existBefore ? Icons.navigate_before : null,
                                isEnabled: existBefore);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      StreamProvider<bool>.value(
                        value: isLoading
                            ? Stream<bool>.value(false)
                            : afterQuery
                                .snapshots()
                                .map((event) => event.documents.length > 0),
                        child: Builder(builder: (BuildContext context) {
                          bool existAfter = Provider.of<bool>(context) ?? false;
                          return CommonButton.getButton(context, () {
                            // go forward
                            databasePagerNotifier.value = ChildParam(
                                startAfter: schemaAndData
                                    .data.last.dataMap[parentParam.sortKey]);
                          },
                              title: "",
                              iconData: existAfter ? Icons.navigate_next : null,
                              isEnabled: existAfter);
                        }),
                      ),
                    ],
                  ),
                ]);
              });
            }),
            SizedBox(
              height: 20,
            ),
            Consumer<SelectedIndexChangeNotifier>(builder:
                (BuildContext context,
                    SelectedIndexChangeNotifier selectedIndexChangeNotifier,
                    Widget child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  printDefault(schemaAndData, parentParam),
                  newButton(schemaAndData),
                  editButton(schemaAndData, selectedIndexChangeNotifier),
                  deleteButton(schemaAndData, selectedIndexChangeNotifier)
                ],
              );
            })
          ])),
    );
  }

  Widget printDefault(
          SchemaAndData oldSchemaAndData, ParentParam parentParam) {
    return CommonButton.getButtonAsync(context, () async {
      var allQuery = applyFilterToQuery(widget.databaseRef, parentParam)
          .orderBy(parentParam.sortKey,
          descending: parentParam.sortKeyDescending) as Query;
      allQuery.getDocuments().then((querySnapshot) async {
        var creator = create_pdf.PdfCreator();
        await creator.init();
        List<CloudObject> data = querySnapshot.documents
            .map((e) => CloudObject(e.documentID, e.data))
            .toList();
        var newSchemaAndData = SchemaAndData<CloudObject>(
            oldSchemaAndData.cloudTableSchema, data);
        await creator.createPdfSummary(
            context, '', DateTime.now(), newSchemaAndData);
      });
    }, title: 'In mặc định', iconData: Icons.print);
  }
  Widget newButton(schemaAndData) => CommonButton.getButton(context, () {
        AlertDialog alert = AlertDialog(
          content:
              AutoForm.createAutoForm(context, schemaAndData.inputInfoMap, {},
                  saveClickFuture: (resultMap) {
            return widget.databaseRef.document().setData(resultMap);
          }),
        );
        showDialog(
            context: context,
            builder: (_) {
              return alert;
            });
      }, title: 'Mới', iconData: Icons.create);

  Widget editButton(SchemaAndData schemaAndData, selectedIndexChangeNotifier) {
    return CommonButton.getButton(context, () {
      AlertDialog alert = AlertDialog(
        content: AutoForm.createAutoForm(
          context,
          schemaAndData.cloudTableSchema.inputInfoMap,
          schemaAndData.data[selectedIndexChangeNotifier.value].dataMap,
          saveClickFuture: (resultMap) async {
            await widget.databaseRef
                .document(schemaAndData
                    .data[selectedIndexChangeNotifier.value].documentId)
                .setData(resultMap);
          },
        ),
      );
      showDialog(
          context: context,
          builder: (_) {
            return alert;
          });
    },
        title: "Chỉnh sửa",
        isEnabled: selectedIndexChangeNotifier.value != null);
  }

  Widget deleteButton(schemaAndData, selectedIndexChangeNotifier) =>
      CommonButton.getButton(context, () {
        AlertDialog alert = AlertDialog(
          actions: [
            CommonButton.getButtonAsync(context, () async {
              await widget.databaseRef
                  .document(schemaAndData
                      .data[selectedIndexChangeNotifier.value].documentId)
                  .delete();
              Navigator.of(context).pop();
            }, title: 'Có'),
            CommonButton.getCloseButton(context, 'Không')
          ],
          content: Text(
              'Bạn thật sự muốn xoá ${schemaAndData.data[selectedIndexChangeNotifier.value].dataMap[schemaAndData.inputInfoMap.keys.elementAt(0)]}?'),
        );
        showDialog(
            context: context,
            builder: (_) {
              return alert;
            });
      }, title: "Xoá", isEnabled: selectedIndexChangeNotifier.value != null);
}
