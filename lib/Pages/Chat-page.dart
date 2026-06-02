import 'dart:io';
import 'package:chatapp_ai/Views/View_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
              padding: const EdgeInsets.all(10),
              itemCount: vm.messages.length,
              itemBuilder: (context, index) {
                final msg = vm.messages[index];
                //print("MESSAGE TIME => ${msg.createdAt}");

                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: msg.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // ================= BUBBLE =================
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        padding: const EdgeInsets.all(10),
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

                            if (msg.image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(msg.image!, height: 150),
                              ),

                            if (msg.documentName != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  msg.documentName!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ================= ACTIONS + TIME (OUTSIDE BUBBLE) =================
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg.isUser)
                              GestureDetector(
                                onTap: () => vm.editMessage(index),
                                child: const Icon(
                                  Icons.edit,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(width: 4),

                            // if (!msg.isUser) ...[
                            //   GestureDetector(
                            //     onTap: () => vm.prevVersion(index),
                            //     child: const Icon(
                            //       Icons.arrow_left,
                            //       size: 15,
                            //       color: Colors.white70,
                            //     ),
                            //   ),
                            //   const SizedBox(width: 2),

                            //   GestureDetector(
                            //     onTap: () => vm.nextVersion(index),
                            //     child: const Icon(
                            //       Icons.arrow_right,
                            //       size: 15,
                            //       color: Colors.white70,
                            //     ),
                            //   ),
                            // ],
                            const SizedBox(width: 2),

                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: msg.message),
                                );
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 10,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Text(
                              DateFormat('hh:mm a').format(msg.createdAt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
