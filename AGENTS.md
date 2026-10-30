# FixAm

Hostel maintenance agent for University of Ibadan halls. A student snaps a
photo of a fault and types one line. Gemini (through Firebase AI Logic) works
out the category and urgency, checks for duplicate tickets, then files or
joins a ticket in Cloud Firestore. Wardens read the same tickets from their
own AI agent through Firebase MCP.

Read docs/SPEC.md before building any feature.

## Stack
- Flutter (Android and iOS), Dart 3.9 or newer
- Firebase: Auth (anonymous), Cloud Firestore, Cloud Storage, App Check
- Gemini through `firebase_ai` (Firebase AI Logic). Never put an API key in code.

## Commands
- `flutter analyze` must be clean
- `flutter test` must be green

## Layout
- `lib/models/` plain Dart models, no Firebase imports
- `lib/data/` repositories (the only code that talks to Firestore and Storage)
- `lib/agent/` the model, the tools and the agent loop
- `lib/ui/` widgets and screens
- `test/` unit tests with fake repositories

## Rules for the in-app agent
- Tools live in `lib/agent/fixam_tools.dart`. Maximum 5 tools.
- `create_ticket` and `escalate_ticket` must ask the student before writing.
- Tool handlers return `Map<String, Object?>`. Errors go back to Gemini as
  `{'error': ...}`, never to the UI as an exception.
- The agent loop stops after 6 steps.
- Every tool gets a unit test that uses `FakeTicketRepository`.

## Firestore
- Collection `tickets`, shape in docs/SPEC.md.
- Security rules live in `firestore.rules`. Change the rules and the
  repository together.

## Done means
`flutter analyze` clean, `flutter test` green, and the demo prompts in
docs/PROMPTS.md work on a real device.
