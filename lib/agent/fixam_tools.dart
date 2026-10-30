import 'package:firebase_ai/firebase_ai.dart';

import '../data/ticket_repository.dart';
import '../models/ticket.dart';

/// Shows the student a ticket draft. True means "file it".
typedef ConfirmDraft = Future<bool> Function(TicketDraft draft);

/// Asks the student a yes or no question.
typedef ConfirmQuestion = Future<bool> Function(String question);

/// Runs the tools Gemini asks for. Plain Dart, so it is easy to test.
///
/// Every handler returns a Map that goes back to Gemini. Bad arguments
/// throw ArgumentError; the agent loop turns that into {'error': ...}
/// so Gemini can correct itself.
class FixAmTools {
  FixAmTools({
    required this.repo,
    required this.confirmDraft,
    required this.confirm,
    this.photoUrl,
    this.onTicket,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TicketRepository repo;

  /// Human in the loop: nothing is filed or escalated without a yes.
  final ConfirmDraft confirmDraft;
  final ConfirmQuestion confirm;

  /// URL of the most recent photo the student attached, if any.
  final String? Function()? photoUrl;

  /// Called with each ticket the agent creates or joins, so the UI can
  /// show it as a card.
  final void Function(Ticket ticket)? onTicket;

  final DateTime Function() _clock;

  Future<Map<String, Object?>> handle(FunctionCall call) async {
    final a = call.args;
    switch (call.name) {
      case 'search_open_tickets':
        return _search(a);
      case 'create_ticket':
        return _create(a);
      case 'add_me_too':
        return _meToo(_require(a, 'ticketId'));
      case 'get_my_tickets':
        return _mine(a['onlyOpen'] as bool? ?? true);
      case 'escalate_ticket':
        return _escalate(_require(a, 'ticketId'), _require(a, 'reason'));
      default:
        throw ArgumentError('Unknown tool: ${call.name}');
    }
  }

  Future<Map<String, Object?>> _search(Map<String, Object?> a) async {
    final category = _require(a, 'category').toLowerCase();
    if (!ticketCategories.contains(category)) {
      throw ArgumentError('category must be one of ${ticketCategories.join(', ')}');
    }
    final found = await repo.searchOpen(
      hall: _require(a, 'hall'),
      block: _require(a, 'block'),
      category: category,
    );
    final now = _clock();
    return {
      'count': found.length,
      'tickets': [for (final t in found) t.toAgentJson(now: now)],
    };
  }

  Future<Map<String, Object?>> _create(Map<String, Object?> a) async {
    final draft = TicketDraft.fromArgs(a);
    if (!await confirmDraft(draft)) {
      return {
        'status': 'cancelled_by_student',
        'next': 'Ask the student what to change.',
      };
    }
    final ticket = await repo.create(draft, photoUrl: photoUrl?.call());
    onTicket?.call(ticket);
    return {'status': 'created', 'id': ticket.id, 'code': ticket.code};
  }

  Future<Map<String, Object?>> _meToo(String ticketId) async {
    final result = await repo.addReporter(ticketId);
    final t = result.ticket;
    onTicket?.call(t);
    return {
      'status': result.alreadyReported ? 'already_reported' : 'added',
      'code': t.code,
      'reportCount': t.reportCount,
      'urgency': t.urgency,
      'ticketStatus': t.status,
    };
  }

  Future<Map<String, Object?>> _mine(bool onlyOpen) async {
    final tickets = await repo.mine(onlyOpen: onlyOpen);
    final now = _clock();
    return {
      'count': tickets.length,
      'tickets': [for (final t in tickets.take(10)) t.toAgentJson(now: now)],
    };
  }

  Future<Map<String, Object?>> _escalate(String ticketId, String reason) async {
    final t = await repo.byId(ticketId);
    if (t == null) return {'error': 'No ticket with id $ticketId.'};

    // Guardrail: the warden hears about a ticket at most once a day.
    final last = t.escalatedAt;
    if (last != null && _clock().difference(last) < const Duration(hours: 24)) {
      return {
        'error': '${t.code} was already escalated in the last 24 hours. '
            'Tell the student the warden has it.',
      };
    }

    if (!await confirm('Send ${t.code} to the hall warden?\n\nReason: $reason')) {
      return {'status': 'cancelled_by_student'};
    }
    await repo.markEscalated(ticketId, reason);
    return {'status': 'escalated', 'code': t.code};
  }

  static String _require(Map<String, Object?> a, String key) {
    final value = a[key];
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError('$key is required');
    }
    return value.trim();
  }
}
