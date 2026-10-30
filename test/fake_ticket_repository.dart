import 'dart:typed_data';

import 'package:fixam/data/ticket_repository.dart';
import 'package:fixam/models/ticket.dart';

/// In-memory TicketRepository for tests. Mirrors the Firestore rules that
/// matter to the agent.
class FakeTicketRepository implements TicketRepository {
  FakeTicketRepository({this.uid = 'student-1', List<Ticket>? seed})
      : tickets = [...?seed];

  String uid;
  final List<Ticket> tickets;
  final escalations = <String, String>{};
  var _next = 1;

  @override
  Future<List<Ticket>> searchOpen({
    required String hall,
    required String block,
    required String category,
  }) async =>
      tickets
          .where((t) =>
              t.hall == normaliseHall(hall) &&
              t.block == normaliseBlock(block) &&
              t.category == category &&
              t.isOpen)
          .toList();

  @override
  Future<Ticket?> byId(String id) async {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<Ticket> create(TicketDraft draft, {String? photoUrl}) async {
    final id = 't${_next++}';
    final ticket = Ticket(
      id: id,
      code: 'FX-${id.toUpperCase()}',
      hall: draft.hall,
      block: draft.block,
      room: draft.room,
      category: draft.category,
      urgency: draft.urgency,
      description: draft.description,
      status: 'open',
      reporters: [uid],
      createdAt: DateTime(2026, 11, 1, 9),
      photoUrl: photoUrl,
    );
    tickets.add(ticket);
    return ticket;
  }

  @override
  Future<({Ticket ticket, bool alreadyReported})> addReporter(String ticketId) async {
    final i = tickets.indexWhere((t) => t.id == ticketId);
    if (i < 0) throw ArgumentError('No ticket with id $ticketId');
    final t = tickets[i];
    if (t.reporters.contains(uid)) return (ticket: t, alreadyReported: true);
    final reporters = [...t.reporters, uid];
    final updated = t.copyWith(
      reporters: reporters,
      urgency: urgencyAfterReports(t.urgency, reporters.length),
    );
    tickets[i] = updated;
    return (ticket: updated, alreadyReported: false);
  }

  @override
  Future<List<Ticket>> mine({bool onlyOpen = true}) async => tickets
      .where((t) => t.reporters.contains(uid) && (!onlyOpen || t.isOpen))
      .toList();

  @override
  Future<void> markEscalated(String ticketId, String reason) async {
    final i = tickets.indexWhere((t) => t.id == ticketId);
    tickets[i] = tickets[i].copyWith(escalatedAt: DateTime(2026, 11, 1, 10));
    escalations[ticketId] = reason;
  }

  @override
  Future<String> uploadPhoto(Uint8List bytes) async => 'https://example.com/photo.jpg';
}

Ticket seedTicket({
  String id = 'leak',
  String hall = 'Independence',
  String block = 'C',
  String category = 'plumbing',
  String urgency = 'medium',
  String status = 'open',
  List<String> reporters = const ['someone-else'],
  DateTime? escalatedAt,
}) =>
    Ticket(
      id: id,
      code: 'FX-0142',
      hall: hall,
      block: block,
      room: 'C11',
      category: category,
      urgency: urgency,
      description: 'Bathroom floor is flooding from a burst pipe.',
      status: status,
      reporters: reporters,
      createdAt: DateTime(2026, 11, 1, 8, 20),
      escalatedAt: escalatedAt,
    );
