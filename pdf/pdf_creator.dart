import 'dart:async';

import 'package:banhang/data/cart_data.dart';
import 'package:banhang/data/repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

import '../data/cloud_obj.dart';
import '../data/cloud_table.dart';
import '../utils.dart';
import '../utils/html/html_no_op.dart'
    if (dart.library.html) '../utils/html/html_utils.dart' as html_utils;
import 'pdf_interface.dart';
import 'pdf_utils.dart';

class GroupByKey {
  List<dynamic> values;

  GroupByKey(this.values);

  @override
  int get hashCode => values.hashCode;

  @override
  bool operator ==(other) =>
      other is GroupByKey && (listEquals(other.values, values));

  @override
  String toString() {
    return values.toString();
  }
}

class PdfCreator extends PdfCreatorInterface {
  static final _columnGap = pw.SizedBox(height: 15);
  static const HORIZONTAL_FIRST_PAGE_LIMIT = 32;
  static const HORIZONTAL_OTHER_PAGE_LIMIT = 37;
  static const VERTICAL_FIRST_PAGE_LIMIT = 50;
  static const VERTICAL_OTHER_PAGE_LIMIT = 55;

  @override
  Future init() async {
    return PdfUtils.init();
  }

  Future<void> generateInvoice(
      BuildContext buildContext, Cart cart, List<CartItem> items) async {
    final Document pdf = Document();

    // Load the logo from assets
    final logo = pw.MemoryImage(
      (await rootBundle.load('lib/common/assets/hiep_hung_logo.png'))
          .buffer
          .asUint8List(),
    );

    // Load repository items
    final repositoryItems =
        await RepositoryCloudTable.convertFromCartItems(items);

    // Nhóm CartItem theo id nếu group == true
    final groupedItems = <String, List<CartItem>>{};
    for (final cartItem in items) {
      final repo = repositoryItems.firstWhere(
        (r) => r.id == cartItem.id,
        orElse: () => RepositoryItem('', {}),
      );
      if (repo.group == true) {
        groupedItems.putIfAbsent(cartItem.id, () => []).add(cartItem);
      }
    }

    // Danh sách để hiển thị
    final displayItems = <dynamic>[];
    for (final cartItem in items) {
      final repo = repositoryItems.firstWhere(
        (r) => r.id == cartItem.id,
        orElse: () => RepositoryItem('', {}),
      );

      if (repo.group != true || !groupedItems.containsKey(cartItem.id)) {
        displayItems.add(cartItem);
      } else if (!displayItems.any(
        (it) => it is List<CartItem> && it.first.id == cartItem.id,
      )) {
        displayItems.add(groupedItems[cartItem.id]!);
      }
    }

    // Kiểm tra xem có item nào có isTonCategory == true không
    final hasTonCategory = items.any((item) => item.isTonCategory == true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20), // ✅ padding all 4 cạnh
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 70, width: 70, child: pw.Image(logo)),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    PdfUtils.textRegular("Công Ty TNHH Tôn Thép Hiệp Hưng"),
                    PdfUtils.textLight(
                        "Số 418, Đường ĐT 764, Tổ 1, Ấp 8, Xã Xuân Đông, Tỉnh Đồng Nai"),
                    PdfUtils.textLight("MST: 3603527994"),
                    PdfUtils.textLight("ĐT: 0913080402 – 0838812552"),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Invoice Title
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(children: [
                  PdfUtils.textLight("Ngày:"),
                  PdfUtils.textLight(
                      " ${DateFormat('dd/MM/yyyy').format(cart.dateCreated)}"),
                ]),
                pw.TableRow(children: [
                  pw.SizedBox(height: 5),
                ]),
                pw.TableRow(children: [
                  PdfUtils.textLight("Số phiếu:"),
                  PdfUtils.textLight(
                      " ${(cart.documentId != null) ? cart.documentId : ''}"),
                ]),
                pw.TableRow(children: [
                  pw.SizedBox(height: 5),
                ]),
                pw.TableRow(children: [
                  PdfUtils.textLight("Khách hàng:"),
                  PdfUtils.textLight(" ${cart.customerName}"),
                ]),
              ],
            ),

            // pw.Divider(height: 20),
            pw.SizedBox(height: 20),

            // --- Merged Items Table ---
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: hasTonCategory
                  ? const <int, pw.TableColumnWidth>{
                      0: pw.FlexColumnWidth(5), // STT
                      1: pw.FlexColumnWidth(12.5), // Mã mặt hàng
                      2: pw.FlexColumnWidth(25), // Tên mặt hàng
                      3: pw.FlexColumnWidth(12.5), // Note
                      4: pw.FlexColumnWidth(5), // Đơn vị
                      5: pw.FlexColumnWidth(5), // Số tấm
                      6: pw.FlexColumnWidth(5), // Số m/tấm
                      7: pw.FlexColumnWidth(5), // SL Lượng
                      8: pw.FlexColumnWidth(12.5), // Đơn giá
                      9: pw.FlexColumnWidth(12.5), // Thành tiền
                    }
                  : const <int, pw.TableColumnWidth>{
                      0: pw.FlexColumnWidth(5), // STT
                      1: pw.FlexColumnWidth(12.5), // Mã mặt hàng
                      2: pw.FlexColumnWidth(25), // Tên mặt hàng
                      3: pw.FlexColumnWidth(12.5), // Note
                      4: pw.FlexColumnWidth(5), // Đơn vị
                      5: pw.FlexColumnWidth(5), // SL Lượng
                      6: pw.FlexColumnWidth(12.5), // Đơn giá
                      7: pw.FlexColumnWidth(12.5), // Thành tiền
                    },
              children: [
                // --- Table Header ---
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: (hasTonCategory
                          ? [
                              'STT',
                              'Mã Mặt Hàng',
                              'Tên Mặt hàng',
                              'Note',
                              'ĐVT',
                              'Tấm',
                              'Mét/Tấm',
                              'SL',
                              'Đơn giá (Đồng/DVT)',
                              'Thành tiền (Đồng)',
                            ]
                          : [
                              'STT',
                              'Mã Mặt Hàng',
                              'Tên Mặt hàng',
                              'Note',
                              'ĐVT',
                              'SL',
                              'Đơn giá (Đồng/DVT)',
                              'Thành tiền (Đồng)',
                            ])
                      .map((header) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: pw.Center(
                              child: PdfUtils.textBold(header),
                            ),
                          ))
                      .toList(),
                ),
                // --- Table Rows ---
                ...displayItems.asMap().entries.expand((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;

                  if (item is CartItem) {
                    // Item đơn
                    return [
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(child: PdfUtils.textLight('$idx')),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.centerLeft,
                            padding: pw.EdgeInsets.all(4),
                            child: PdfUtils.textLight(item.id),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.centerLeft,
                            padding: pw.EdgeInsets.all(4),
                            child: PdfUtils.textLight(item.name ?? ''),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            child: PdfUtils.textLight(item.tonNote ?? ''),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: PdfUtils.textLight(item.unitName),
                            ),
                          ),
                          if (hasTonCategory) ...[
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: PdfUtils.textLight(
                                  item.isTonCategory == true
                                      ? item.soLuongTam.toStringAsFixed(0)
                                      : '',
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: PdfUtils.textLight(
                                  item.isTonCategory == true
                                      ? item.soLuongMet.toStringAsFixed(0)
                                      : '',
                                ),
                              ),
                            ),
                          ],
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: PdfUtils.textLight(
                                item.quantity.toStringAsFixed(0),
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.centerRight,
                            child: PdfUtils.textLight(
                              formatNumber(
                                item.unitPrice.toInt(),
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.centerRight,
                            child: PdfUtils.textLight(
                              formatNumber(item.totalPrice.toInt()),
                            ),
                          ),
                        ],
                      ),
                    ];
                  } else if (item is List<CartItem>) {
                    // Nhóm item
                    final groupItems = item;
                    final repo = repositoryItems.firstWhere(
                      (r) => r.id == groupItems.first.id,
                      orElse: () => RepositoryItem('', {}),
                    );

                    final rows = <pw.TableRow>[];

                    for (int i = 0; i < groupItems.length; i++) {
                      final ci = groupItems[i];
                      rows.add(
                        pw.TableRow(
                          decoration: i < groupItems.length - 1
                              ? const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: PdfColors.white, // mờ hơn
                                      width: 0.5,
                                    ),
                                  ),
                                )
                              : null,
                          children: [
                            if (i == 0)
                              pw.Container(
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: pw.Center(
                                    child: PdfUtils.textLight('$idx'),
                                  ),
                                ),
                              )
                            else
                              pw.SizedBox(),
                            if (i == 0)
                              pw.Container(
                                padding: pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.centerLeft,
                                child: PdfUtils.textLight(repo.id),
                              )
                            else
                              pw.SizedBox(),
                            if (i == 0)
                              pw.Container(
                                padding: pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.centerLeft,
                                child: PdfUtils.textLight(repo.name ?? ''),
                              )
                            else
                              pw.SizedBox(),
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: PdfUtils.textLight(ci.tonNote ?? ''),
                              ),
                            ),
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: PdfUtils.textLight(ci.unitName),
                              ),
                            ),
                            if (hasTonCategory) ...[
                              pw.Container(
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: PdfUtils.textLight(
                                    ci.isTonCategory == true
                                        ? ci.soLuongTam.toStringAsFixed(0)
                                        : '',
                                  ),
                                ),
                              ),
                              pw.Container(
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: PdfUtils.textLight(
                                    ci.isTonCategory == true
                                        ? ci.soLuongMet.toStringAsFixed(0)
                                        : '',
                                  ),
                                ),
                              ),
                            ],
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: PdfUtils.textLight(
                                  ci.quantity.toStringAsFixed(0),
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              alignment: pw.Alignment.centerRight,
                              child: PdfUtils.textLight(
                                  formatNumber(ci.unitPrice.toInt())),
                            ),
                            pw.Container(
                              padding: pw.EdgeInsets.all(4),
                              alignment: pw.Alignment.centerRight,
                              child: PdfUtils.textLight(
                                  formatNumber(ci.totalPrice.toInt())),
                            ),
                          ],
                        ),
                      );
                    }

                    return rows;
                  }

                  return const <pw.TableRow>[];
                }),
              ],
            ),

            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
              },
              border: pw.TableBorder.all(width: 1, color: PdfColors.black),
              children: [
                // Hàng 1: Tổng tiền
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      alignment: pw.Alignment.centerLeft,
                      child: PdfUtils.textLight('Tổng tiền'),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      alignment: pw.Alignment.centerRight,
                      child: PdfUtils.textLight(
                          formatNumber(cart.totalPrice.toInt())),
                    ),
                  ],
                ),

                // Hàng 2: Đã thanh toán
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      alignment: pw.Alignment.centerLeft,
                      child: PdfUtils.textLight('Đã thanh toán'),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      alignment: pw.Alignment.centerRight,
                      child: PdfUtils.textLight(
                          formatNumber(cart.paidNumber.toInt())),
                    ),
                  ],
                ),

                // Hàng 3: Công nợ
                // pw.TableRow(
                //   children: [
                //     pw.Container(
                //       padding: const pw.EdgeInsets.symmetric(
                //         horizontal: 6,
                //         vertical: 4,
                //       ),
                //       alignment: pw.Alignment.centerLeft,
                //       child: PdfUtils.textLight('Nợ cũ'),
                //     ),
                //     pw.Container(
                //       padding: const pw.EdgeInsets.symmetric(
                //         horizontal: 6,
                //         vertical: 4,
                //       ),
                //       alignment: pw.Alignment.centerRight,
                //       //Làm phần công nợ
                //       // child: PdfUtils.textLight(
                //       //     formatNumber(cart.deptNumber.toInt())),
                //       child: PdfUtils.textLight(formatNumber(0)),
                //     ),
                //   ],
                // ),

                // Hàng 4: Còn lại (đậm hơn, font to hơn)
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      alignment: pw.Alignment.centerLeft,
                      child: PdfUtils.textBold('Còn lại', fontSize: 11),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      alignment: pw.Alignment.centerRight,
                      child: PdfUtils.textBold(
                        formatNumber(cart.deptNumber.toInt()),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // pw.Divider(height: 20),
            pw.SizedBox(height: 80),

            // --- Note Section ---
            PdfUtils.textRegular("Lưu ý:"),
            pw.SizedBox(height: 5),
            PdfUtils.textLight(
                "- Quý khách vui lòng kiểm tra kĩ hàng hoá và số lượng trước khi kí nhận."),
            pw.SizedBox(height: 5),
            PdfUtils.textLight(
                "- Vệ sinh bề mặt mái tôn sau thi công để tránh mạt sắt bám vào gây rỉ sét."),
            // Space for writing notes
            pw.Divider(height: 20),

            // --- Signature Section ---
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    PdfUtils.textRegular("Bên mua"),
                    PdfUtils.textLight("(Ký, họ tên)"),
                    pw.SizedBox(height: 60),
                  ],
                ),
                pw.Column(
                  children: [
                    PdfUtils.textRegular("Bên bán"),
                    PdfUtils.textLight("(Ký, họ tên)"),
                    pw.SizedBox(height: 60),
                  ],
                ),
                pw.Column(
                  children: [
                    PdfUtils.textRegular("Người giao hàng"),
                    PdfUtils.textLight("(Ký, họ tên)"),
                    pw.SizedBox(height: 60),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 50),
            PdfUtils.center(
              PdfUtils.textLight('Cảm ơn quý khách và hẹn gặp lại!'),
            ),
          ];
        },
      ),
    );

    // --- Printing logic ---
    final bytes = await pdf.save();
    if (kIsWeb) {
      if (html_utils.HtmlUtils().isSafari()!) {
        (html_utils.HtmlUtils()).downloadWeb(bytes, 'invoice.pdf');
      } else {
        (html_utils.HtmlUtils()).viewBytes(bytes);
      }
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  Future<List<int>> _generatingPdfSummary(
      BuildContext buildContext,
      DateTime timeOfPrint,
      PrintInfo printInfo,
      List<Map<String, dynamic>> data) {
    final Document pdf = pw.Document();
    Map<int, pw.TableColumnWidth> colWidths = Map();
    double sumFraction = 0;

    Map<String, InputInfo?> usedInputInfoMap = printInfo.inputInfoMap
        .filterMap((printInfo.groupByFields ?? []) + printInfo.printFields!);
    usedInputInfoMap.entries.forEach((e) {
      InputInfo inputInfo = e.value!;
      sumFraction += inputInfo.printFlex!;
    });
    usedInputInfoMap.entries.toList().asMap().forEach((key, value) {
      colWidths[key] =
          pw.FractionColumnWidth(value.value!.printFlex! / sumFraction);
    });
    int count = 0;
    var limitFirstPage = printInfo.printVertical
        ? VERTICAL_FIRST_PAGE_LIMIT
        : HORIZONTAL_FIRST_PAGE_LIMIT;
    var limitOtherPage = printInfo.printVertical
        ? VERTICAL_OTHER_PAGE_LIMIT
        : HORIZONTAL_OTHER_PAGE_LIMIT;
    pw.Table header = pw.Table(columnWidths: colWidths, children: [
      pw.TableRow(
          children: usedInputInfoMap.entries
              .map((e) => PdfUtils.textRegular(e.value!.fieldDes))
              .toList())
    ]);
    List<pw.TableRow> tableRows = [];
    List<pw.Table> tables = [];
    Map<String, dynamic> aggregationStatInt = {};
    if (printInfo.groupByFields != null) {
      Map<GroupByKey, Map<String, dynamic>> grouped = {};
      data.forEach((row) {
        GroupByKey groupByKey =
            GroupByKey(printInfo.groupByFields!.map((e) => row[e]).toList());
        Map<String, dynamic> map;
        if (grouped.containsKey(groupByKey)) {
          map = grouped[groupByKey]!;
        } else {
          map = {};
          grouped[groupByKey] = map;
        }
        printInfo.printFields!.forEach((fieldName) {
          if (!printInfo.groupByFields!.contains(fieldName)) {
            if (map[fieldName] == null) {
              map[fieldName] = row[fieldName] ?? 0;
            } else {
              map[fieldName] += row[fieldName] ?? 0;
            }
          }
        });
      });
      data.clear();
      grouped.entries.forEach((e) {
        Map<String, dynamic> newMap = Map.from(e.value);
        printInfo.groupByFields!.asMap().forEach((index, groupedField) {
          newMap[groupedField] = e.key.values[index];
        });
        data.add(newMap);
      });
    }
    data.forEach((row) {
      printInfo.aggregateFields!.forEach((fieldName) {
        if (aggregationStatInt.containsKey(fieldName)) {
          aggregationStatInt[fieldName] =
              sum([aggregationStatInt[fieldName], row[fieldName]]);
        } else {
          aggregationStatInt[fieldName] = row[fieldName] ?? 0;
        }
      });
      count++;
      tableRows.add(pw.TableRow(
          children: usedInputInfoMap.keys.map((fieldName) {
        return PdfUtils.textLight(toText(buildContext, row[fieldName]) ?? "",
            maxLine: 1);
      }).toList()));
      if ((tables.isEmpty && count == limitFirstPage) ||
          (tables.isNotEmpty && count == limitOtherPage)) {
        tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
        count = 0;
        tableRows = [];
      }
    });
    if (tableRows.isNotEmpty) {
      tables.add(pw.Table(columnWidths: colWidths, children: tableRows));
    }
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        orientation: printInfo.printVertical
            ? pw.PageOrientation.natural
            : pw.PageOrientation.landscape,
        footer: (pw.Context context) {
          return pw.Container(
              alignment: pw.Alignment.centerRight,
              child: PdfUtils.textLight(
                '${context.pageNumber} / ${context.pagesCount}',
              ));
        },
        build: (pw.Context context) {
          List<pw.Widget> children = [];
          children.addAll([
            PdfUtils.textRegular("Test"),
            PdfUtils.textLight("Test"),
            PdfUtils.center(
              PdfUtils.textRegular(printInfo.title!.toUpperCase()),
            ),
            PdfUtils.center(PdfUtils.textRegular(
                'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
            _columnGap,
            header,
          ]);
          if (tables.length == 0) {
            return children;
          }
          int lastCount = limitFirstPage - tables[0].children.length;
          children.addAll([tables[0]]);
          for (int i = 1; i < tables.length; i++) {
            children.addAll([pw.NewPage(), header, tables[i]]);
            lastCount = limitOtherPage - tables[i].children.length;
          }
          const LAST_PAGE_COLUMN_NUM = 3;
          if (lastCount < LAST_PAGE_COLUMN_NUM) {
            children.add(pw.NewPage());
          }
          List<Map<String?, String?>?> maps = partitionMap(
              aggregationStatInt.map((fieldName, value) => MapEntry(
                  printInfo.inputInfoMap.map![fieldName]!.fieldDes,
                  toText(buildContext, value))),
              LAST_PAGE_COLUMN_NUM);
          List<pw.Widget> mapWidgets =
              maps.map((map) => PdfUtils.tableOfTwo(map!, width: 100)).toList();
          children.add(pw.Container(
              decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide()))));
          children.add(pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              mainAxisSize: pw.MainAxisSize.max,
              children: mapWidgets));
          return children;
        }));
    return pdf.save();
  }

  @override
  Future createPdfSummary(BuildContext context, DateTime timeOfPrint,
      PrintInfo printInfo, List<CloudObject> data) async {
    List<int> bytes = await _generatingPdfSummary(
        context, timeOfPrint, printInfo, data.map((e) => e.dataMap).toList());
    if (kIsWeb) {
      if (html_utils.HtmlUtils().isSafari()!) {
        (html_utils.HtmlUtils()).downloadWeb(bytes, 'report.pdf');
      } else {
        (html_utils.HtmlUtils()).viewBytes(bytes);
      }
      return null;
    } else {
      return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
        return bytes as FutureOr<Uint8List>;
      });
    }
  }

  @override
  Future createPdfTicket(BuildContext buildContext, DateTime timeOfPrint,
      PrintTicket? printTicket, Map? dataMap) {
    return Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final Document pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(15),
          orientation: printTicket!.printVertical
              ? pw.PageOrientation.natural
              : pw.PageOrientation.landscape,
          build: (pw.Context context) {
            List<pw.Widget> children = [];
            children.addAll([
              PdfUtils.textRegular("Test"),
              PdfUtils.textLight("Test"),
              PdfUtils.center(
                PdfUtils.textRegular(printTicket.title!.toUpperCase()),
              ),
              PdfUtils.center(PdfUtils.textRegular(
                  'Ngày in: ${formatDatetime(buildContext, timeOfPrint)}')),
              _columnGap,
            ]);
            printTicket.ticketParagraphs.forEach((paragraph) {
              if (paragraph.fieldNames != null) {
                List lists = partitionListToBin(
                    paragraph.fieldNames!, paragraph.numColumn);
                children.add(pw.Row(
                    mainAxisSize: pw.MainAxisSize.max,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: lists.map((list) {
                      return tableOfTwo(buildContext, list,
                          printTicket.inputInfoMap.map, dataMap);
                    }).toList()));
              } else if (paragraph.hardCodeTexts != null) {
                List<List> lists = partitionListToBin(
                    paragraph.hardCodeTexts!, paragraph.numColumn);
                children.add(pw.Row(
                    mainAxisSize: pw.MainAxisSize.max,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: lists.map((list) {
                      return pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: list
                              .map((text) => PdfUtils.textLight(text))
                              .toList());
                    }).toList()));
              } else {
                children.add(pw.SizedBox(
                    height: paragraph.numLineBreak! * DOT_PER_CM * 1.0));
              }
            });
            return children;
          }));
      return pdf.save();
    });
  }

  pw.Widget tableOfTwo(BuildContext buildContext, List<String> fieldNames,
      Map<String, InputInfo>? inputInfoMap, Map? dataMap) {
    return PdfUtils.tableOfTwo(
        fieldNames.asMap().map((key, fieldName) {
          return MapEntry(inputInfoMap![fieldName]!.fieldDes,
              toText(buildContext, dataMap![fieldName] ?? ''));
        }),
        width: null);
  }
}
