import 'package:flutter/material.dart';
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:kib_journal/config/routes/navigation_helpers.dart';
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager;
import 'package:kib_journal/core/utils/export.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/di/setup.dart' show getIt;
import 'package:kib_journal/firebase_services/firebase_auth_service.dart'
    show FirebaseAuthService;
import 'package:kib_journal/presentation/reusable_widgets/add_journal_entry.dart';
import 'package:kib_journal/presentation/reusable_widgets/journal_entry_card.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';
import 'package:kib_journal/providers/firestore_journal_service_provider.dart'
    show FirestoreJournalServiceProvider;
import 'package:kib_journal/services/email_journals_service.dart';
import 'package:kib_utils/kib_utils.dart';
import 'package:provider/provider.dart' show Consumer, Provider;

class HomeScreen extends StatefulWidgetK {
  HomeScreen({super.key, super.tag = "HomeScreen"});

  @override
  StateK<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends StateK<HomeScreen> {
  final _appPrefs = getIt<AppPrefsAsyncManager>();
  final _authService = getIt<FirebaseAuthService>();
  late final EmailJournalsService _emailService;
  late final FirestoreJournalServiceProvider _journalProvider;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _appPrefs.getCurrentUserUid().then(
      (value) =>
          kprint.lg('_HomeScreenState:initState: current-user-id: $value'),
    );
    postFrame(() async {
      _initJournalProvider();
      _getCurrentUserEmail();
      _emailService = await getIt.getAsync<EmailJournalsService>();
    });
  }

  void _initJournalProvider() async {
    _journalProvider = Provider.of<FirestoreJournalServiceProvider>(
      context,
      listen: false,
    );
    await _journalProvider.init();

    // TODO: remove after testing is done or retain-and-fix-flow if needed
    // _journalProvider.getAllJournalEntries();
    _journalProvider.getJournalEntriesFromLast24Hours();
    _journalProvider.getAllUserJournalEntryTrackers();
  }

  void _getCurrentUserEmail() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email ?? '-';
      });
    }
    _authService.authStateChanges.listen(
      (user) {
        kprint.lg(
          '_getCurrentUserEmail: email[ ${user == null ? '-' : user.email} ]',
        );
        if (user != null) {
          setState(() {
            _currentUserEmail = user.email ?? '-';
          });
        }
      },
      onError: (err) {
        kprint.err('_getCurrentUserEmail: ${err.toString()}');
      },
      onDone: () {
        kprint.lg('_getCurrentUserEmail: onDone');
      },
    );
  }

  Future<void> _refreshJournalEntries({bool refresh = true}) async {
    await _journalProvider.loadCurrentUserJournalEntries(refresh: refresh);
  }

  void logout(BuildContext context) async {
    final signOutResult = await _authService.signOut();
    switch (signOutResult) {
      case Success():
        final isUnset = await _appPrefs.setCurrentUserUid('');
        if (isUnset) {
          (() => navigateToSignIn(context))();
        } else {
          kprint.err('home_screen:logout: Failed to unset current user uid');
          informUser('Error signing out: Failed to unset user data');
        }
        break;
      case Failure(error: final Exception e):
        kprint.err('home_screen:logout:Error: $e');
        informUser('Error signing out: $e');
        break;
    }
  }

  void _showAddJournalEntryBottomSheet(BuildContext ctx) async {
    /* // TODO: For debug only: To test sending of emails
    final result = await _emailService.distributeJournalEntries();
    switch (result) {
      case Success():
        informUser('Journal entries distributed');
        break;
      case Failure(error: final Exception e):
        informUser('Error distributing journal entries: $e');
        break;
    } */
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AddJournalEntryForm(
            onEntryAdded: (createdEntry) async {
              Navigator.pop(context);
              informUser('Journal, ${createdEntry.title}, entry added');
              await _refreshJournalEntries(refresh: false);
            },
          ),
    );
  }

  void _handleOnDelete(JournalEntry journal) async {
    await _journalProvider.handleDeleteJournalEntry(journal);
    await _refreshJournalEntries(refresh: false);
  }

  @override
  Widget buildWithTheme(BuildContext context) {
    return Consumer<FirestoreJournalServiceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => _refreshJournalEntries(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Home Screen'),
                  if (_currentUserEmail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _currentUserEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => logout(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddJournalEntryBottomSheet(context),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshJournalEntries,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (provider.status.isLoading &&
                        provider.journalEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (!provider.status.isLoading &&
                        provider.journalEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'No journal entries yet.\nUse the + button to add one.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    if (provider.status.isError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (provider.journalEntries.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.journalEntries.length,
                        itemBuilder: (context, index) {
                          final journalEntry = provider.journalEntries[index];
                          return JournalEntryCard(
                            entry: journalEntry,
                            tag: 'journal-${journalEntry.id}-$index',
                            onDelete: (journal) => _handleOnDelete(journal),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      // child: ,
    );
  }
}
