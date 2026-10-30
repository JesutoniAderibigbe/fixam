import 'package:firebase_ai/firebase_ai.dart';
import 'package:fixam/agent/fixam_tools.dart';
import 'package:fixam/models/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_ticket_repository.dart';

void main() {
  final now = DateTime(2026, 11, 1, 9);
  late FakeTicketRepository repo;
  late FixAmTools tools;
  late bool studentSaysYes;
  late int questionsAsked;

  FixAmTools buildTools({String? photo}) => FixAmTools(
        repo: repo,
        clock: () => now,
        photoUrl: () => photo,
        confirmDraft: (_) async {
          questionsAsked++;
          return studentSaysYes;
        },
        confirm: (_) async {
          questionsAsked++;
          return studentSaysYes;
        },
      );

  setUp(() {
    repo = FakeTicketRepository(seed: [seedTicket()]);
    studentSaysYes = true;
    questionsAsked = 0;
    tools = buildTools();
  });

  group('search_open_tickets', () {
    test('finds the open leak, even with messy hall and block names', () async {
      final result = await tools.handle(FunctionCall('search_open_tickets', {
        'hall': 'independence hall',
        'block': 'block c',
        'category': 'plumbing',
      }));
      expect(result['count'], 1);
      final ticket = (result['tickets'] as List).single as Map;
      expect(ticket['code'], 'FX-0142');
      expect(ticket['minutesAgo'], 40);
    });

    test('rejects a category that does not exist', () {
      expect(
        tools.handle(FunctionCall('search_open_tickets', {
          'hall': 'Independence',
          'block': 'C',
          'category': 'magic',
        })),
        throwsArgumentError,
      );
    });
  });

  group('create_ticket', () {
    test('creates a ticket with the attached photo', () async {
      tools = buildTools(photo: 'https://example.com/socket.jpg');
      final result = await tools.handle(FunctionCall('create_ticket', {
        'hall': 'Mellanby',
        'block': 'b',
        'room': 'b07',
        'category': 'electrical',
        'urgency': 'medium',
        'description': 'Socket beside the bed has no power.',
      }));
      expect(result['status'], 'created');
      final created = repo.tickets.last;
      expect(created.block, 'B');
      expect(created.room, 'B07');
      expect(created.photoUrl, 'https://example.com/socket.jpg');
      expect(questionsAsked, 1);
    });

    test('writes nothing when the student says no', () async {
      studentSaysYes = false;
      final result = await tools.handle(FunctionCall('create_ticket', {
        'hall': 'Mellanby',
        'block': 'B',
        'room': 'B07',
        'category': 'electrical',
        'urgency': 'medium',
        'description': 'Socket beside the bed has no power.',
      }));
      expect(result['status'], 'cancelled_by_student');
      expect(repo.tickets, hasLength(1)); // only the seed ticket
    });

    test('refuses a ticket with no room, so Gemini asks the student', () {
      expect(
        tools.handle(FunctionCall('create_ticket', {
          'hall': 'Mellanby',
          'block': 'B',
          'room': '',
          'category': 'electrical',
          'urgency': 'medium',
          'description': 'Socket has no power.',
        })),
        throwsArgumentError,
      );
    });
  });

  group('add_me_too', () {
    test('adds the student once, and reports a second try', () async {
      final first = await tools.handle(FunctionCall('add_me_too', {'ticketId': 'leak'}));
      expect(first['status'], 'added');
      expect(first['reportCount'], 2);

      final again = await tools.handle(FunctionCall('add_me_too', {'ticketId': 'leak'}));
      expect(again['status'], 'already_reported');
      expect(again['reportCount'], 2);
    });

    test('three reports make it high urgency', () async {
      await tools.handle(FunctionCall('add_me_too', {'ticketId': 'leak'}));
      repo.uid = 'student-2';
      final third = await tools.handle(FunctionCall('add_me_too', {'ticketId': 'leak'}));
      expect(third['reportCount'], 3);
      expect(third['urgency'], 'high');
    });
  });

  test('get_my_tickets lists only my tickets', () async {
    await tools.handle(FunctionCall('add_me_too', {'ticketId': 'leak'}));
    final mine = await tools.handle(FunctionCall('get_my_tickets', {'onlyOpen': true}));
    expect(mine['count'], 1);
  });

  group('escalate_ticket', () {
    test('asks first, then escalates', () async {
      final result = await tools.handle(FunctionCall('escalate_ticket', {
        'ticketId': 'leak',
        'reason': 'Flooding for two hours.',
      }));
      expect(result['status'], 'escalated');
      expect(questionsAsked, 1);
      expect(repo.escalations['leak'], 'Flooding for two hours.');
    });

    test('does nothing when the student says no', () async {
      studentSaysYes = false;
      final result = await tools.handle(FunctionCall('escalate_ticket', {
        'ticketId': 'leak',
        'reason': 'Flooding for two hours.',
      }));
      expect(result['status'], 'cancelled_by_student');
      expect(repo.escalations, isEmpty);
    });
  });

  test('an unknown tool is a loud error', () {
    expect(tools.handle(FunctionCall('order_pizza', {})), throwsArgumentError);
  });

  test('urgencyAfterReports', () {
    expect(urgencyAfterReports('low', 2), 'low');
    expect(urgencyAfterReports('low', 3), 'high');
  });
}
