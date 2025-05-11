import 'package:flutter/material.dart';
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:kib_journal/config/routes/navigation_helpers.dart';
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager;
import 'package:kib_journal/core/utils/export.dart';
import 'package:kib_journal/data/models/journal_entry.dart' show JournalEntry;
import 'package:kib_journal/di/setup.dart' show getIt;
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart'
    show FirestoreJournalEntriesService;
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';
import 'package:kib_journal/providers/firestore_journal_service_provider.dart'
    show FirestoreJournalServiceProvider;
import 'package:provider/provider.dart' show Consumer, Provider;

class HomeScreen extends StatefulWidgetK {
  HomeScreen({super.key, super.tag = "HomeScreen"});

  @override
  StateK<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends StateK<HomeScreen> {
  final _appPrefs = getIt<AppPrefsAsyncManager>();
  final _journalEntriesService = getIt<FirestoreJournalEntriesService>();
  late final FirestoreJournalServiceProvider _journalProvider;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _appPrefs.getCurrentUserUid().then(
      (value) =>
          kprint.lg('_HomeScreenState:initState: current-user-id: $value'),
    );
    postFrame(() async => _initJournalProvider());
  }

  void _initJournalProvider() async {
    _journalProvider = Provider.of<FirestoreJournalServiceProvider>(
      context,
      listen: false,
    );
    await _journalProvider.init();
  }

  Future<void> _refreshJournalEntries() async {
    await _journalProvider.loadJournalEntries(refresh: true);
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
    return Consumer<FirestoreJournalServiceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => _refreshJournalEntries(),
              child: const Text('Home Screen'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => logout(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
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
                    if (provider.journalEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: const Text(
                          'No journal entries yet.\nUse the + button to add one.',
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final journalEntry = provider.journalEntries[index];
                          return JournalEntryCard(
                            entry: journalEntry,
                            tag: 'journal-${journalEntry.id}-$index',
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: provider.journalEntries.length,
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

class JournalEntryCard extends StatelessWidgetK {
  final JournalEntry entry;

  JournalEntryCard({super.key, required super.tag, required this.entry});

  @override
  Widget buildWithTheme(BuildContext context) {
    // final dateFormatter = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // dateFormatter.format(entry.createdAt),
              '${entry.createdAt.hour}:${entry.createdAt.minute}  ${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              entry.content,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
