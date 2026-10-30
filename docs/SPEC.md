# FixAm spec

## The problem
Reporting a hostel fault means finding the porter, writing in a book, and
hoping. Five students report the same leak and nobody knows if anything is
happening.

## The agent
One chat screen. The student can attach a photo and type one line, for
example "Bathroom in Block C is flooding. Independence Hall, C14."

FixAm must:
1. Use the photo to decide the category and urgency.
2. Ask for hall, block or room if any is missing. Never guess a location.
3. Search open tickets for that hall, block and category before creating one.
4. If a matching ticket exists, offer to add the student to it ("me too").
5. Otherwise draft a ticket and show it to the student to confirm.
6. Put safety first: for sparks, burning smell, smoke, gas or exposed live
   wires, tell the student to leave the area and alert the hall porter, then
   file a high urgency ticket.
7. Decline anything that is not hostel maintenance.

## Tools (lib/agent/fixam_tools.dart)
| Tool | Purpose | Guard |
|---|---|---|
| search_open_tickets | Open tickets for hall, block, category | read only |
| create_ticket | New ticket from a draft | student confirms the draft card |
| add_me_too | Join an existing ticket | none |
| get_my_tickets | The student's tickets | read only |
| escalate_ticket | Flag a ticket to the warden | confirm, at most once per 24 hours |

## Data model: `tickets/{ticketId}`
| Field | Type | Notes |
|---|---|---|
| code | string | e.g. FX-7Q2K, shown to students |
| hall | string | Independence, Mellanby, Queen Idia, ... |
| block | string | single letter, upper case |
| room | string | e.g. C14 |
| category | string | plumbing, electrical, carpentry, cleaning, other |
| urgency | string | low, medium, high |
| description | string | one sentence a technician can act on |
| photoUrl | string or null | Cloud Storage download URL |
| status | string | open, assigned, fixed (wardens change this) |
| reporters | array of uid | first item is the creator |
| reportCount | int | reporters.length, kept for warden queries |
| escalatedAt | timestamp or null | |
| escalationReason | string or null | |
| createdAt, updatedAt | timestamp | server timestamps |

Three or more reporters raise urgency to high.

## Security (firestore.rules)
- Any signed-in student can read tickets (needed to find duplicates).
- A student can create a ticket only with themselves as the sole reporter.
- "Me too" may only add yourself to `reporters`.
- Only a reporter can escalate, once per 24 hours.
- Status changes come from wardens (admin access through Firebase MCP).

## Screens
- Chat: messages, tool activity chips, ticket cards, photo button.
- Draft dialog: shows the ticket before it is filed.
