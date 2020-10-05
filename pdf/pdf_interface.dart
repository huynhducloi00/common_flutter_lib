
import '../data/cloud_table.dart';
import 'package:flutter/material.dart';

abstract class PdfCreatorInterface{
  Future init(){}

  Future createPdfSummary(BuildContext context,
      DateTime timeOfPrint, PrintInfo printInfo, List data, bool isPhone){}
  Future createPdfTicket(BuildContext context, DateTime timeOfPrint,
      PrintTicket printTicket, Map dataMap){}
}