import 'dart:typed_data';

import '../models/ticket.dart';

/// Everything the app (and the agent) can do with tickets.
/// The agent's tools depend on this interface, so tests can use a fake.
abstract class TicketRepository {
  /// Open or assigned tickets for one hall, block and category.
  Future<List<Ticket>> searchOpen({
    required String hall,
    required String block,
    required String category,
  });

  Future<Ticket?> byId(String id);

  /// Files a new ticket with the current student as the only reporter.
  Future<Ticket> create(TicketDraft draft, {String? photoUrl});

  /// Adds the current student to an existing ticket ("me too").
  Future<({Ticket ticket, bool alreadyReported})> addReporter(String ticketId);

  /// Tickets the current student reported, newest first.
  Future<List<Ticket>> mine({bool onlyOpen = true});

  Future<void> markEscalated(String ticketId, String reason);

  /// Uploads a report photo and returns its download URL.
  Future<String> uploadPhoto(Uint8List bytes);
}
