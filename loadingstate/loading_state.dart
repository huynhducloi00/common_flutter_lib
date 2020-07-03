import 'package:canxe/common/loadingstate/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class LoadingState<T extends StatefulWidget, L> extends State<T>
    with AutomaticKeepAliveClientMixin<T> {
  bool isLoading = false;
  String tag;
  bool isRequireData = false;
  Loading loadingScreen = Loading();
  bool keepAlive;
  L data;
  LoadingState({this.isRequireData = false, this.tag="", this.keepAlive = false}):super();

  void markLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void markDoneLoading() {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (keepAlive) {
      super.build(context);
    }
    if (isRequireData) {
      data = Provider.of<L>(context);
      if (data == null) {
        return loadingScreen;
      }
    }
    if (isLoading) {
      return loadingScreen;
    } else {
      return delegateBuild(context);
    }
  }

  Widget delegateBuild(BuildContext context);
  @override
  bool get wantKeepAlive => keepAlive;
}
