/// Plain Dart models. No Firebase imports here, so tests stay fast.
library;

const ticketCategories = [
  'plumbing',
  'electrical',
  'carpentry',
  'cleaning',
  'other',
];

const ticketUrgencies = ['low', 'medium', 'high'];

/// Three or more students reporting the same fault makes it high urgency.
String urgencyAfterReports(String current, int reportCount) =>
    reportCount >= 3 ? 'high' : current;

/// "independence hall" -> "Independence", "queen idia" -> "Queen Idia".
String normaliseHall(String raw) {
  final words = raw
      .trim()
      .replaceAll(RegExp(r'\s+hall$', caseSensitive: false), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  return words
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// "block c" -> "C".
String normaliseBlock(String raw) => raw
    .trim()
    .replaceAll(RegExp(r'^block\s*', caseSensitive: false), '')
    .toUpperCase();

class Ticket {
  const Ticket({
    required this.id,
    required this.code,
    required this.hall,
    required this.block,
    required this.room,
    required this.category,
    required this.urgency,
    required this.description,
    required this.status,
    required this.reporters,
    required this.createdAt,
    this.photoUrl,
    this.escalatedAt,
  });

  final String id;
  final String code;
  final String hall;
  final String block;
  final String room;
  final String category;
  final String urgency;
  final String description;
  final String status;
  final List<String> reporters;
  final DateTime createdAt;
  final String? photoUrl;
  final DateTime? escalatedAt;

  int get reportCount => reporters.length;
  bool get isOpen => status != 'fixed';

  Ticket copyWith({
    List<String>? reporters,
    String? urgency,
    String? status,
    DateTime? escalatedAt,
  }) =>
      Ticket(
        id: id,
        code: code,
        hall: hall,
        block: block,
        room: room,
        category: category,
        urgency: urgency ?? this.urgency,
        description: description,
        status: status ?? this.status,
        reporters: reporters ?? this.reporters,
        createdAt: createdAt,
        photoUrl: photoUrl,
        escalatedAt: escalatedAt ?? this.escalatedAt,
      );

  /// What Gemini sees about a ticket. Small on purpose: fewer tokens,
  /// fewer mistakes, and no student ids.
  Map<String, Object?> toAgentJson({DateTime? now}) => {
        'id': id,
        'code': code,
        'hall': hall,
        'block': block,
        'room': room,
        'category': category,
        'urgency': urgency,
        'status': status,
        'description': description,
        'reportCount': reportCount,
        'minutesAgo': (now ?? DateTime.now()).difference(createdAt).inMinutes,
      };
}

/// A ticket before it is filed. Built from Gemini's tool arguments and
/// validated here, so bad arguments become an error Gemini can fix.
class TicketDraft {
  TicketDraft({
    required String hall,
    required String block,
    required String room,
    required this.category,
    required this.urgency,
    required this.description,
  })  : hall = normaliseHall(hall),
        block = normaliseBlock(block),
        room = room.trim().toUpperCase() {
    if (this.hall.isEmpty || this.block.isEmpty || this.room.isEmpty) {
      throw ArgumentError('hall, block and room are all required. Ask the student.');
    }
    if (!ticketCategories.contains(category)) {
      throw ArgumentError('category must be one of ${ticketCategories.join(', ')}');
    }
    if (!ticketUrgencies.contains(urgency)) {
      throw ArgumentError('urgency must be one of ${ticketUrgencies.join(', ')}');
    }
    if (description.trim().isEmpty || description.length > 300) {
      throw ArgumentError('description must be one sentence, under 300 characters');
    }
  }

  factory TicketDraft.fromArgs(Map<String, Object?> args) => TicketDraft(
        hall: '${args['hall'] ?? ''}',
        block: '${args['block'] ?? ''}',
        room: '${args['room'] ?? ''}',
        category: '${args['category'] ?? ''}'.toLowerCase(),
        urgency: '${args['urgency'] ?? ''}'.toLowerCase(),
        description: '${args['description'] ?? ''}'.trim(),
      );

  final String hall;
  final String block;
  final String room;
  final String category;
  final String urgency;
  final String description;
}
