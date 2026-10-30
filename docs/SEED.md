# Seed data (lesson 1)

Paste this prompt into your agent host with Firebase MCP connected. The data
is invented sample data for the demo.

> Using Firebase MCP, in my Firestore database add these 6 documents to the
> `tickets` collection, matching the data model in docs/SPEC.md. Use
> reporters ["seed-user-1"], reportCount 1, photoUrl null, escalatedAt null,
> escalationReason null, and createdAt and updatedAt set to now minus the
> minutes shown.

| code | hall | block | room | category | urgency | status | description | minutes ago |
|---|---|---|---|---|---|---|---|---|
| FX-0142 | Independence | C | C11 | plumbing | high | open | Bathroom floor in Block C is flooding from a burst pipe under the sink. | 40 |
| FX-0151 | Independence | A | A03 | electrical | medium | assigned | Socket beside the reading table has no power. | 300 |
| FX-0163 | Mellanby | B | B07 | carpentry | low | open | Wardrobe door hinge is broken and the door will not close. | 1500 |
| FX-0170 | Queen Idia | A | A22 | cleaning | medium | open | Waste bin outside Block A has not been emptied for three days. | 720 |
| FX-0174 | Mellanby | D | D15 | plumbing | medium | fixed | Tap in the Block D kitchen was dripping all night. | 4000 |
| FX-0181 | Queen Idia | C | C09 | electrical | high | open | Corridor light is flickering and buzzing near the stairs. | 90 |

Then check: "List the open tickets in Independence Hall, Block C."
