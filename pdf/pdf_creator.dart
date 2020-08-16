import '../data/cloud_table.dart';
import 'create_pdf_sumary.dart';
import 'pdf_utils.dart';
import 'package:flutter/material.dart';

class PdfCreator {
  Future init() {
    return PdfUtils.init();
  }

  Future createPdfSummary(BuildContext context, String title,
      DateTime timeOfPrint, SchemaAndData schemaAndData) {
    return PdfSummary.createPdfSummary(context, title, timeOfPrint, schemaAndData);
  }
}
