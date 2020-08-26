enum DataType {
  string,
  html,
  int,
  timestamp,
  boolean,
}

class CloudObject<T> {
  String documentId;
  Map<String, dynamic> dataMap;

  CloudObject(this.documentId, this.dataMap);
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
