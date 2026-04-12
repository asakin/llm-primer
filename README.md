# llm-primer

No more waiting for your LLM CLI to boot.

llm-primer keeps pre-warmed sessions ready in tmux — Claude Code, Aider, a local Ollama model, anything with a startup protocol. When you need a session, you get one instantly — fully initialized, context already loaded, ready to type.

## How it works

```bash
primerd start    # start the daemon
primer attach    # get a warm session instantly
```

The daemon watches for `SESSION START` in the tmux pane output. When it appears, the session is warm. When you attach, the slot re-warms in the background.

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

This is the AI-native flow: Claude decides its context is getting long → signals primerd → primerd warms its replacement → by the time you start a fresh session, it's already ready.

**Or add to CLAUDE.md** to let Claude decide contextually:

```markdown
When your context is getting long, run: touch ~/.llm-primer/warm-request
```

**Or trigger manually:**

```bash
primer warm    # request a warm session now
```

### Eager — always-on pool

Always keeps `PRIMER_POOL_SIZE` sessions warm. Costs tokens for idle sessions, but a warm session is always available even before any signal.

```bash
export PRIMER_MODE=eager
primerd start
```

## Install

**macOS:**
```bash
brew tap asakin/llm-primer && brew install llm-primer
```

**Linux (and macOS if you prefer):**
```bash
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

**Requires:** `tmux` and whatever CLI you're using (`claude`, `aider`, `ollama`, etc.)

## Usage

```
primerd start            Start the daemon
primerd stop             Stop the daemon
primerd status           Show daemon and pool status

primer attach            Attach to a warm session (auto-picks first warm slot)
primer attach 1          Attach to slot 1 specifically
primer warm              Signal primerd to warm a session now
primer status            Show pool health
primer logs              Tail the daemon log
```

Shorthand: `primer a` = attach, `primer w` = warm.

```bash
alias cc='primer attach'    # two keystrokes to a warm session
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `PRIMER_CLI` | `claude` | CLI command to launch (e.g. `aider`, `ollama run llama3`, `llm`) |
| `PRIMER_RESET_CMD` | `/clear` | Command to reset session context. Set to `""` to kill+respawn instead (for CLIs with no soft-reset) |
| `PRIMER_MODE` | `lazy` | `lazy` or `eager` |
| `PRIMER_POOL_SIZE` | `2` | Max sessions in the pool |
| `PRIMER_DIR` | `~/.llm-primer` | State + log directory |
| `PRIMER_SESSION_PREFIX` | `primer` | Tmux window name prefix |
| `PRIMER_WARMUP_MSG` | `ready` | Message sent to trigger the session protocol |
| `PRIMER_WARMUP_MARKER` | `SESSION START` | String to watch for in pane output |
| `PRIMER_WARMUP_TIMEOUT` | `60` | Seconds to wait for warmup marker |
| `PRIMER_WATCH_DIR` | *(none)* | Config dir to watch for changes (triggers rewarm) |
| `PRIMER_WATCH_INTERVAL` | `5` | Seconds between config watch checks |

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
```

The PostCompact hook is Claude Code-specific, but the warm-request signal works the same way regardless of what CLI you're running. Any process can touch `~/.llm-primer/warm-request` to request a warm slot.

## The pool lifecycle

**Lazy mode:**
```
signal (PostCompact / primer warm / CLAUDE.md) → warm-request file created
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

## Known limitations

- **Relies on undocumented behavior.** `/clear` re-injecting `CLAUDE.md` and re-running the session protocol isn't in any spec. If Anthropic changes this, warmth detection breaks silently.
- **bash + tmux only.** VSCode/Cursor integrated terminal users: this won't work there. WSL2 works; native Windows doesn't.
- **macOS `stat` flags.** The config file watcher uses `stat -f` (macOS). Linux support needs `stat -c`. PRs welcome.
- **Eager mode token cost.** Warm sessions ran the startup protocol. If you keep 3 eager sessions and never attach to 2 of them, you paid for 2 startups that did nothing. Lazy mode avoids this entirely.

## Why tmux?

No new process model, no daemon talking to Claude's API, no special integration required per editor. It's just a shell and tmux — the same tools you're probably already using.

## License

MIT
