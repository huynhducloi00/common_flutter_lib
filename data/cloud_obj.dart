enum DataType { string, html, int, timestamp, boolean, double, firebaseImage }

class CloudObject {
  String? documentId;
  Map<String, dynamic> dataMap;

  CloudObject(this.documentId, this.dataMap) {
    dataMap['documentId'] = documentId;
  }

  Map<String, dynamic> get getDataMapWithDocId {
    return dataMap;
  }

  Map<String, dynamic> get getDataMapWithoutDocId {
    return dataMap..remove('documentId');
  }

// Copy the following static
//  static ItemLookup _convertToItemLookUp(docId, dynamic data) {
//    return ItemLookup(docId, data);
//  }
//
//  static List<ItemLookup> convertQuerySnapshotToList(List<DocumentSnapshot> event) {
//    return event.asMap().entries.map((e) {
//      return ItemLookup._convertToItemLookUp(e.value.documentID, e.value.data);
//    }).toList();
//  }
//
//  static Map<String, InputInfo> inputInfoMap() => {
//  'itemId': InputInfo(DataType.string,
//  fieldDes: 'Mã sản phẩm', validator: InputInfo.nonNullValidator),
//  'itemDes': InputInfo(DataType.string,
//  fieldDes: 'Tên sản phẩm', validator: InputInfo.nonNullValidator),
//};
}
