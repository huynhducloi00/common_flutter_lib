import 'loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget createStreamBuilder<L, W extends StatefulWidget>(
    {Stream<L> stream, W child}) {
  return StreamBuilder(
    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
      if (snapshot.hasData) {
        // still loading
        return MultiProvider(providers: [
          Provider<L>.value(value: snapshot.data),
          Provider<ConnectionState>.value(
            value: snapshot.connectionState,
          )
        ], child: child);
      } else {
        return Loading();
      }
    },
    stream: stream,
  );
}

class StreamStatefulChildState<T extends StatefulWidget, L> extends State<T> {
  bool isLoading;
  L data;

  @override
  Widget build(BuildContext context) {
    var connectionState = Provider.of<ConnectionState>(context);
    isLoading = connectionState == ConnectionState.waiting;
    data = Provider.of<L>(context);
    return delegateBuild(context);
  }

  Widget delegateBuild(BuildContext context) {
    throw UnimplementedError();
  }
}
