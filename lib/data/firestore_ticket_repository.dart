import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/ticket.dart';
import 'ticket_repository.dart';

class FirestoreTicketRepository implements TicketRepository {
  FirestoreTicketRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection('tickets');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.uid;
  }

  @override
  Future<List<Ticket>> searchOpen({
    required String hall,
    required String block,
    required String category,
  }) async {
    final snap = await _tickets
        .where('hall', isEqualTo: normaliseHall(hall))
        .where('block', isEqualTo: normaliseBlock(block))
        .where('category', isEqualTo: category)
        .where('status', whereIn: ['open', 'assigned'])
        .limit(5)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<Ticket?> byId(String id) async {
    final doc = await _tickets.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<Ticket> create(TicketDraft draft, {String? photoUrl}) async {
    final ref = _tickets.doc();
    final code = 'FX-${ref.id.substring(0, 4).toUpperCase()}';
    await ref.set({
      'code': code,
      'hall': draft.hall,
      'block': draft.block,
      'room': draft.room,
      'category': draft.category,
      'urgency': draft.urgency,
      'description': draft.description,
      'photoUrl': photoUrl,
      'status': 'open',
      'reporters': [_uid],
      'reportCount': 1,
      'escalatedAt': null,
      'escalationReason': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Ticket(
      id: ref.id,
      code: code,
      hall: draft.hall,
      block: draft.block,
      room: draft.room,
      category: draft.category,
      urgency: draft.urgency,
      description: draft.description,
      status: 'open',
      reporters: [_uid],
      createdAt: DateTime.now(),
      photoUrl: photoUrl,
    );
  }

  @override
  Future<({Ticket ticket, bool alreadyReported})> addReporter(
      String ticketId) {
    final uid = _uid;
    final ref = _tickets.doc(ticketId);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw ArgumentError('No ticket with id $ticketId');
      final ticket = _fromDoc(doc);
      if (ticket.reporters.contains(uid)) {
        return (ticket: ticket, alreadyReported: true);
      }
      final reporters = [...ticket.reporters, uid];
      final urgency = urgencyAfterReports(ticket.urgency, reporters.length);
      tx.update(ref, {
        'reporters': reporters,
        'reportCount': reporters.length,
        'urgency': urgency,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (
        ticket: ticket.copyWith(reporters: reporters, urgency: urgency),
        alreadyReported: false,
      );
    });
  }

  @override
  Future<List<Ticket>> mine({bool onlyOpen = true}) async {
    // One array-contains filter, sorted on the device: no composite index.
    final snap = await _tickets.where('reporters', arrayContains: _uid).get();
    final tickets = snap.docs
        .map(_fromDoc)
        .where((t) => !onlyOpen || t.isOpen)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tickets;
  }

  @override
  Future<void> markEscalated(String ticketId, String reason) {
    return _tickets.doc(ticketId).update({
      'escalatedAt': FieldValue.serverTimestamp(),
      'escalationReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> uploadPhoto(Uint8List bytes) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('reports/$_uid/$name');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Ticket _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Ticket(
      id: doc.id,
      code: d['code'] as String? ?? 'FX-????',
      hall: d['hall'] as String? ?? '',
      block: d['block'] as String? ?? '',
      room: d['room'] as String? ?? '',
      category: d['category'] as String? ?? 'other',
      urgency: d['urgency'] as String? ?? 'medium',
      description: d['description'] as String? ?? '',
      status: d['status'] as String? ?? 'open',
      reporters: List<String>.from(d['reporters'] as List? ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: d['photoUrl'] as String?,
      escalatedAt: (d['escalatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
