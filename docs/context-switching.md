# Context switching

When your LLM session's context gets heavy (80%, 90% of the window), you want to jump to a fresh one without losing momentum. llm-primer has three mechanisms that work together.

## `primer switch`

Run this when you want to move to a fresh session:

```bash
primer switch
```

It touches `~/.llm-primer/warm-request` and prints next steps:

```
→ Switch requested. primerd is warming a fresh session.

When you're ready to switch:
  1. Open a new terminal (or new iTerm tab / Obsidian terminal tab)
  2. Run: primer attach

Your current session stays open. Copy anything you need before closing it.
```

The replacement warms in the background while you finish your current thread. By the time you're ready, it's already initialized.

## Automatic — PostCompact hook

Claude Code fires a `PostCompact` hook when it compacts context. Wire it up so primer warms a replacement automatically:

```json
// .claude/settings.json
{
  "hooks": {
    "PostCompact": [{
      "hooks": [{
        "type": "command",
        "command": "touch ~/.llm-primer/warm-request"
      }]
    }]
  }
}
```

Zero-effort: by the time you notice context is getting heavy, a fresh session is already warming.

## Automatic — LLM prompts you

The default `PRIMER_WARMUP_MSG` tells the LLM it's running inside primer and asks it to suggest `primer switch` when context gets heavy. For most CLIs this is all you need.

If your LLM setup has its own `CLAUDE.md` or equivalent, you can reinforce it:

```markdown
When your context is getting long (around 70% of the window), ask:
"Context is getting heavy — want me to pre-warm a fresh session?
If yes, run `primer switch` in your terminal."
```

---

## Why three?

- `primer switch` covers the manual case (you notice first).
- `PostCompact` covers the Claude-Code-specific case (Claude notices first).
- `CLAUDE.md` instruction covers the general LLM case (the LLM notices first and tells you).

They don't conflict — whichever fires first warms a slot; the others become no-ops because primerd ignores warm requests when a slot is already warming.
