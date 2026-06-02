// import 'dart:io';
// import 'package:chatapp_ai/Services/Api_services.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class Chat_page extends StatefulWidget {
//   const Chat_page({super.key});

//   @override
//   State<Chat_page> createState() => _Chat_appState();
// }

// class _Chat_appState extends State<Chat_page> {
//   final TextEditingController controller = TextEditingController();
//   final ScrollController scrollController = ScrollController();
//   final ImagePicker picker = ImagePicker();

//   File? selectedImage;
//   File? selectedDocument;
//   String? selectedDocumentName;
//   int? editingIndex;

//   // FIX 1: Use nullable instead of `late` to avoid LateInitializationError
//   stt.SpeechToText? speech;
//   bool isListening = false;
//   // FIX 2: Track whether speech was successfully initialized
//   bool speechAvailable = false;

//   List<Map<String, dynamic>> messages = [
//     {
//       "isUser": false,
//       "message": "Hello! How can I help you today?",
//       "image": null,
//       "document": null,
//       "documentName": null,
//     },
//   ];

//   bool isTyping = false;

//   @override
//   void initState() {
//     super.initState();
//     speech = stt.SpeechToText();
//     _initSpeech();
//   }

//   /// FIX 3: Initialize speech once at startup and cache the result.
//   Future<void> _initSpeech() async {
//     // Request microphone permission first
//     final status = await Permission.microphone.request();
//     if (!status.isGranted) {
//       debugPrint('Microphone permission denied');
//       return;
//     }

//     try {
//       bool available = await speech!.initialize(
//         onStatus: (status) {
//           debugPrint('Speech status: $status');
//           // FIX 4: Reset isListening when the recognizer stops on its own
//           if (status == 'done' || status == 'notListening') {
//             if (mounted) setState(() => isListening = false);
//           }
//         },
//         onError: (error) {
//           debugPrint('Speech error: $error');
//           // FIX 5: Always reset isListening on error
//           if (mounted) setState(() => isListening = false);
//         },
//       );

//       if (mounted) setState(() => speechAvailable = available);
//       debugPrint('Speech available: $available');
//     } catch (e) {
//       debugPrint('Speech init exception: $e');
//     }
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     scrollController.dispose();
//     speech?.stop();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // SEND MESSAGE
//   // ─────────────────────────────────────────────
//   void sendMessage() async {
//     if (controller.text.isEmpty &&
//         selectedImage == null &&
//         selectedDocument == null) {
//       return;
//     }

//     final String userMessage = controller.text;
//     final File? imageToSend = selectedImage;
//     final File? docToSend = selectedDocument;
//     final String? docNameToSend = selectedDocumentName;

//     // FIX 6: Clear inputs AND set isTyping together in one setState
//     setState(() {
//       if (editingIndex != null) {
//         messages[editingIndex!] = {
//           "isUser": true,
//           "message": userMessage,
//           "image": imageToSend,
//           "document": docToSend,
//           "documentName": docNameToSend,
//         };
//         editingIndex = null;
//       } else {
//         messages.add({
//           "isUser": true,
//           "message": userMessage,
//           "image": imageToSend,
//           "document": docToSend,
//           "documentName": docNameToSend,
//         });
//       }

//       // FIX 7: Clear inside setState so UI updates atomically
//       controller.clear();
//       selectedImage = null;
//       selectedDocument = null;
//       selectedDocumentName = null;
//       isTyping = true;
//     });

//     // Scroll after the new user bubble is painted
//     scrollToBottom();

//     try {
//       String aiReply = await ApiService.sendMessage(
//         userMessage,
//         image: imageToSend,
//         document: docToSend,
//       );

//       // FIX 8: Guard setState with mounted check
//       if (!mounted) return;
//       setState(() {
//         messages.add({
//           "isUser": false,
//           "message": aiReply,
//           "image": null,
//           "document": null,
//           "documentName": null,
//         });
//         isTyping = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       // FIX 9: isTyping was never reset to false on error in original code
//       setState(() {
//         messages.add({
//           "isUser": false,
//           "message": "Error: $e",
//           "image": null,
//           "document": null,
//           "documentName": null,
//         });
//         isTyping = false;
//       });
//     }

//     scrollToBottom();
//   }

//   void scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (scrollController.hasClients) {
//         scrollController.animateTo(
//           scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   // ─────────────────────────────────────────────
//   // SPEECH
//   // ─────────────────────────────────────────────
//   Future<void> startListening() async {
//     // FIX 10: Don't try to listen if speech wasn't initialized / not available
//     if (speech == null || !speechAvailable) {
//       _showSnackBar('Speech recognition is not available on this device');
//       return;
//     }

//     if (isListening) return; // already running

//     setState(() => isListening = true);

//     speech!.listen(
//       onResult: (result) {
//         if (mounted) {
//           setState(() => controller.text = result.recognizedWords);
//         }
//       },
//       listenFor: const Duration(seconds: 30),
//       pauseFor: const Duration(seconds: 5),
//       cancelOnError: true,
//       partialResults: true,
//     );
//   }

//   void stopListening() {
//     // FIX 11: Guard — onLongPressUp fires even when the long-press didn't start
//     if (!isListening) return;

//     speech?.stop();
//     setState(() => isListening = false);

//     // Only auto-send if there's something to send
//     if (controller.text.trim().isNotEmpty) {
//       sendMessage();
//     }
//   }

//   // ─────────────────────────────────────────────
//   // PICKERS
//   // ─────────────────────────────────────────────
//   Future<void> pickImage(ImageSource source) async {
//     try {
//       final XFile? image = await picker.pickImage(
//         source: source,
//         imageQuality: 80,
//       );
//       if (image == null) return;
//       if (mounted) setState(() => selectedImage = File(image.path));
//     } catch (e) {
//       debugPrint('Image picker error: $e');
//     }
//   }

//   Future<void> pickDocument() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles();
//       if (result != null && mounted) {
//         setState(() {
//           selectedDocument = File(result.files.single.path!);
//           selectedDocumentName = result.files.single.name;
//         });
//       }
//     } catch (e) {
//       debugPrint('Document picker error: $e');
//     }
//   }

//   // ─────────────────────────────────────────────
//   // HELPERS
//   // ─────────────────────────────────────────────
//   void _showSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   // ─────────────────────────────────────────────
//   // WIDGETS
//   // ─────────────────────────────────────────────
//   Widget buildMessageBubble(Map<String, dynamic> message, int index) {
//     bool isUser = message['isUser'] ?? false;
//     File? image = message['image'];
//     File? document = message['document'];
//     String? documentName = message['documentName'];

//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onLongPress: () {
//         showModalBottomSheet(
//           context: context,
//           backgroundColor: const Color(0xff2A2B32),
//           builder: (context) {
//             return SafeArea(
//               child: Wrap(
//                 children: [
//                   ListTile(
//                     leading: const Icon(Icons.copy, color: Colors.white),
//                     title: const Text(
//                       'Copy',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     onTap: () {
//                       Clipboard.setData(
//                         ClipboardData(text: message['message'] ?? ''),
//                       );
//                       Navigator.pop(context);
//                       _showSnackBar('Message copied');
//                     },
//                   ),
//                   if (isUser)
//                     ListTile(
//                       leading: const Icon(Icons.edit, color: Colors.white),
//                       title: const Text(
//                         'Edit',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       onTap: () {
//                         Navigator.pop(context);
//                         setState(() {
//                           controller.text = message['message'] ?? '';
//                           selectedImage = image;
//                           editingIndex = index;
//                         });
//                       },
//                     ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//       child: Align(
//         alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           padding: const EdgeInsets.all(12),
//           constraints: const BoxConstraints(maxWidth: 320),
//           decoration: BoxDecoration(
//             color: isUser ? const Color(0xff10A37F) : const Color(0xff2A2B32),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (image != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: Image.file(
//                       image,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               if (document != null)
//                 Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white10,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.insert_drive_file, color: Colors.white),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           documentName ?? 'Document',
//                           style: const TextStyle(color: Colors.white),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               if ((message['message'] ?? '').toString().isNotEmpty)
//                 Text(
//                   message['message'],
//                   style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget typingWidget() {
//     return const Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: EdgeInsets.symmetric(vertical: 10),
//         child: Row(
//           children: [
//             SizedBox(width: 10),
//             CircularProgressIndicator(strokeWidth: 2),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // BUILD
//   // ─────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xff343541),
//       drawer: Drawer(
//         backgroundColor: const Color(0xff202123),
//         child: Column(
//           children: [
//             const SizedBox(height: 60),
//             ListTile(
//               leading: const Icon(Icons.chat, color: Colors.white),
//               title: Text(
//                 'New Chat',
//                 style: GoogleFonts.poppins(color: Colors.white),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.history, color: Colors.white),
//               title: Text(
//                 'Chat History',
//                 style: GoogleFonts.poppins(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff202123),
//         elevation: 0,
//         title: Text(
//           'AI Assistant',
//           style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: messages.length,
//               itemBuilder: (context, index) =>
//                   buildMessageBubble(messages[index], index),
//             ),
//           ),
//           if (isTyping) typingWidget(),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             color: const Color(0xff202123),
//             child: Row(
//               children: [
//                 // ADD BUTTON
//                 PopupMenuButton(
//                   icon: const Icon(Icons.add, color: Colors.white),
//                   color: const Color(0xff2A2B32),
//                   onSelected: (value) {
//                     if (value == 'gallery') {
//                       pickImage(ImageSource.gallery);
//                     } else if (value == 'camera') {
//                       pickImage(ImageSource.camera);
//                     } else if (value == 'document') {
//                       pickDocument();
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     const PopupMenuItem(
//                       value: 'gallery',
//                       child: Text(
//                         'Gallery',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     const PopupMenuItem(
//                       value: 'camera',
//                       child: Text(
//                         'Camera',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     const PopupMenuItem(
//                       value: 'document',
//                       child: Text(
//                         'Document',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(width: 8),

//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // IMAGE PREVIEW
//                       if (selectedImage != null)
//                         Stack(
//                           children: [
//                             Container(
//                               margin: const EdgeInsets.only(bottom: 8),
//                               height: 80,
//                               width: 80,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(12),
//                                 image: DecorationImage(
//                                   image: FileImage(selectedImage!),
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               right: 0,
//                               child: GestureDetector(
//                                 onTap: () =>
//                                     setState(() => selectedImage = null),
//                                 child: const CircleAvatar(
//                                   radius: 12,
//                                   backgroundColor: Colors.red,
//                                   child: Icon(
//                                     Icons.close,
//                                     size: 14,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),

//                       // DOCUMENT PREVIEW
//                       if (selectedDocument != null)
//                         Container(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: Colors.white10,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.insert_drive_file,
//                                 color: Colors.white,
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   selectedDocumentName ?? 'Document',
//                                   style: const TextStyle(color: Colors.white),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               GestureDetector(
//                                 onTap: () => setState(() {
//                                   selectedDocument = null;
//                                   selectedDocumentName = null;
//                                 }),
//                                 child: const Icon(
//                                   Icons.close,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                       // TEXT INPUT ROW
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           color: const Color(0xff40414F),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: controller,
//                                 style: const TextStyle(color: Colors.white),
//                                 decoration: InputDecoration(
//                                   hintText: 'Message AI Assistant',
//                                   hintStyle: GoogleFonts.poppins(
//                                     color: Colors.white70,
//                                   ),
//                                   border: InputBorder.none,
//                                 ),
//                               ),
//                             ),

//                             // MIC BUTTON
//                             // FIX 12: Show disabled icon when speech unavailable
//                             GestureDetector(
//                               onLongPress: speechAvailable
//                                   ? startListening
//                                   : () => _showSnackBar(
//                                       'Speech recognition unavailable',
//                                     ),
//                               onLongPressUp: stopListening,
//                               child: Icon(
//                                 isListening ? Icons.mic : Icons.mic_none,
//                                 color: !speechAvailable
//                                     ? Colors.white30
//                                     : isListening
//                                     ? Colors.red
//                                     : Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(width: 10),

//                 // SEND BUTTON
//                 GestureDetector(
//                   onTap: sendMessage,
//                   child: Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xff10A37F),
//                     ),
//                     child: const Icon(Icons.send, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }import 'package:chatapp_ai/Views/View_model.dart';

import 'dart:io';
import 'package:chatapp_ai/Views/View_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xff343541),

      // ================= DRAWER (RESTORED) =================
      drawer: Drawer(
        backgroundColor: const Color(0xff202123),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Chats",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Divider(color: Colors.white24),

            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text(
                "New Chat",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                vm.clearChat();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xff202123),
        title: const Text("AI Assistant"),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // ================= CHAT LIST =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.messages.length,
              itemBuilder: (context, index) {
                final msg = vm.messages[index];

                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xff10A37F)
                          : const Color(0xff2A2B32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.history[msg.currentIndex],
                          style: const TextStyle(color: Colors.white),
                        ),

                        const SizedBox(height: 6),

                        // ================= IMAGE =================
                        if (msg.image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(msg.image!, height: 150),
                          ),

                        // ================= DOCUMENT =================
                        if (msg.documentName != null)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    msg.documentName!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 6),

                        // ================= ACTIONS =================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (msg.isUser)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                onPressed: () => vm.editMessage(index),
                              ),

                            if (!msg.isUser)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_left),
                                    onPressed: () => vm.prevVersion(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_right),
                                    onPressed: () => vm.nextVersion(index),
                                  ),
                                ],
                              ),

                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: msg.message),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= LOADING =================
          if (vm.isTyping)
            const Padding(
              padding: EdgeInsets.all(5),
              child: CircularProgressIndicator(),
            ),

          // ================= INPUT + PREVIEW =================
          Container(
            color: const Color(0xff202123),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- IMAGE PREVIEW ----------
                if (vm.selectedImage != null)
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(vm.selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: vm.removeImage,
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ---------- DOCUMENT PREVIEW ----------
                if (vm.selectedDocumentName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vm.selectedDocumentName!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        GestureDetector(
                          onTap: vm.removeDocument,
                          child: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  ),

                // ---------- INPUT ROW ----------
                Row(
                  children: [
                    PopupMenuButton(
                      icon: const Icon(Icons.attach_file, color: Colors.white),
                      onSelected: (value) {
                        if (value == "gallery") {
                          vm.pickImage(ImageSource.gallery);
                        } else if (value == "camera") {
                          vm.pickImage(ImageSource.camera);
                        } else {
                          vm.pickDocument();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "gallery", child: Text("Gallery")),
                        PopupMenuItem(value: "camera", child: Text("Camera")),
                        PopupMenuItem(value: "doc", child: Text("Document")),
                      ],
                    ),

                    Expanded(
                      child: TextField(
                        controller: vm.controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Message...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white),
                      onPressed: vm.startListening,
                    ),

                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: vm.sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
