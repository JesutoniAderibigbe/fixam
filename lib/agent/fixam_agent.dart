import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import 'fixam_tools.dart';

/// The agent loop: send the message, run any tools Gemini asks for, send
/// the results back, and repeat until Gemini answers in words.
class FixAmAgent {
  FixAmAgent({
    required GenerativeModel model,
    required this.tools,
    this.maxSteps = 6,
    this.onToolCall,
  }) : _chat = model.startChat();

  final FixAmTools tools;

  /// A guardrail: never let one message run tools forever.
  final int maxSteps;

  /// Lets the UI show which tool is running.
  final void Function(String toolName)? onToolCall;

  /// One chat session, so FixAm remembers the whole conversation.
  final ChatSession _chat;

  Future<String> send(String text, {Uint8List? photo}) async {
    var response = await _chat.sendMessage(Content.multi([
      TextPart(text),
      if (photo != null) InlineDataPart('image/jpeg', photo),
    ]));

    for (var step = 0; step < maxSteps; step++) {
      final calls = response.functionCalls.toList();
      if (calls.isEmpty) return response.text ?? '';

      final results = <FunctionResponse>[];
      for (final call in calls) {
        onToolCall?.call(call.name);
        try {
          results.add(FunctionResponse(call.name, await tools.handle(call)));
        } catch (e) {
          // Let Gemini see the problem and fix its next call.
          results.add(FunctionResponse(call.name, {'error': e.toString()}));
        }
      }
      response = await _chat.sendMessage(Content.functionResponses(results));
    }
    return 'I got stuck on that one. Please describe the problem again.';
  }
}
