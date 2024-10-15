import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'chat_history_screen.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBotScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  bool isOnline = true;
  bool isListening = false;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool isProcessingGeminiResponse = false;

  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "User",
    profileImage:
    "https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_960_720.png",
  );

  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
    "https://seeklogo.com/images/G/gemini-logo-2D3A0A4F3A-seeklogo.com.png",
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkConnection();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  Future<void> _listen() async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.hasConfidenceRating && val.confidence > 0.75) {
              if (val.recognizedWords.isNotEmpty) {
                _sendMessage(ChatMessage(
                  user: currentUser,
                  createdAt: DateTime.now(),
                  text: val.recognizedWords,
                ));
              }
            } else if (val.finalResult) {
              print("Confianza insuficiente o tartamudeando");
            }
          },
          listenFor: const Duration(seconds: 5),
          cancelOnError: true,
          partialResults: true,
        );
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
    }
  }

  List<String> _splitTextIntoChunks(String text, int maxLength) {
    List<String> chunks = [];
    int start = 0;

    while (start < text.length) {
      int end = start + maxLength;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }

      end = text.lastIndexOf(' ', end);
      chunks.add(text.substring(start, end));
      start = end + 1;
    }

    return chunks;
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setPitch(1.0);

    List<String> chunks = _splitTextIntoChunks(text, 300);

    for (String chunk in chunks) {
      await _flutterTts.speak(chunk);
      await _flutterTts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _checkConnection() async {
    try {
      var result = await Connectivity().checkConnectivity();
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    } catch (e) {
      print("Error checking connectivity: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Gemini Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChat,
          ),
          IconButton(
            icon: Icon(isListening ? Icons.mic : Icons.mic_none),
            onPressed: _listen, // Agregar botón para activar/desactivar el micrófono
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DashChat(
              currentUser: currentUser,
              onSend: (message) {
                if (isOnline) {
                  _sendMessage(message);
                } else {
                  _showNoConnectionDialog();
                }
              },
              messages: messages,
              messageOptions: MessageOptions(
                messageDecorationBuilder: (ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
                  bool isUser = message.user.id == currentUser.id;
                  return BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  );
                },
                messageTextBuilder: (ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
                  return GestureDetector(
                    onTap: () {
                      // Leer el mensaje en voz alta al tocarlo
                      _speak(message.text);
                    },
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para limpiar el historial de chat
  void _clearChat() async {
    setState(() {
      messages.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin conexión'),
        content: const Text(
            'No tienes conexión a internet. Por favor, verifica tu conexión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonMessages =
    messages.map((message) => jsonEncode(message.toJson())).toList();
    await prefs.setStringList('chat_messages', jsonMessages);
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

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    print("Mensaje enviado: ${chatMessage.text}");
    _saveMessages();
    _sendToGemini(chatMessage);
  }

  void _sendToGemini(ChatMessage chatMessage) {
    if (isProcessingGeminiResponse) return;
    setState(() {
      isProcessingGeminiResponse = true;
    });
    try {
      if (chatMessage.customProperties == null) {
        String question = chatMessage.text;

        gemini.streamGenerateContent(question).listen(
              (event) {
            String response = event.content?.parts
                ?.fold("", (previous, current) => "$previous ${current.text}") ??
                "";
            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );

            setState(() {
              messages = [message, ...messages];
            });
            _saveMessages();

            if (!isProcessingGeminiResponse) {
              _speak(response);
            }
          },
          onDone: () {
            setState(() {
              isProcessingGeminiResponse = false;
            });
          },
          onError: (error) {
            print("Error al generar la respuesta: $error");
            setState(() {
              isProcessingGeminiResponse = false;
            });
          },
        );
      }
    } catch (error) {
      print("Error al enviar a Gemini: $error");
      setState(() {
        isProcessingGeminiResponse = false;
      });
    }
  }
}
