# FixAm

A hostel maintenance agent built live in the workshop
**Beyond Chatbots: Building AI Agents in Flutter with Gemini, Firebase & MCP**
(Pre-DevFest Ibadan 2026, Jesutoni Aderibigbe).

A student snaps a photo of a fault and types one line. Gemini looks at the
photo, decides the category and urgency, checks for duplicates, and files or
joins a ticket in Firestore. Wardens query the same tickets from Claude Code
or Antigravity through Firebase MCP.

## Checkpoint branches
Fell behind? `git checkout` the next branch and keep going.

| Branch | What it adds |
|---|---|
| `00-empty` | AGENTS.md, CLAUDE.md, `.mcp.json`, docs/SPEC.md, a blank app |
| `01-firebase` | Firebase packages, rules, models, Firestore repository |
| `02-chatbot` | A plain Gemini chat. It talks, nothing more |
| `03-eyes` | Photos go to Gemini with the message |
| `04-tools-and-loop` | Five tools, the agent loop, unit tests |
| `05-human-in-loop` | Draft ticket card and confirm dialogs, ticket cards in chat |
| `06-guardrails` | App Check, safety rules in the instruction, escalation limit |
| `07-warden-mcp` | docs/WARDEN.md: the warden's agent reads tickets through Firebase MCP |

`main` equals `07-warden-mcp`.

## Run it on your machine
You need Flutter (Dart 3.9 or newer), Node.js, the Firebase CLI and the
FlutterFire CLI.

```bash
git clone <this repo> fixam && cd fixam
git checkout 00-empty

# Platform folders are not in git. Generate them (your lib/ is kept):
flutter create . --project-name fixam --platforms android,ios

# From 01-firebase onwards, connect your own Firebase project:
dart pub global activate flutterfire_cli
flutterfire configure

flutter pub get
flutter run
```

In the Firebase console: turn on **Firebase AI Logic** (Gemini Developer API),
**Anonymous** sign-in, **Cloud Firestore**, **Cloud Storage** and **App Check**.
Deploy the rules with `firebase deploy --only firestore:rules,storage`.

## App Check in debug
From `06-guardrails` the app uses App Check. On first debug run, copy the debug
token from the logs into Firebase console > App Check > Manage debug tokens.

## Tests
`flutter test` runs the tool tests with a fake repository. They never call
Gemini, so they are fast and give the same result every time.
