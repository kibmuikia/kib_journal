import 'package:flutter/material.dart';
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:kib_journal/config/routes/navigation_helpers.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager;
import 'package:kib_journal/core/utils/export.dart';
import 'package:kib_journal/di/setup.dart' show getIt;
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart'
    show FirestoreJournalEntriesService;
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';
import 'package:kib_utils/kib_utils.dart';

class HomeScreen extends StatefulWidgetK {
  HomeScreen({super.key, super.tag = "HomeScreen"});

  @override
  StateK<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends StateK<HomeScreen> {
  final _appPrefs = getIt<AppPrefsAsyncManager>();
  final _journalEntriesService = getIt<FirestoreJournalEntriesService>();

  @override
  void initState() {
    super.initState();
    _appPrefs.getCurrentUserUid().then(
      (value) =>
          kprint.lg('_HomeScreenState:initState: current-user-id: $value'),
    );
    getJournalEntries();
  }

  void getJournalEntries() async {
    final result = await _journalEntriesService.getJournalEntries();
    switch (result) {
      case Success(value: final entries):
        kprint.lg('_HomeScreenState:getJournalEntries: $entries');
        informUser('Got ${entries.length} journal entries');
        break;
      case Failure(error: final Exception e):
        if (e is UnauthorizedException) {
          informUser('You are Unauthorized');
        } else if (e is ExceptionX) {
          informUser(e.message);
        } else {
          informUser(e.toString());
        }
        break;
    }
  }

  void informUser(String message) => context.showMessage(message);

  void logout(BuildContext context) async {
    final isUnset = await _appPrefs.setCurrentUserUid('');
    if (isUnset) {
      (() => navigateToSignIn(context))();
    } else {
      kprint.err('Failed to unset current user uid');
      (() => context.showMessage('Unable to logout'))();
    }
  }

  @override
  Widget buildWithTheme(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: SafeArea(child: Column(children: [])),
    );
  }
}
