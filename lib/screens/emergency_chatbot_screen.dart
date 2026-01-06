import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class EmergencyChatbotScreen extends StatefulWidget {
  const EmergencyChatbotScreen({super.key});

  @override
  State<EmergencyChatbotScreen> createState() =>
      _EmergencyChatbotScreenState();
}

class _EmergencyChatbotScreenState
    extends State<EmergencyChatbotScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> messages = [];

  Future<void> sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userText});
    });

    _controller.clear();

    final reply = await GeminiService.sendMessage(messages);

    setState(() {
      messages.add({"sender": "bot", "text": reply});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Assistant"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["sender"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.redAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText:
                        "Ask about first aid or emergency help...",
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.red),
                onPressed: sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}
