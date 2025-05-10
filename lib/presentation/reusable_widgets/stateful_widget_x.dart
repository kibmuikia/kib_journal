import 'package:flutter/material.dart' show State, StatefulWidget, VoidCallback;

abstract class StatefulWidgetK extends StatefulWidget {
  final String tag;

  const StatefulWidgetK({super.key, required this.tag});

  @override
  StateK<StatefulWidgetK> createState();
}

abstract class StateK<T extends StatefulWidgetK> extends State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
