// This is mainly for paging
class ChildParam {
  // When both of this is null, it means we are at the first page.
  // Both can not take value at one time.
  dynamic startAfter;
  dynamic endBefore;

  ChildParam({this.startAfter, this.endBefore}) {
    assert(startAfter == null || endBefore == null);
  }

  @override
  String toString() {
    return '${startAfter} ${endBefore}';
  }
}
