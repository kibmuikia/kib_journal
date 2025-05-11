import 'package:flutter/material.dart';
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart' show AppPrefsAsyncManager;
import 'package:kib_journal/di/setup.dart' show getIt;
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';

class HomeScreen extends StatefulWidgetK {
  HomeScreen({super.key, super.tag = "HomeScreen"});

  @override
  StateK<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends StateK<HomeScreen> {
  final _appPrefs = getIt<AppPrefsAsyncManager>();

  @override
  void initState() {
    super.initState();
    _appPrefs.getCurrentUserUid().then((value) => kprint.lg('_HomeScreenState:initState: current-user-id: $value'));
  }
  
  @override
  Widget buildWithTheme(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Screen")),
      body: SafeArea(child: Column(children: [])),
    );
  }
}
