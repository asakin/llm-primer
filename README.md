# llm-primer

No more waiting for your LLM CLI to boot.

Every LLM CLI session starts cold. For a bare setup that's a few seconds — annoying but livable. For an LLM wiki (a `CLAUDE.md` with a session-start protocol, spend checks, inbox review, publishing signals) it can be 30–60 seconds of waiting every single time before you can type.

llm-primer keeps sessions pre-warmed in tmux. The startup protocol runs in the background; when you want a session you get one instantly, fully initialized.

```bash
primerd start    # start the daemon
primer attach    # get a warm session instantly
primer alt       # get the alt session (fast model, different tool — you configure it)
```

Works with any LLM CLI: Claude Code, Aider, Ollama, Gemini CLI, Simon Willison's `llm`. If your CLI takes >5s to boot, this helps.

---

## Why this exists

Built while developing [llm-context-base](https://github.com/asakin/llm-context-base), an LLM wiki framework whose sessions take 30–60s to initialize because the AI reads your profile, config, inbox state, publishing calendar, and more on every startup. Waiting every time was untenable.

It's not llm-context-base-specific — anything with a slow-ish startup benefits. But if you're running an LLM wiki today, you already know the pain.

---

## Pool layout

By default the pool keeps three sessions. What runs in each slot is up to you.

| Slot | What it runs | When to use it |
|---|---|---|
| 0 | `PRIMER_CLI` (your primary tool) | Main work |
| 1 | `PRIMER_CLI` (standby) | Fresh context when slot 0 gets heavy |
| 2 | `PRIMER_ALT_CLI` (alt — see below) | Quick tasks, cheaper model, different tool |

The alt slot is **not configured by default**. Set `PRIMER_ALT_CLI` to whatever makes sense for your setup. All three slots run `PRIMER_CLI` until you do.

---

## The alt slot

The idea: keep a different session warm alongside your main one. What "different" means is up to you.

Common uses:
- A faster/cheaper model for quick questions (saves cost and time for things that don't need full power)
- A completely different LLM tool (Claude for context-heavy work, Ollama for offline or local tasks)
- A different persona or context (same tool, different system prompt or project)

Configure it once in your config file or shell:

```bash
# Claude Haiku (fast, cheap)
PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001

# Local Ollama model (free, offline)
PRIMER_ALT_CLI=ollama run llama3.2:1b

# Aider with a smaller model
PRIMER_ALT_CLI=aider --model gpt-4o-mini

# A completely different tool
PRIMER_ALT_CLI=gemini
```

Then `primer alt` attaches to it instantly.

---

## Configuration

Three layers, in priority order:

1. **Environment variables** — always win
2. **Config file** (`~/.llm-primer/config`) — KEY=VALUE, one per line
3. **Built-in defaults**

Generate a starter config:

```bash
primerd config-template > ~/.llm-primer/config
```

The config file is plain text — no bash syntax, no quoting. Your LLM assistant can generate or update it on your behalf.

**Example config:**

```ini
# ~/.llm-primer/config

PRIMER_CLI=claude
PRIMER_POOL_SIZE=3
PRIMER_MODE=lazy

# Alt slot — set to enable; leave empty for uniform pool
PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001

# Watch your wiki config dir — triggers rewarm when files change
PRIMER_WATCH_DIR=~/path/to/your/wiki/_config

# Garbage collector — scans vault for stray files, moves to _inbox/
PRIMER_GC_VAULT=~/path/to/your/wiki
```

**Tell your LLM wiki to configure it:**

Add this to your `CLAUDE.md` (or equivalent):

```markdown
llm-primer config lives at ~/.llm-primer/config.
When asked to configure the alt slot or any primer setting, write to that file.
Format: KEY=value, one per line, comments with #.
Example: PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001
```

Now you can say "set my alt slot to Ollama llama3" and your assistant updates the file for you.

**Full variable reference:**

| Variable | Default | Description |
|---|---|---|
| `PRIMER_CLI` | `claude` | CLI for all slots unless overridden |
| `PRIMER_POOL_SIZE` | `3` | Number of pool slots |
| `PRIMER_MODE` | `lazy` | `lazy` or `eager` |
| `PRIMER_ALT_CLI` | *(empty)* | CLI for the alt slot. Empty = all slots run `PRIMER_CLI`. |
| `PRIMER_ALT_SLOT` | last slot | Which slot number is the alt |
| `PRIMER_SLOT_{N}_CLI` | *(none)* | Per-slot override (highest priority) |
| `PRIMER_RESET_CMD` | `/clear` | Soft-reset command. `""` = kill+respawn. |
| `PRIMER_WARMUP_MSG` | `ready` | Message sent to trigger session initialization |
| `PRIMER_WARMUP_MARKER` | `SESSION START` | String to watch for in output |
| `PRIMER_WARMUP_TIMEOUT` | `60` | Seconds to wait for warmup |
| `PRIMER_WATCH_DIR` | *(none)* | Dir to watch for changes (triggers rewarm) |
| `PRIMER_GC_VAULT` | *(none)* | Vault path for garbage collector (empty = disabled) |
| `PRIMER_GC_INTERVAL` | `3600` | Seconds between GC runs |
| `PRIMER_CONFIG` | `~/.llm-primer/config` | Config file path |

---

## Modes

### Lazy (default) — zero idle cost

The pool starts cold. Sessions warm on demand via a signal file (`~/.llm-primer/warm-request`). Any process can touch that file to request a warm slot.

**Wire up a PostCompact hook** (Claude Code) so Claude automatically warms a replacement when context gets heavy:

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

**Or tell your LLM assistant to ask before compaction starts.** Add to your `CLAUDE.md` (or equivalent):

```markdown
When your context is getting long (above ~70% of the window), ask:
"Context is getting heavy — want me to pre-warm a fresh session?
If yes, run `primer switch` in your terminal."
```

`primer switch` touches the warm-request file and prints next steps:

```
→ Switch requested. primerd is warming a fresh session.

When you're ready to switch:
  1. Open a new terminal (or new iTerm tab / Obsidian terminal tab)
  2. Run: primer attach

Your current session stays open. Copy anything you need before closing it.
```

### Eager — always-on pool

Always keeps `PRIMER_POOL_SIZE` sessions warm. A session is available before any signal, at the cost of idle startup runs.

```bash
export PRIMER_MODE=eager
primerd start
```

---

## Install

**macOS (Homebrew):**
```bash
brew tap asakin/llm-primer
brew install llm-primer
```

**Linux and macOS (curl):**
```bash
# Latest release (recommended)
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/v0.5.0/install.sh | VERSION=v0.5.0 bash

# Bleeding edge (tracks main)
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

The installer will ask if you want to set up a launchd agent (macOS) so primerd starts on login automatically. Strongly recommended — without it you have to run `primerd start` after every reboot.

**Requires:** `tmux` and whatever CLI you're using.

### Note on existing shell aliases

If you already have a shell alias or function wrapping your CLI that auto-sends a greeting (e.g. `claude()  { command claude "Hi" "$@"; }`), it will collide with primer's warmup message — you'll get two greetings per session.

Two ways to fix:

1. **Drop the alias.** Primer's `PRIMER_WARMUP_MSG` does the same thing, and the new default tells the LLM it's running in primer — which is better than "Hi".
2. **Bypass the alias in `PRIMER_CLI`.** Use `command` or an absolute path:
   ```ini
   PRIMER_CLI=command claude
   # or
   PRIMER_CLI=/opt/homebrew/bin/claude
   ```

---

## Open on every terminal

### iTerm2

Configure a profile to open directly into a warm session:

1. **iTerm2 → Preferences → Profiles → [your profile] → General**
2. Under **Command**, select **Command** and enter: `/usr/local/bin/primer attach`
3. Every new tab/window with that profile drops you into a live session.

### Obsidian embedded terminal

1. Open **Settings → Community Plugins → Obsidian Terminal**
2. Set **Custom Shell Command** to: `primer attach`
3. The terminal inside your vault opens directly into a warm session.

Both require primerd to already be running. The launchd agent handles that automatically on login.

---

## Garbage collector

`primer-gc` finds `.md` files that drifted into the wrong place in your vault and moves them to your inbox so they get filed properly.

Drift enters a wiki from two directions: AI output (fix with better instructions) and casual human drops (fix with a background worker). The GC is that worker.

```bash
primer gc ~/path/to/vault           # dry run — show what would move
primer gc ~/path/to/vault --auto    # move stray files to your inbox
primer gc ~/path/to/vault --lint    # flag frontmatter issues + duplicate slugs only
```

### What's stray (and how you change that)

A `.md` file is "stray" if it isn't in a `_*` directory, isn't in a named content directory, and isn't a recognized root-level file. The specifics — which directories count, which root files are recognized, where strays get moved — are governed by a **vault-scoped policy file** at `<vault>/.primer-gc`.

If no policy file exists, defaults kick in that are shaped like [llm-context-base](https://github.com/asakin/llm-context-base) vaults (`0-Ideas/`, `1-Projects/`, `2-Knowledge/`, etc.; filenames like `YYYY-MM-DD-slug.md`; strays moved to `_inbox/`). If that doesn't match your setup, override it.

### The `.primer-gc` policy file

Plain `KEY=value`, one per line, comments with `#`. Drop it at your vault root. Every field is optional — what you don't set falls back to the built-in default.

```ini
# <vault>/.primer-gc
#
# Directories where .md files are allowed (comma-separated)
ALLOWED_DIRS=notes,projects,references,archive

# Root-level files allowed as-is
ALLOWED_ROOT_FILES=README.md,INDEX.md

# Where strays get moved (relative to vault root)
INBOX_DIR=incoming

# Regex that filenames must match. Leave empty to skip the naming lint.
FILENAME_REGEX=

# Dirs where frontmatter is not required (raw capture zones)
LINT_SKIP_DIRS=incoming,scratch
```

### Let your LLM maintain it

The whole point of an LLM wiki is that the LLM knows your conventions. The `.primer-gc` file exists so the LLM can *tell the GC about those conventions* instead of forcing the GC to guess.

Add this to your `CLAUDE.md` (or equivalent):

```markdown
The GC policy for this vault is at `.primer-gc` (plain KEY=value).
When we add a new top-level content directory, update ALLOWED_DIRS.
When we introduce a new root-level convention file, update ALLOWED_ROOT_FILES.
When the filename convention changes, update FILENAME_REGEX.
```

Now when you tell your LLM "let's add a `6-Recipes/` directory for cooking content," it can update the policy at the same time. The GC learns without you editing a config file.

### Other pieces

**Never moved:** files in `_*` directories, assets (`.png`, `.pdf`, `.sh`, etc.), symlinks.

**Lint checks:** missing frontmatter blocks, duplicate file slugs across the vault.

**Run automatically:**

```ini
# ~/.llm-primer/config
PRIMER_GC_VAULT=~/path/to/your/wiki
PRIMER_GC_INTERVAL=3600
```

primerd runs primer-gc in the background. Moved files appear in your inbox on the next triage.

### What's coming (v0.6.0 direction — not shipped)

Static rules handle the 95% of cases that look obvious. The remaining 5% — "this file doesn't match any rule, but is it actually misplaced?" — deserves an LLM's judgment, not a heuristic.

The planned v0.6.0 architecture:
- Static rules run hot (hourly, no LLM call)
- Ambiguous files go to an "LLM review queue"
- A background worker drains the queue by asking a **warm idle session** (configurable — `use_slot: alt`) to make the call. The LLM already has your wiki's context loaded; no separate session needed
- Decisions get applied as moves

Track progress in RELEASE.md and the project issues.

---

## Self-test

Run the built-in test suite to verify your installation works:

```bash
primer selftest           # full suite
primer selftest --fast    # skip tests that need tmux
```

The suite runs without touching your real pool or making any LLM API calls. It uses a mock CLI and a temporary directory. Useful after upgrades, after changing your config, or when contributing a change.

---

## Usage reference

```
primerd start            Start the daemon
primerd stop             Stop the daemon
primerd status           Daemon and pool status
primerd config-template  Print a starter config file

primer attach            Attach to a warm session (first warm non-alt slot)
primer attach 1          Attach to slot 1 specifically
primer alt               Attach to the alt slot (PRIMER_ALT_CLI must be set)
primer switch            Pre-warm a replacement + print switch instructions
primer warm              Signal primerd to warm a session now
primer gc <vault>        Run the garbage collector
primer selftest          Run the self-test suite
primer status            Pool health
primer logs              Tail the daemon log
```

Shorthand: `primer a` = attach, `primer sw` = switch, `primer w` = warm, `primer s` = status.

```bash
alias cc='primer attach'    # warm session in two keystrokes
alias ca='primer alt'       # jump to alt slot
```

---

## Works with any LLM CLI

llm-primer sends keystrokes to a tmux window and watches for a string in the output. Change `PRIMER_CLI` to whatever you use:

```bash
# Local Ollama
PRIMER_CLI=ollama run llama3.2
PRIMER_WARMUP_MARKER=ready

# Aider
PRIMER_CLI=aider --model gpt-4o
PRIMER_WARMUP_MARKER="Aider v"

# Simon Willison's llm CLI
PRIMER_CLI=llm chat
PRIMER_WARMUP_MARKER="Chatting with"

# Gemini CLI
PRIMER_CLI=gemini
PRIMER_WARMUP_MARKER="Gemini"
```

If your tool has no soft-reset command, set `PRIMER_RESET_CMD=""` and primerd will kill and respawn the process instead of sending `/clear`.

---

## Known limitations

- **Relies on undocumented behavior.** `/clear` re-injecting `CLAUDE.md` and re-running the session protocol isn't in any spec. If it changes, warmth detection breaks silently. The selftest will catch this.
- **bash + tmux only.** VSCode/Cursor integrated terminal users: this won't work there. WSL2 works; native Windows doesn't.
- **macOS `stat` flags.** The config file watcher uses `stat -f` (macOS) with a Linux fallback. If the watcher fails silently on your distro, open an issue.
- **Eager mode token cost.** Warm sessions already ran the startup protocol. In lazy mode this doesn't happen until needed.

---

## Troubleshooting

**`pool: no tmux session found`**
Run `primerd start` first. If the launchd agent is installed but the pool is missing, the daemon may have crashed — check `primer logs`.

**Warmup times out (slot stays `warming` or goes to `stale`)**
Your CLI's output probably doesn't contain the default `SESSION START` marker. Set `PRIMER_WARMUP_MARKER` to a string that actually appears when your CLI is ready:
```ini
PRIMER_WARMUP_MARKER=Aider v   # for Aider
PRIMER_WARMUP_MARKER=>>>       # for Python REPL
```

**`primer attach` says "Pool session not found"**
primerd isn't running. Start it: `primerd start`. If you set up the launchd agent, check `launchctl list | grep primerd`.

**Config file changes aren't picked up**
Env vars always beat the config file. If you have `PRIMER_POOL_SIZE` exported somewhere, unset it or restart your shell. Or use `env -u PRIMER_POOL_SIZE primerd start` to verify the file value.

**Weird state after a crash**
Nuke the tmux session and restart:
```bash
primerd stop
tmux kill-session -t primer-pool
rm -rf ~/.llm-primer/state
primerd start
```

**Two greetings per session**
You probably have a shell alias/function around `claude` (or whatever CLI) that sends a greeting. See "Note on existing shell aliases" above.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: open an issue first for anything non-trivial, run `primer selftest` before submitting, and include the test output in your PR.

---

## License

MIT
