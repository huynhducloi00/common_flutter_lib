enum Datatype{
  string,
  html,
  int,
  timestamp,
}
class InputInfo<T> {
  String field;
  T value;
  Function validator;
  String hint;
  bool canUpdate;
  Datatype datatype;
  InputInfo({this.value, this.validator, this.hint, this.canUpdate = true, this.datatype});
  static InputInfo<T> cloneWithValue<T>(InputInfo<T> from, dynamic value){
    return InputInfo( value: value, validator: from.validator, hint: from.hint, canUpdate: from.canUpdate,
        datatype: from.datatype);
  }
}
abstract class CloudObject<T> {

  Map<String, dynamic> get toMap;

  static String validator(bool condition, String errorMessage){
    return condition ? null: errorMessage;
  }
  static Map<String, InputInfo> autoFormMap(Map<String, InputInfo> itemRules, CloudObject cloudObject){
    Map<String, InputInfo> newMap=new Map();
    itemRules.forEach((key, value) {
      InputInfo newInputInfo= InputInfo.cloneWithValue(value, cloudObject.toMap[key]);
      newMap[key]= newInputInfo;
    });
    return newMap;
  }
  static Map<String, InputInfo> newItemAutoFormMap(Map<String, InputInfo> itemRules) {
    Map<String, InputInfo> newMap=new Map();
    itemRules.forEach((key, value) {
      InputInfo newInputInfo= InputInfo.cloneWithValue(value, null);
      newMap[key]= newInputInfo;
    });
    return newMap;
  }
}