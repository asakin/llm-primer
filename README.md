# llm-primer

No more waiting for your LLM CLI to boot.

llm-primer keeps pre-warmed sessions ready in tmux — Claude Code, Aider, a local Ollama model, anything with a startup protocol. When you need a session, you get one instantly — fully initialized, context already loaded, ready to type.

## How it works

```bash
primerd start    # start the daemon
primer attach    # get a warm session instantly
primer haiku     # get the cheap haiku session for quick tasks
```

The daemon watches for `SESSION START` in the tmux pane output. When it appears, the session is warm. When you attach, the slot re-warms in the background.

---

## Pool layout

By default, the pool keeps three sessions:

| Slot | Model | When to use |
|---|---|---|
| 0 | Claude (primary) | Main work |
| 1 | Claude (standby) | Fresh context when slot 0 gets heavy |
| 2 | Claude Haiku | Quick questions, cheap tasks, things you'd normally skip because they aren't worth the cost |

**The haiku slot is the point.** You have a fast, cheap session sitting warm at all times. Use it for "is this right?", quick lookups, generating a short draft — things where you'd normally just not bother asking because firing up a full session isn't worth it. Now you just run `primer haiku`.

---

## Modes

### Lazy (default) — zero idle cost

The pool starts cold. Sessions only warm when Claude signals that one is needed. No background token burn for sessions that might never be used.

**The signal:** any process touches `~/.llm-primer/warm-request`. primerd sees the file, warms a slot, deletes the file.

**Recommended: wire up the PostCompact hook.** When Claude Code compacts context (a sign the session is getting heavy and will likely end soon), it automatically requests a warm replacement:

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

**Or add to CLAUDE.md** so Claude asks you before compaction starts:

```markdown
When your context is getting long (above ~70% of the window), ask the user:
"Your context is getting heavy — want me to pre-warm a fresh session so you
can switch cleanly? Run `primer switch` to set it up."
If they say yes, run: touch ~/.llm-primer/warm-request
```

**Or trigger manually:**

```bash
primer warm      # warm a session now
primer switch    # warm + print switch instructions
```

`primer switch` pre-warms a replacement and tells you exactly what to do:

```
→ Switch requested. primerd is warming a fresh session.

When you're ready to switch:
  1. Open a new terminal (or iTerm tab)
  2. Run: primer attach

Your current session stays open — copy anything you need before closing it.
```

### Eager — always-on pool

Always keeps `PRIMER_POOL_SIZE` sessions warm. A warm session is always available even before any signal, at the cost of idle startup runs.

```bash
export PRIMER_MODE=eager
primerd start
```

---

## Install

**macOS:**
```bash
brew tap asakin/llm-primer
brew install llm-primer
```

**Linux (and macOS if you prefer):**
```bash
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

The installer will ask if you want to set up a launchd agent (macOS) so primerd starts automatically on login. Recommended — without it you have to run `primerd start` manually after each reboot.

**Requires:** `tmux` and whatever CLI you're using (`claude`, `aider`, `ollama`, etc.)

---

## Open on every terminal

### iTerm2

Configure a profile to open directly into a warm session:

1. **iTerm2 → Preferences → Profiles → [your profile] → General**
2. Under **Command**, select **Command** and enter: `/usr/local/bin/primer attach`
3. Every new tab/window with that profile opens straight into a warm Claude session.

### Obsidian embedded terminal (ObsidianTerminal plugin)

1. Open **Obsidian Settings → Community Plugins → Obsidian Terminal**
2. Set **Custom Shell Command** to: `primer attach`
3. The terminal inside your vault opens directly into a warm session.

Both require primerd to already be running. With the launchd agent installed, that's automatic on login.

---

## Garbage collector

The garbage collector (`primer-gc`) finds files that ended up in the wrong place in your vault and moves them into `_inbox/` so they can be filed properly.

This matters because drift enters a wiki from two directions: bad AI output (addressed by instructions) and casual human drops (addressed by primer-gc). A file dropped directly into `1-Projects/` without a metadata header, or an idea parked wherever the cursor happened to be — these accumulate and make the wiki less queryable over time.

```bash
# Dry run — see what would move
primer gc ~/path/to/vault

# Actually move stray files to _inbox/
primer gc ~/path/to/vault --auto

# Just check for frontmatter issues and duplicate slugs
primer gc ~/path/to/vault --lint
```

**What's considered stray:**
- Any `.md` file not in `_inbox/`, `_output/`, `_meta/`, `_config/`, `_divergence/`, `_seeds/`, or any `_*` directory
- Not in a named content directory (`0-Ideas/`, `1-Projects/`, `2-Knowledge/`, etc.)
- Not a known root-level file (`README.md`, `PHILOSOPHY.md`, `CLAUDE.md`, etc.)

**Never moved:** files in `_*` directories, asset files (images, PDFs, scripts), symlinks.

**Additional checks (`--lint`):**
- `.md` files without a frontmatter block (`--- ... ---`)
- Duplicate file slugs across the vault

**Automate it via primerd:**

```bash
export PRIMER_GC_VAULT=~/path/to/your/vault
export PRIMER_GC_INTERVAL=3600   # run every hour (default)
primerd start
```

primerd runs primer-gc in the background on the configured interval. Moves go into `_inbox/` silently — you'll find them in your normal morning triage.

**Configure allowed directories:**

```bash
export GC_ALLOWED_DIRS="archive,scratch,reference"
primer gc ~/vault --auto
```

---

## Usage

```
primerd start            Start the daemon
primerd stop             Stop the daemon
primerd status           Show daemon and pool status

primer attach            Attach to a warm session (auto-picks first warm non-haiku slot)
primer attach 1          Attach to slot 1 specifically
primer haiku             Attach to the haiku slot (fast, cheap)
primer switch            Pre-warm a replacement and print switch instructions
primer warm              Signal primerd to warm a session now
primer gc <vault>        Run the garbage collector against a vault
primer status            Show pool health
primer logs              Tail the daemon log
```

Shorthand: `primer a` = attach, `primer h` = haiku, `primer sw` = switch, `primer w` = warm, `primer s` = status.

```bash
alias cc='primer attach'    # warm claude session in two keystrokes
alias ch='primer haiku'     # jump to haiku
```

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `PRIMER_CLI` | `claude` | Default CLI for all slots |
| `PRIMER_SLOT_{N}_CLI` | *(none)* | Per-slot CLI override (takes priority over everything) |
| `PRIMER_HAIKU_SLOT` | last slot | Which slot runs Haiku. Set to `-1` to disable. |
| `PRIMER_HAIKU_CLI` | `claude --model claude-haiku-4-5-20251001` | Haiku slot CLI |
| `PRIMER_RESET_CMD` | `/clear` | Command to reset session context. Set to `""` to kill+respawn instead |
| `PRIMER_MODE` | `lazy` | `lazy` or `eager` |
| `PRIMER_POOL_SIZE` | `3` | Max sessions in the pool |
| `PRIMER_DIR` | `~/.llm-primer` | State + log directory |
| `PRIMER_SESSION_PREFIX` | `primer` | Tmux window name prefix |
| `PRIMER_WARMUP_MSG` | `ready` | Message sent to trigger the session protocol |
| `PRIMER_WARMUP_MARKER` | `SESSION START` | String to watch for in pane output |
| `PRIMER_WARMUP_TIMEOUT` | `60` | Seconds to wait for warmup marker |
| `PRIMER_WATCH_DIR` | *(none)* | Config dir to watch for changes (triggers rewarm) |
| `PRIMER_WATCH_INTERVAL` | `5` | Seconds between config watch checks |
| `PRIMER_GC_VAULT` | *(none)* | Vault path for garbage collector (leave empty to disable) |
| `PRIMER_GC_INTERVAL` | `3600` | Seconds between GC runs |

**Recommended shell config (~/.zshrc):**

```bash
# llm-primer
export PRIMER_WATCH_DIR=~/path/to/your/vault/_config
export PRIMER_GC_VAULT=~/path/to/your/vault
alias cc='primer attach'
alias ch='primer haiku'
```

---

## Works with any LLM CLI

llm-primer doesn't care what's running in the tmux window. It sends keystrokes and watches for a string. Change `PRIMER_CLI` to use a different tool:

```bash
# Local Ollama model
export PRIMER_CLI="ollama run llama3"
export PRIMER_WARMUP_MARKER="ready"   # whatever your setup prints on init

# Aider with a local model
export PRIMER_CLI="aider --model ollama/llama3"
export PRIMER_WARMUP_MARKER="Aider v"

# Simon Willison's llm CLI
export PRIMER_CLI="llm chat"
export PRIMER_WARMUP_MARKER="Chatting with"

# Mixed pool: slots 0-1 are claude, slot 2 is haiku (the default)
# To make slot 0 Opus instead:
export PRIMER_SLOT_0_CLI="claude --model claude-opus-4-6"
```

The PostCompact hook is Claude Code-specific, but the warm-request signal works regardless of what CLI you're running. Any process can touch `~/.llm-primer/warm-request` to request a warm slot.

---

## The pool lifecycle

**Lazy mode:**
```
signal (PostCompact / primer warm / primer switch / CLAUDE.md instruction)
  → warm-request file created
  → primerd sees file → spawns slot → sends warmup msg → waits for SESSION START → warm
                                                                                      ↓
                                                                              user attaches
                                                                                      ↓
                                                                        slot goes cold until next signal
```

**Eager mode:**
```
start → pre-warm all slots → health loop re-warms stale slots
                                               ↓
                                       user attaches
                                               ↓
                               slot re-warms in background immediately
```

---

## Known limitations

- **Relies on undocumented behavior.** `/clear` re-injecting `CLAUDE.md` and re-running the session protocol isn't in any spec. If Anthropic changes this, warmth detection breaks silently.
- **bash + tmux only.** VSCode/Cursor integrated terminal users: this won't work there (tmux can't attach into a VSCode terminal pane). WSL2 works; native Windows doesn't. The iTerm2 and Obsidian setups described above work because they're real terminal emulators that support tmux.
- **macOS `stat` flags.** The config file watcher uses `stat -f` (macOS) with a Linux fallback. If it fails silently on your distro, open an issue.
- **Eager mode token cost.** Warm sessions ran the startup protocol. If you keep 3 eager sessions and never attach to 2 of them, you paid for 2 startups that did nothing. Lazy mode avoids this entirely.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: open an issue first for anything non-trivial, keep it bash + tmux, and include a manual test run in your PR description.

The most useful contributions right now:
- `PRIMER_WARMUP_MARKER` defaults for popular CLIs (Aider, Ollama, `llm`, Gemini CLI)
- Linux package manager recipes (AUR PKGBUILD, Nix flake)
- A `primer init` wizard that asks "what CLI?" and writes the right env vars

---

## Why tmux?

No new process model, no daemon talking to Claude's API, no special integration required per editor. It's just a shell and tmux — the same tools you're probably already using. The pool session lives completely outside any editor. Attach to it from iTerm, from Obsidian's terminal, from a remote SSH session — it doesn't matter.

## License

MIT
