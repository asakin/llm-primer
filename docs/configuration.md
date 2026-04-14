# Configuration reference

Three layers, priority order:

1. **Environment variables** (`PRIMER_*`) — always win
2. **Config file** (`~/.llm-primer/config`) — plain `KEY=value`, one per line
3. **Built-in defaults**

Generate a starter config:
```bash
primerd config-template > ~/.llm-primer/config
```

## Pool

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_CLI` | `claude` | CLI command for all slots unless overridden |
| `PRIMER_POOL_SIZE` | `3` | Number of pool slots |
| `PRIMER_MODE` | `lazy` | `lazy` (warm on demand) or `eager` (always-on) |
| `PRIMER_SESSION_PREFIX` | `primer` | tmux window/session name prefix |

## Alt slot

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_ALT_CLI` | *(empty)* | CLI for the alt slot. Empty = uniform pool. |
| `PRIMER_ALT_SLOT` | last slot | Which slot number is the alt |
| `PRIMER_ALT_WARMUP_MSG` | *(falls back to PRIMER_WARMUP_MSG)* | Preamble only the alt slot sees |
| `PRIMER_SLOT_{N}_CLI` | *(none)* | Per-slot override, wins over `PRIMER_ALT_CLI` |

## Warmup behavior

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_WARMUP_MSG` | primer-aware preamble | Message sent after launching the CLI |
| `PRIMER_WARMUP_MARKER` | `SESSION START` | String to watch for that signals "warm" |
| `PRIMER_WARMUP_TIMEOUT` | `180` | Seconds to wait before giving up. Bump if your session start reads many files; lower for stock CLIs. |
| `PRIMER_RESET_CMD` | `/clear` | Soft-reset command. `""` = kill+respawn. |

## File watcher (auto-rewarm)

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_WATCH_DIR` | *(empty)* | Dir to watch — changes trigger rewarm of warm slots |
| `PRIMER_WATCH_INTERVAL` | `5` | Poll interval in seconds |

## Garbage collector

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_GC_VAULT` | *(empty)* | Vault path. Set to enable the GC cron in primerd. |
| `PRIMER_GC_INTERVAL` | `21600` | Seconds between GC runs (6 hours). Lower = more aggressive. |

## Paths

| Variable | Default | What it does |
|---|---|---|
| `PRIMER_DIR` | `~/.llm-primer` | State + log directory |
| `PRIMER_CONFIG` | `~/.llm-primer/config` | Config file path |

---

## The config file

`~/.llm-primer/config` is plain text — one `KEY=value` per line, comments with `#`. No bash syntax, no quoting.

Example:
```ini
PRIMER_CLI=claude
PRIMER_POOL_SIZE=3
PRIMER_MODE=lazy
PRIMER_ALT_CLI=claude --model claude-haiku-4-5-20251001
PRIMER_WATCH_DIR=/Users/me/vault/_config
PRIMER_GC_VAULT=/Users/me/vault
```

Your LLM assistant can maintain this file on your behalf — add a CLAUDE.md snippet pointing at it and ask it to update settings when they change.

## The GC policy file

Separate file at your vault root: `<vault>/.primer-gc`. Drives the garbage collector's rules. Same format. See [garbage-collector.md](garbage-collector.md) for fields.

## Shell aliases

```bash
alias cc='primer attach'    # warm session, two keystrokes
alias ca='primer alt'       # alt slot
alias cs='primer status'    # pool health
```

## iTerm2 profile

Preferences → Profiles → [your profile] → General → Command → select **Command** → enter `/opt/homebrew/bin/primer attach`.

Every new tab opens into a warm session.

## Obsidian embedded terminal

Install the ObsidianTerminal plugin. Settings → Community Plugins → Obsidian Terminal → Custom Shell Command → `primer attach`.

## macOS launchd agent

The installer offers to set this up. To do it manually after installation:
```bash
LAUNCHD=yes bash install.sh
```

To unload:
```bash
launchctl unload ~/Library/LaunchAgents/io.github.asakin.primerd.plist
```
