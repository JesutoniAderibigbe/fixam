import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../agent/fixam_model.dart';
import 'bubbles.dart';
import 'chat_items.dart';

/// Lesson 2: a plain chatbot screen.
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

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _busy = true;
      _items.add(UserItem(text));
    });
    try {
      final response = await _chat.sendMessage(Content.text(text));
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
                    UserItem(:final text) => Bubble(text: text, mine: true),
                    AgentItem(:final text) => Bubble(text: text, mine: false),
                    ErrorItem(:final text) => Text(text,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    _ => const SizedBox.shrink(),
                  },
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
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
