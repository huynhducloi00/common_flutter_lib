import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class CurrentQueryNotifier extends ChangeNotifier {
  late CollectionReference colRef;
  late Query _originalQuery;
  late Query _currentPagingQuery;
  late ParentParam _parentParam;
  final int tableTableRowLimit;
  Query _calculateNewQuery(ParentParam parentParam) {
    // Apply both parent and child params.
    var queryTmp = applyFilterToQuery(colRef, parentParam);
    var query = queryTmp as Query;
    query = query.orderBy(parentParam.sortKey!,
        descending: parentParam.sortKeyDescending!);
    query = query.limit(tableTableRowLimit);
    return query;
  }

  CurrentQueryNotifier(this.colRef, parentParam, this.tableTableRowLimit) {
    _parentParam = parentParam;
    _originalQuery = _calculateNewQuery(parentParam);
    _currentPagingQuery = _originalQuery;
  }
  ParentParam get parentParam => _parentParam;
  Query get currentPagingQuery => _currentPagingQuery;
  Query get originalQuery => _originalQuery;

  set parentParam(ParentParam value) {
    _parentParam = value;
    _originalQuery = _calculateNewQuery(_parentParam);
    _currentPagingQuery = _originalQuery;
    notifyListeners();
  }

  set currentPagingQuery(Query value) {
    _currentPagingQuery = value;
    notifyListeners();
  }
}
