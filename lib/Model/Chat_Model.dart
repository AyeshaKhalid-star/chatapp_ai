// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

class MessageModel {
  final bool isUser;

  /// 👇 ALL MESSAGE VERSIONS (edit history + AI regenerations)
  final List<String> history;

  /// 👇 CURRENT DISPLAY INDEX
  int currentIndex;

  final File? image;
  final File? document;
  final String? documentName;

  MessageModel({
    required this.isUser,
    required this.history,
    this.currentIndex = 0,
    this.image,
    this.document,
    this.documentName,
  });

  /// 👇 CURRENT MESSAGE TEXT
  String get message => history[currentIndex];

  MessageModel copyWith({
    bool? isUser,
    List<String>? history,
    int? currentIndex,
    File? image,
    File? document,
    String? documentName,
  }) {
    return MessageModel(
      isUser: isUser ?? this.isUser,
      history: history ?? this.history,
      currentIndex: currentIndex ?? this.currentIndex,
      image: image ?? this.image,
      document: document ?? this.document,
      documentName: documentName ?? this.documentName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isUser': isUser,
      'history': history,
      'currentIndex': currentIndex,
      'image': image?.path,
      'document': document?.path,
      'documentName': documentName,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      isUser: map['isUser'] as bool,
      history: List<String>.from(map['history'] ?? [map['message'] ?? ""]),
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
    return 'MessageModel(isUser: $isUser, message: $message, history: $history, currentIndex: $currentIndex)';
  }
}
