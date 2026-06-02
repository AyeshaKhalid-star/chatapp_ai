import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {

  static Future<String> sendMessage(
    String message, {
    File? image,
    File? document,
  }) async {
    try {
      String? base64Image;
      String? base64Document;

      String documentMimeType = "application/pdf";

      // ================= IMAGE =================
      if (image != null) {
        final imageBytes = await image.readAsBytes();

        base64Image = base64Encode(imageBytes);
      }

      // ================= DOCUMENT =================
      if (document != null) {
        final documentBytes = await document.readAsBytes();

        base64Document = base64Encode(documentBytes);

        // ===== Detect document type =====

        if (document.path.endsWith(".pdf")) {
          documentMimeType = "application/pdf";
        } else if (document.path.endsWith(".txt")) {
          documentMimeType = "text/plain";
        } else if (document.path.endsWith(".doc")) {
          documentMimeType = "application/msword";
        } else if (document.path.endsWith(".docx")) {
          documentMimeType =
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        }
      }

      // ================= API REQUEST =================

      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey",
        ),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({
          "contents": [
            {
              "parts": [
                // ================= IMAGE =================
                if (base64Image != null)
                  {
                    "inline_data": {
                      "mime_type": "image/jpeg",

                      "data": base64Image,
                    },
                  },

                // ================= DOCUMENT =================
                if (base64Document != null)
                  {
                    "inline_data": {
                      "mime_type": documentMimeType,

                      "data": base64Document,
                    },
                  },

                // ================= TEXT =================
                {"text": message},
              ],
            },
          ],
        }),
      );

      print(response.body);

      // ================= SUCCESS =================
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            "No response from AI";
      } else {
        return "Error ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }
}
