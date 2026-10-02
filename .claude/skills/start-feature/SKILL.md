---
name: start-feature
description: Plan a new feature and lock the files it will touch in the shared FEATURES.md before any code is written. Use when the user says "/start-feature <name>", "start a new feature", or "plan the <x> feature" and wants to claim the work.
---

Arguments: `$ARGUMENTS` — a feature name, optionally followed by " - " and a
short description (e.g. `wishlist - users can save products`).

1. **Name it.** Turn the name into a slug (lowercase, dashes: `wishlist`,
   `product-reviews`). Ask for a name if none was given.

2. **Plan.** Read the relevant code and work out the exact files the feature
   will create or modify (project-relative paths, e.g. `lib/pages/x.dart`).
   Keep the list to what is really needed. Files in `test/` are shared and are
   never locked, so leave them out of the list.

3. **Check locks** — this changes nothing:
   ```bash
   bash .claude/scripts/lock-files.sh --check <file1> <file2> ...
   ```
   - `CONFLICT`: tell the user who holds which file and offer choices: wait
     for that person to `/release-locks`, coordinate with them, or change the
     plan to avoid the file. Re-check after any plan change.
   - `COORDINATE` files are allowed but shared; mention them.

4. **Ask for approval.** Show the plan, the file list (new / changed), and the
   lock check result. Do not lock or edit anything until the user approves.

5. **After approval:**
   ```bash
   git switch main && git pull          # skip if there are uncommitted changes; ask the user first
   git switch -c feature/<slug>
   bash .claude/scripts/lock-files.sh <slug> <file1> <file2> ...
   ```
   If `lock-files.sh` reports a conflict (someone locked a file in the
   meantime), stop and tell the user.

6. **Knowledge base.** Next to FEATURES.md (the directory of `FEATURES_MD` in
   `.claude/settings.local.json`), create `features/<slug>/` with
   `status.md` (plan + checklist), `discoveries.md` and `blockers.md`, if they
   don't exist.

7. **Report** in a few lines: branch created, files locked, knowledge-base
   folder. Ask whether to start building now.

Never edit lock lines in FEATURES.md by hand, and never work around a blocked
edit — tell the user who owns the file.
