# Troubleshooting

## `pool: no tmux session found`

primerd isn't running. Start it: `primerd start`. If you set up the launchd agent, check it's loaded: `launchctl list | grep primerd`.

## Warmup times out (slot stays `warming` then goes `stale`)

Your CLI doesn't print the default `SESSION START` marker. Set `PRIMER_WARMUP_MARKER` to a string that actually appears when your CLI is ready:

```ini
PRIMER_WARMUP_MARKER=Aider v        # for Aider
PRIMER_WARMUP_MARKER=>>>            # for a Python-style REPL
PRIMER_WARMUP_MARKER=Chatting with  # for llm chat
```

## `primer attach` says "Pool session not found"

primerd isn't running. Same fix as above.

## Config file changes aren't picked up

Environment variables always beat the config file. If you have `PRIMER_POOL_SIZE` exported somewhere, unset it or restart your shell. To verify the config file value alone:
```bash
env -u PRIMER_POOL_SIZE primerd start
```

## Two greetings per session

You probably have a shell alias or function around `claude` (or whatever CLI) that auto-sends a greeting. It collides with primer's `PRIMER_WARMUP_MSG`. Two fixes:

1. **Drop the alias.** Primer does the same thing; the new default preamble is strictly better than a bare "Hi".
2. **Bypass the alias in `PRIMER_CLI`:**
   ```ini
   PRIMER_CLI=command claude
   # or
   PRIMER_CLI=/opt/homebrew/bin/claude
   ```

## Weird state after a crash

Nuke the pool and start fresh:
```bash
primerd stop
tmux kill-session -t primer-pool
rm -rf ~/.llm-primer/state
primerd start
```

You don't need to reconfigure anything — `~/.llm-primer/config` stays put.

## GC is flagging files I don't want flagged

Add to `<vault>/.primer-gc`:
- A new dir to `ALLOWED_DIRS` → files in it stop being stray
- A new filename to `ALLOWED_ROOT_FILES` → that root file stops being stray
- A dir to `SCAN_EXCLUDE_DIRS` → the GC won't walk into it at all
- Change `FILENAME_REGEX` or set it empty → naming lint relaxes

See [garbage-collector.md](garbage-collector.md).

## `primer alt` fails with "Alt slot not configured"

`PRIMER_ALT_CLI` is empty. Set it in `~/.llm-primer/config`:

```ini
PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001
```

Or pick a different tool — see [alt-slot.md](alt-slot.md) for examples.

## The Obsidian embedded terminal doesn't render cleanly

ObsidianTerminal uses xterm.js. Mouse support and some ANSI sequences can misbehave. Workarounds:
- Use iTerm2 alongside Obsidian
- Resize the Obsidian pane after attaching (forces tmux to redraw)
- Run `tmux kill-server` and attach again if things get really weird

## Logs

```bash
primer logs   # tail ~/.llm-primer/primerd.log
```

Most issues show up here. If you're filing a bug, include the last 50 lines.
