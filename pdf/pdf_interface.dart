import '../data/cloud_obj.dart';

import '../data/cloud_table.dart';
import 'package:flutter/material.dart';

abstract class PdfCreatorInterface{
  Future? init(){
    return null;
  }

  Future? createPdfSummary(BuildContext context,
      DateTime timeOfPrint, PrintInfo printInfo, List<CloudObject> data){
        return null;
      }
  Future? createPdfTicket(BuildContext context, DateTime timeOfPrint,
      PrintTicket printTicket, Map dataMap){
        return null;
      }
}