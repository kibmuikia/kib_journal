import 'package:flutter/material.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/core/utils/general_utils.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';
import 'package:kib_journal/providers/firestore_journal_service_provider.dart';
import 'package:kib_utils/kib_utils.dart';
import 'package:provider/provider.dart';

class AddJournalEntryForm extends StatefulWidgetK {
  final Function(JournalEntry createdJournal) onEntryAdded;

  AddJournalEntryForm({
    super.key,
    required this.onEntryAdded,
    super.tag = 'AddJournalEntryForm',
  });

  @override
  StateK<AddJournalEntryForm> createState() => _AddJournalEntryFormState();
}

class _AddJournalEntryFormState extends StateK<AddJournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  String? message;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext ctx) async {
    if (_formKey.currentState?.validate() != true) {
      setState(() {
        message = 'Ensure form data is valid';
      });
      return;
    }

    context.hideKeyboard();
    setState(() {
      _isSubmitting = true;
      message = null;
    });

    final provider = Provider.of<FirestoreJournalServiceProvider>(
      context,
      listen: false,
    );

    final result = await provider.createJournalEntry(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    switch (result) {
      case Success(value: final journalEntry):
        setState(() {
          _isSubmitting = false;
        });
        widget.onEntryAdded(journalEntry);
        break;
      case Failure(error: final Exception e):
        setState(() {
          _isSubmitting = false;
          message = e is ExceptionX ? e.message : e.toString();
        });
        break;
    }
  }

  @override
  Widget buildWithTheme(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create New Journal Entry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  if (value.trim().length > 500) {
                    return 'Content must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitForm(context),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Save Entry'),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  //
}
