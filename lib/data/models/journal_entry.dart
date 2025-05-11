import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart' show JsonSerializable;

part 'journal_entry.g.dart';

@JsonSerializable()
class JournalEntry extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    this.id = '',
    this.userId = '',
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       assert(content.isNotEmpty, 'Content cannot be empty'),
       assert(content.length > 500, 'Content must be less than 500 characters'),
       assert(title.isNotEmpty, 'Title cannot be empty'),
       assert(userId.isNotEmpty, 'User ID cannot be empty'),
       assert(id.isNotEmpty, 'ID cannot be empty');

  @override
  List<Object?> get props => [id, userId, title, content, createdAt, updatedAt];

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);

  Map<String, dynamic> toJson() => _$JournalEntryToJson(this);

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreated = data['createdAt'];
    final createdAt =
        rawCreated is Timestamp
            ? rawCreated.toDate()
            : rawCreated is String
            ? DateTime.tryParse(rawCreated)
            : null;
    final rawUpdated = data['updatedAt'];
    final updatedAt =
        rawUpdated is Timestamp
            ? rawUpdated.toDate()
            : rawUpdated is String
            ? DateTime.tryParse(rawUpdated)
            : null;

    return JournalEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
