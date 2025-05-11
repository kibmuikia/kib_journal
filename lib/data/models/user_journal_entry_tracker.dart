import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart' show JsonSerializable;

part 'user_journal_entry_tracker.g.dart';

@JsonSerializable()
class UserJournalEntryTracker extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final DateTime lastPostedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserJournalEntryTracker({
    this.id = '',
    this.userId = '',
    this.userEmail = '',
    required this.lastPostedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(userId.isNotEmpty, 'User ID cannot be empty');

  @override
  List<Object?> get props => [id, userId, userEmail, lastPostedAt, createdAt, updatedAt];

  factory UserJournalEntryTracker.fromJson(Map<String, dynamic> json) =>
      _$UserJournalEntryTrackerFromJson(json);

  Map<String, dynamic> toJson() => _$UserJournalEntryTrackerToJson(this);

  factory UserJournalEntryTracker.fromFirestore(DocumentSnapshot docSnapshot) {
    final data = docSnapshot.data() as Map<String, dynamic>;

    final rawLastPostedAt = data['lastPostedAt'];
    final lastPostedAt =
        rawLastPostedAt is Timestamp
            ? rawLastPostedAt.toDate()
            : rawLastPostedAt is String
            ? DateTime.tryParse(rawLastPostedAt)
            : null;
    if (lastPostedAt == null) {
      throw StateError('lastPostedAt cannot be null');
    }

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

    return UserJournalEntryTracker(
      id: docSnapshot.id,
      userId: data['userId'],
      userEmail: data['userEmail'],
      lastPostedAt: lastPostedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'lastPostedAt': Timestamp.fromDate(lastPostedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserJournalEntryTracker copyWith({
    String? id,
    String? userId,
    DateTime? lastPostedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserJournalEntryTracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastPostedAt: lastPostedAt ?? this.lastPostedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  //
}
