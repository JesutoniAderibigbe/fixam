import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../agent/fixam_model.dart';
import 'bubbles.dart';
import 'chat_items.dart';

/// Lesson 3: the chatbot can now see photos.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _items = <ChatItem>[
    const AgentItem('Hi, I am FixAm. What is broken in your hostel?'),
  ];
  final _input = TextEditingController();
  final _chat = buildChatbotModel().startChat();
  bool _busy = false;
  Uint8List? _photo; // attached, not sent yet

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photo = bytes);
  }

  Future<void> _send() async {
    final typed = _input.text.trim();
    final photo = _photo;
    if ((typed.isEmpty && photo == null) || _busy) return;
    final text = typed.isEmpty ? 'Here is a photo of the problem.' : typed;
    _input.clear();
    setState(() {
      _busy = true;
      _photo = null;
      _items.add(UserItem(text, photo: photo));
    });
    try {
      // One message, two parts: the words and the picture.
      final response = await _chat.sendMessage(Content.multi([
        TextPart(text),
        if (photo != null) InlineDataPart('image/jpeg', photo),
      ]));
      setState(() => _items.add(AgentItem(response.text ?? '')));
    } catch (e) {
      setState(() => _items.add(ErrorItem('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixAm')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in _items)
                  switch (item) {
                    UserItem(:final text, :final photo) =>
                      Bubble(text: text, mine: true, photo: photo),
                    AgentItem(:final text) => Bubble(text: text, mine: false),
                    ErrorItem(:final text) => Text(text,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    _ => const SizedBox.shrink(),
                  },
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_photo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photo!, height: 56, width: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Photo attached')),
                  IconButton(
                    onPressed: () => setState(() => _photo = null),
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove photo',
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    tooltip: 'Take a photo',
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    tooltip: 'Choose a photo',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Describe the problem',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
