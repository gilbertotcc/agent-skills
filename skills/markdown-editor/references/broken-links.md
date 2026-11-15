# Broken links

How to handle a link lychee reports as unreachable.

1. **Recheck it.** Open the URL with a web fetch tool, if the agent has one,
   or `curl -sIL <url>`, to tell a dead link from a flaky host.
2. **Replace a dead link,** unless step 4 applies. Search the web for the
   same content at a working URL (a moved page, an archived copy, a pinned
   tag) and swap it in.
3. **Exclude a link that works but fails the check** (auth wall, rate limit,
   bot blocking) only after the user confirms. Add it to the project's
   lychee ignore mechanism, usually `.lycheeignore` or `exclude` in
   `lychee.toml` (see
   [excluding links](https://lychee.cli.rs/recipes/excluding-links/)), with
   a dated comment:

   ```text
   # Reachable but fails the link check. (Last access: YYYY-MM-DD)
   ```

   The date is when the URL was last confirmed reachable: today if the user
   or the agent just checked it, else the latest pipeline run that did.
4. **Keep a dead link only in a historical record** (changelog, meeting
   notes, decision log) whose URL is part of the record, and only after the
   user confirms. If a replacement exists (a moved page, an archived copy),
   offer it first; keep the original only when none exists or the user says
   the record must keep it. Exclude it as in step 3, with this comment:

   ```text
   # Historical reference; the URL is no longer reachable. (Last access: YYYY-MM-DD)
   ```

   The date is when the link was last known to work, such as the last
   passing link-check run (e.g. the one before the run that reported it).
   If no such date can be found, ask the user.
5. **No ignore mechanism?** Tell the user the link stays broken and suggest
   adding the starter `.lycheeignore` (see [setup.md](setup.md)).

Fill in the real date; the committed comment contains no placeholders.
