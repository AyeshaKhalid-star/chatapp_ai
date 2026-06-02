import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:chatapp_ai/Model/Chat_Model.dart';
import 'package:chatapp_ai/Services/api_services.dart';

class ChatViewModel extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final ImagePicker picker = ImagePicker();
  stt.SpeechToText speech = stt.SpeechToText();

  List<MessageModel> messages = [];

  File? selectedImage;
  File? selectedDocument;
  String? selectedDocumentName;

  int? editingIndex;

  bool isTyping = false;
  bool isListening = false;
  bool speechAvailable = false;

  ChatViewModel() {
    initSpeech();

    messages.add(
      MessageModel(
        isUser: false,
        history: ["Hello! How can I help you today?"],
      ),
    );
  }

  // =========================
  // SPEECH INIT
  // =========================
  Future<void> initSpeech() async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      speechAvailable = false;
      notifyListeners();
      return;
    }

    speechAvailable = await speech.initialize();
    notifyListeners();
  }

  // =========================
  // CLEAR ATTACHMENTS
  // =========================
  void clearAttachment() {
    selectedImage = null;
    selectedDocument = null;
    selectedDocumentName = null;
    notifyListeners();
  }

  // =========================
  // MESSAGE VERSION NAVIGATION
  // =========================
  void nextVersion(int index) {
    final msg = messages[index];

    if (msg.currentIndex < msg.history.length - 1) {
      msg.currentIndex++;
      notifyListeners();
    }
  }

  void prevVersion(int index) {
    final msg = messages[index];

    if (msg.currentIndex > 0) {
      msg.currentIndex--;
      notifyListeners();
    }
  }

  // =========================
  // SEND MESSAGE
  // =========================
  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty && selectedImage == null && selectedDocument == null) {
      return;
    }

    // ================= EDIT MODE =================
    if (editingIndex != null) {
      final index = editingIndex!;
      final msg = messages[index];

      msg.history.add(text);
      msg.currentIndex = msg.history.length - 1;

      editingIndex = null;
      controller.clear();

      isTyping = true;
      notifyListeners();

      String aiInput = text;
      if (selectedDocumentName != null) {
        aiInput += "\n[File: $selectedDocumentName]";
      }

      final aiReply = await ApiService.sendMessage(aiInput);

      if (index + 1 < messages.length && !messages[index + 1].isUser) {
        messages.removeAt(index + 1);
      }

      messages.insert(
        index + 1,
        MessageModel(isUser: false, history: [aiReply]),
      );

      isTyping = false;
      notifyListeners();
      return;
    }

    // ================= NORMAL MESSAGE =================
    final userMsg = text;

    messages.add(
      MessageModel(
        isUser: true,
        history: [userMsg],
        image: selectedImage,
        document: selectedDocument,
        documentName: selectedDocumentName,
      ),
    );

    controller.clear();

    final docName = selectedDocumentName;
    final img = selectedImage;
    final doc = selectedDocument;

    clearAttachment();

    isTyping = true;
    notifyListeners();

    String aiInput = userMsg;

    if (docName != null) {
      aiInput += "\n[File: $docName]";
    }

    try {
      final aiReply = await ApiService.sendMessage(aiInput);

      messages.add(MessageModel(isUser: false, history: [aiReply]));
    } catch (e) {
      messages.add(MessageModel(isUser: false, history: ["Error: $e"]));
    }

    isTyping = false;
    notifyListeners();
  }

  // ================= IMAGE PICK =================
  Future<void> pickImage(ImageSource source) async {
    final image = await picker.pickImage(source: source);

    if (image == null) return;

    selectedImage = File(image.path);
    notifyListeners();
  }

  // ================= DOCUMENT PICK =================
  Future<void> pickDocument() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.single.path == null) return;

    selectedDocument = File(result.files.single.path!);
    selectedDocumentName = result.files.single.name;

    notifyListeners();
  }

  // ================= EDIT MESSAGE =================
  void editMessage(int index) {
    editingIndex = index;
    controller.text = messages[index].message;
    notifyListeners();
  }

  void deleteMessage(int index) {
    messages.removeAt(index);
    notifyListeners();
  }

  void clearChat() {
    messages.clear();
    messages.add(
      MessageModel(
        isUser: false,
        history: ["Hello! How can I help you today?"],
      ),
    );
    notifyListeners();
  }

  // ================= VOICE =================
  Future<void> startListening() async {
    if (!speechAvailable) return;

    isListening = true;
    notifyListeners();

    await speech.listen(
      onResult: (result) {
        controller.text = result.recognizedWords;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    if (!isListening) return;

    await speech.stop();
    isListening = false;
    notifyListeners();

    if (controller.text.trim().isNotEmpty) {
      sendMessage();
    }
  }

  void removeImage() {
    selectedImage = null;
    notifyListeners();
  }

  void removeDocument() {
    selectedDocument = null;
    selectedDocumentName = null;
    notifyListeners();
  }
}
