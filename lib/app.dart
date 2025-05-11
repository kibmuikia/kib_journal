import 'package:flutter/material.dart';
import 'package:kib_journal/config/routes/router_config.dart';
import 'package:kib_journal/config/theme/app_theme.dart' show AppThemeConfig;
import 'package:kib_journal/core/constants/app_constants.dart' show appName;
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager;
import 'package:kib_journal/core/utils/general_utils.dart' show postFrame;
import 'package:kib_journal/di/setup.dart' show getIt;
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';
import 'package:kib_journal/providers/firestore_journal_service_provider.dart'
    show FirestoreJournalServiceProvider;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class KibJournal extends StatefulWidgetK {
  KibJournal({super.key, super.tag = 'KibJournal'});

  @override
  StateK<KibJournal> createState() => _KibJournalState();
}

class _KibJournalState extends StateK<KibJournal> {
  late final AppPrefsAsyncManager _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<AppPrefsAsyncManager>();
    _updatePrefFirstLaunch();
  }

  void _updatePrefFirstLaunch() async {
    postFrame(() async {
      await _prefs.setFirstLaunch(false);
    });
  }

  // This widget is the root of your application.
  @override
  Widget buildWithTheme(BuildContext context) {
    return _setupMaterialApp(context);
  }

  Widget _setupMaterialApp(BuildContext ctx) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return _setupProviders(context);
      },
    );
  }

  MultiProvider _setupProviders(BuildContext ctx) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FirestoreJournalServiceProvider(),
        ),
      ],
      child: _materialApp(ctx),
    );
  }

  MaterialApp _materialApp(BuildContext ctx) {
    return MaterialApp.router(
      title: appName,
      theme: AppThemeConfig.lightTheme,
      themeMode: ThemeMode.dark,
      darkTheme: AppThemeConfig.darkTheme,
      routerConfig: AppNavigation.appRouteConfig,
    );
  }
}
