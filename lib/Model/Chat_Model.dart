// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

class MessageModel {
  static const Uuid _uuid = Uuid();

  /// Unique Message ID
  final String chatId;

  /// Sender type
  final bool isUser;

  /// Timestamp
  final DateTime createdAt;

  /// User message versions
  List<String> history;

  /// AI response versions (IMPORTANT ADDITION)
  List<String> aiHistory;

  /// Current selected version index
  int currentIndex;

  final File? image;
  final File? document;
  final String? documentName;

  MessageModel({
    String? chatId,
    DateTime? createdAt,
    required this.isUser,
    required this.history,
    this.aiHistory = const [],
    this.currentIndex = 0,
    this.image,
    this.document,
    this.documentName,
  }) : chatId = chatId ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  // =========================
  // CURRENT VALUES
  // =========================

  String get message => history.isNotEmpty ? history[currentIndex] : "";

  String get aiMessage => aiHistory.isNotEmpty
      ? aiHistory[currentIndex.clamp(0, aiHistory.length - 1)]
      : "";

  // =========================
  // VERSION HELPERS
  // =========================

  bool get canGoNext => currentIndex < history.length - 1;

  bool get canGoPrev => currentIndex > 0;

  void nextVersion() {
    if (canGoNext) currentIndex++;
  }

  void prevVersion() {
    if (canGoPrev) currentIndex--;
  }

  // =========================
  // COPY WITH
  // =========================

  MessageModel copyWith({
    String? chatId,
    bool? isUser,
    DateTime? createdAt,
    List<String>? history,
    List<String>? aiHistory,
    int? currentIndex,
    File? image,
    File? document,
    String? documentName,
  }) {
    return MessageModel(
      chatId: chatId ?? this.chatId,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
      aiHistory: aiHistory ?? this.aiHistory,
      currentIndex: currentIndex ?? this.currentIndex,
      image: image ?? this.image,
      document: document ?? this.document,
      documentName: documentName ?? this.documentName,
    );
  }

  // =========================
  // SERIALIZATION
  // =========================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatId': chatId,
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
      'history': history,
      'aiHistory': aiHistory,
      'currentIndex': currentIndex,
      'image': image?.path,
      'document': document?.path,
      'documentName': documentName,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      chatId: map['chatId'],
      isUser: map['isUser'] as bool,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      history: List<String>.from(map['history'] ?? []),

      // 🔥 IMPORTANT FIX: AI history restore
      aiHistory: List<String>.from(map['aiHistory'] ?? []),

      currentIndex: map['currentIndex'] ?? 0,
      image: map['image'] != null ? File(map['image']) : null,
      document: map['document'] != null ? File(map['document']) : null,
      documentName: map['documentName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageModel.fromJson(String source) =>
      MessageModel.fromMap(json.decode(source));

  @override
  String toString() {
    return '''
MessageModel(
  chatId: $chatId,
  isUser: $isUser,
  createdAt: $createdAt,
  message: $message,
  aiMessage: $aiMessage,
  history: $history,
  aiHistory: $aiHistory,
  currentIndex: $currentIndex
)
''';
  }
}
