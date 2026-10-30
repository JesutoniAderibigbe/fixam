import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../agent/fixam_agent.dart';
import '../agent/fixam_model.dart';
import '../agent/fixam_tools.dart';
import '../data/ticket_repository.dart';
import '../models/ticket.dart';
import 'bubbles.dart';
import 'chat_items.dart';
import 'draft_dialog.dart';
import 'ticket_card.dart';

/// The chat talks to an agent that uses tools (lesson 4) and asks the
/// student before it writes anything (lesson 5).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.repo});

  final TicketRepository repo;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _items = <ChatItem>[
    const AgentItem('Hi, I am FixAm. Snap the problem and tell me your hall, '
        'block and room. I will handle the rest.'),
  ];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final FixAmAgent _agent;

  bool _busy = false;
  Uint8List? _photo; // attached, not sent yet
  String? _photoUrl; // the last photo, uploaded, for create_ticket

  @override
  void initState() {
    super.initState();
    final tools = FixAmTools(
      repo: widget.repo,
      confirmDraft: _confirmDraft,
      confirm: _confirm,
      photoUrl: () => _photoUrl,
      onTicket: (ticket) => _add(TicketItem(ticket)),
    );
    _agent = FixAmAgent(
      model: buildFixAmModel(),
      tools: tools,
      onToolCall: (name) => _add(ToolItem(name)),
    );
  }

  /// Human in the loop: the agent loop waits here until the student answers.
  Future<bool> _confirmDraft(TicketDraft draft) async {
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DraftDialog(draft: draft),
    );
    return ok ?? false;
  }

  Future<bool> _confirm(String question) async {
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _add(ChatItem item) {
    if (!mounted) return;
    setState(() => _items.add(item));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photo = bytes);
  }

  Future<void> _send([String? preset]) async {
    final typed = (preset ?? _input.text).trim();
    final photo = _photo;
    if ((typed.isEmpty && photo == null) || _busy) return;
    final text = typed.isEmpty ? 'Here is a photo of the problem.' : typed;
    _input.clear();
    setState(() {
      _busy = true;
      _photo = null;
    });
    _add(UserItem(text, photo: photo));
    try {
      if (photo != null) _photoUrl = await widget.repo.uploadPhoto(photo);
      final reply = await _agent.send(text, photo: photo);
      if (reply.trim().isNotEmpty) _add(AgentItem(reply));
    } catch (e) {
      _add(ErrorItem('Something went wrong: $e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixAm'),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => _send('Show my open tickets'),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My tickets',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, i) => switch (_items[i]) {
                UserItem(:final text, :final photo) =>
                  Bubble(text: text, mine: true, photo: photo),
                AgentItem(:final text) => Bubble(text: text, mine: false),
                ToolItem(:final toolName) => _ToolChip(toolName: toolName),
                TicketItem(:final ticket) => TicketCard(ticket: ticket),
                ErrorItem(:final text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(text, style: TextStyle(color: scheme.error)),
                  ),
              },
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
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'What is broken, and where?',
                        border: OutlineInputBorder(),
                      ),
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

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.toolName});

  final String toolName;

  static const _labels = {
    'search_open_tickets': 'Checking for existing tickets',
    'create_ticket': 'Drafting a ticket',
    'add_me_too': 'Adding you to the ticket',
    'get_my_tickets': 'Looking up your tickets',
    'escalate_ticket': 'Escalating to the warden',
  };

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Chip(
          avatar: const Icon(Icons.build_circle_outlined, size: 18),
          label: Text(_labels[toolName] ?? toolName),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
