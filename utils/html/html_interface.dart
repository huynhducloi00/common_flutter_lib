abstract class HtmlUtilsInterface {
  void viewBytes(List<int> bytes){}
  Future downloadWeb(List<int> byteList, String downloadName){}
}