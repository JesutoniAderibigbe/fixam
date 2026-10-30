# The warden's agent (lesson 7)

No new app code. The student app filed tickets through its own agent. Now a
second agent, the warden's, works on the same Firestore data through
Firebase MCP.

## Setup on the warden's laptop
1. Sign in to the Firebase CLI with an account that has access to the
   project: `npx -y firebase-tools@latest login`
2. Connect Firebase MCP in the agent host. Claude Code:
   ```bash
   claude mcp add --scope project firebase -- npx -y firebase-tools@latest mcp
   ```
   Then run `/mcp` and check that `firebase` is connected.
3. Tell the agent which project to use, for example:
   "Use the Firebase project fixam-ibadan."

Firebase MCP uses the warden's own Firebase login, so it is not limited by
the student security rules. That is why status changes live here and not in
the app.

## Prompts for the demo
1. "How many tickets are open in each hall? Sort by urgency."
2. "Which hall has the most open plumbing tickets this week?"
3. "Show me every high urgency ticket that has been escalated."
4. "Mark FX-0142 as assigned and set updatedAt to now."
5. "Draft a short WhatsApp message to the Independence Hall porter listing
   today's high urgency tickets."

Prompt 4 changes real data. Read what the agent plans to do before you
approve the tool call. Same rule as the app: humans approve writes.

## Stretch: Genkit Dart and MCP
Genkit Dart (Preview) has a `genkit_mcp` package that can expose your own
tools as an MCP server. A small Dart server could serve
`search_open_tickets` to the warden's agent, so it calls your tested tool
instead of reading raw Firestore. Treat this as a bonus: Genkit Dart is in
Preview, and this repo does not include that server yet.
