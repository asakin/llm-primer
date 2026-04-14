# The alt slot

A designated slot running a different CLI from your primary. What "different" means is up to you.

Common uses:
- **Cheaper/faster model.** Keep a Haiku session warm for quick questions that don't need the full model.
- **Different tool entirely.** Claude for main work, Ollama for offline tasks.
- **Different context.** Same tool, different system prompt or project root.

## Configure it

Edit `~/.llm-primer/config`:

```ini
# Claude Haiku (fast, cheap)
PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001

# Local Ollama model (free, offline)
PRIMER_ALT_CLI=ollama run llama3.2:1b

# Aider with a cheaper model
PRIMER_ALT_CLI=aider --model gpt-4o-mini

# A completely different tool
PRIMER_ALT_CLI=gemini
```

Empty by default — when unset, all three slots run `PRIMER_CLI` (uniform pool).

## Use it

```bash
primer alt   # attach to the alt slot
```

If the alt slot is cold, `primer alt` warms it on demand (touches `~/.llm-primer/warm-request-2`) and waits briefly before attaching. Subsequent attaches are instant.

## Which slot is the alt?

Last slot in the pool, by default. For a pool of 3, that's slot 2. Override with `PRIMER_ALT_SLOT`.

## A different message per slot

Cheap/fast models usually want different instructions — shorter answers, less preamble. Set `PRIMER_ALT_WARMUP_MSG` for a preamble that only the alt slot sees:

```ini
PRIMER_ALT_WARMUP_MSG=You are the alt slot — a fast, cheap model. Keep answers short and direct unless asked otherwise. Please run your session start protocol.
```

Falls back to `PRIMER_WARMUP_MSG` if unset.

## Per-slot overrides

You can set any slot's CLI individually via `PRIMER_SLOT_{N}_CLI`:

```ini
PRIMER_SLOT_0_CLI=claude --model claude-opus-4-6
PRIMER_SLOT_1_CLI=claude
PRIMER_SLOT_2_CLI=ollama run llama3.2
```

This wins over `PRIMER_ALT_CLI` if both are set.
