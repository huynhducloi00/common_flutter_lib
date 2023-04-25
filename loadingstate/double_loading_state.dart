import 'loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class DoubleLoadingState<T extends StatefulWidget, L1,L2> extends State<T>
    with AutomaticKeepAliveClientMixin<T> {
  bool isLoading = false;
  String tag;
  bool isRequireData = false;
  Loading loadingScreen = Loading();
  bool keepAlive;
  L1? data1;
  L2? data2;
  DoubleLoadingState({this.isRequireData = false, this.tag="", this.keepAlive = false}):super();

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
      data1 = Provider.of<L1>(context);
      data2=Provider.of<L2>(context);
      if (data1 == null || data2==null) {
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
