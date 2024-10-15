import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Método para cargar mensajes desde SharedPreferences
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonMessages = prefs.getStringList('chat_messages');
    if (jsonMessages != null) {
      setState(() {
        messages = jsonMessages
            .map((jsonMessage) =>
            ChatMessage.fromJson(jsonDecode(jsonMessage)))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Mensajes'),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            title: Text(message.user.firstName ?? 'Usuario'),
            subtitle: Text(message.text),
            trailing: Text(message.createdAt.toString()),
          );
        },
      ),
    );
  }
}
