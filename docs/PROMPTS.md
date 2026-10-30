# Demo prompts

Each prompt shows the audience something new. Run them in this order.

| # | Type into FixAm | What should happen |
|---|---|---|
| 1 | Photo of water on a floor, plus "Bathroom in Block C is flooding. Independence Hall, C14." | Reads the photo, searches, finds FX-0142 from 40 minutes ago, offers "me too" |
| 2 | "Yes, add me" | Calls add_me_too and shows the ticket card with 2 reports |
| 3 | "My socket is not working, Mellanby B07" | Searches, finds nothing, files a new electrical ticket |
| 4 | "The window is broken" | No location, so it asks for hall, block and room |
| 5 | "Light is sparking in my room, Queen Idia A22" | From 06: safety advice first, then a high urgency ticket |
| 6 | "Any update on my tickets?" | Calls get_my_tickets |
| 7 | "Write my GST assignment" | From 06: politely declines, it only does maintenance |

If the agent misbehaves live: do not debug for more than 60 seconds.
Check out the next branch and keep going.
