# Lessons Learned

This directory records only concrete approaches that caused a bug, regression,
confusing interaction, or operational risk. It prevents the same failed
approach from being introduced again.

Current behavior belongs in the focused documents directly under `docs/`.

## Entry format

```md
## YYYY-MM-DD - Short problem title

Context:
- What the work was trying to achieve.

Failed approach:
- What the system did.

Problem observed:
- The concrete consequence.

Root cause:
- Why the approach failed.

Lesson:
- The stable warning that prevents repetition.
```

Do not add routine implementation summaries, plans, release notes, or current
contracts here.
