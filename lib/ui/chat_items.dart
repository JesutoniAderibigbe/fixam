import 'dart:typed_data';

import '../models/ticket.dart';

/// Everything that can appear in the chat list.
sealed class ChatItem {
  const ChatItem();
}

class UserItem extends ChatItem {
  const UserItem(this.text, {this.photo});
  final String text;
  final Uint8List? photo;
}

class AgentItem extends ChatItem {
  const AgentItem(this.text);
  final String text;
}

/// A small chip that shows which tool the agent just called.
class ToolItem extends ChatItem {
  const ToolItem(this.toolName);
  final String toolName;
}

class TicketItem extends ChatItem {
  const TicketItem(this.ticket);
  final Ticket ticket;
}

class ErrorItem extends ChatItem {
  const ErrorItem(this.text);
  final String text;
}
