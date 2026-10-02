---
name: release-locks
description: Release your FEATURES.md file locks for a branch after it is pushed, so teammates can edit those files. Use when the user says "release my locks", "unlock my files", or that they finished/pushed a feature and others can take over.
---

Run the release script from the project root, passing the branch name if the
user gave one (otherwise it uses the current branch):

```bash
bash .claude/scripts/release-locks.sh $ARGUMENTS
```

Then tell the user, in a short reply:
- which files were released, or
- why it refused (uncommitted changes, branch not pushed, unpushed commits) and
  the exact command to fix it. Offer to run that fix, then run the script again.

Never edit FEATURES.md by hand to work around a refusal: releasing before the
work is pushed would let a teammate edit an out-of-date file.
