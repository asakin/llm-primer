# llm-primer

No more waiting for Claude Code to boot.

llm-primer keeps a pool of pre-warmed Claude Code sessions running in the background via tmux. When you need a session, you get one instantly — fully initialized, session protocol already run, ready to type.

## How it works

```
primerd start
```

This spawns N tmux windows, launches `claude` in each, sends a warmup message, and waits for `SESSION START` to appear in the output. That's the signal that the session protocol has completed and the session is ready.

When you need a session:

```
primer attach
```

That's it. You're in. The slot you just took gets re-warmed automatically in the background.

If you change your config (`CLAUDE.md`, `_config/`), primerd detects the change and sends `/clear` to all slots, re-running the session protocol with fresh context.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

Or with Homebrew:

```bash
brew install asakin/llm-primer/llm-primer
```

**Requires:** `tmux`, `claude` (Claude Code CLI)

## Usage

```
primerd start            Start the pool daemon
primerd stop             Stop the daemon
primerd status           Show daemon status

primer attach            Attach to a warm session (auto-picks)
primer attach 1          Attach to slot 1 specifically
primer status            Show pool health
primer logs              Tail the daemon log
```

## Configuration

All config via environment variables. Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Number of warm sessions to keep ready (default: 2)
export PRIMER_POOL_SIZE=3

# Watch a directory for config changes → triggers rewarm
export PRIMER_WATCH_DIR=~/projects/my-vault/_config

# Shortcut: instant claude
alias cc='primer attach'
```

| Variable | Default | Description |
|---|---|---|
| `PRIMER_POOL_SIZE` | `2` | Sessions in the pool |
| `PRIMER_DIR` | `~/.llm-primer` | State + log directory |
| `PRIMER_SESSION_PREFIX` | `primer` | Tmux window name prefix |
| `PRIMER_WARMUP_MSG` | `ready` | Message sent to trigger the session protocol |
| `PRIMER_WARMUP_TIMEOUT` | `60` | Seconds to wait for `SESSION START` |
| `PRIMER_WATCH_DIR` | *(none)* | Config dir to watch for changes |
| `PRIMER_WATCH_INTERVAL` | `5` | Seconds between watch checks |

## How warmth detection works

llm-primer watches for `SESSION START` in the pane output. If your session protocol outputs that string (llm-context-base does by default), primerd knows the session is ready. If your setup doesn't print that, set `PRIMER_WARMUP_MSG` to whatever message kicks off the work you want pre-done, and check the output yourself.

## The pool lifecycle

```
spawn → send warmup msg → wait for SESSION START → warm
                                                      ↓
                                              user attaches
                                                      ↓
                                          slot re-warms in background
```

On config change (file watcher):
```
detect change → send /clear to all slots → send warmup msg → re-warm
```

## Why tmux?

tmux is already how people run persistent terminal sessions. `primer attach` is just `tmux attach` with slot selection on top. No new process model, no sidecar, no daemon talking to Claude's API — just shell and tmux.

## Homebrew

```bash
brew tap asakin/llm-primer
brew install llm-primer
```

## License

MIT
