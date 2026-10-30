import 'package:firebase_ai/firebase_ai.dart';

/// Check the Firebase AI Logic console for the newest Gemini model before
/// the workshop, and change it here.
const fixamModelName = 'gemini-2.5-flash';

const chatbotInstructions = '''
You are FixAm, a friendly maintenance assistant for University of Ibadan halls.
Keep replies to two short sentences.
''';

/// Lesson 2: a plain chatbot. It can talk about a leak, but it cannot do
/// anything about one. That is the "before" picture.
GenerativeModel buildChatbotModel() => FirebaseAI.googleAI().generativeModel(
      model: fixamModelName,
      systemInstruction: Content.text(chatbotInstructions),
    );
