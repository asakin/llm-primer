# llm-primer

A pre-warmed pool of Claude Code sessions. Skip the startup wait.

Made by AI, mostly. I described the idea. Claude built it.

## Why

A Claude Code session that reads a real `CLAUDE.md` and runs a startup protocol takes 30 to 60 seconds before you can type. Fine once. Friction when you switch contexts, reopen after a break, or want to ask one quick thing.

llm-primer keeps a couple of sessions warm in the background. When you want one, it's already past the protocol.

## Install

```bash
brew tap asakin/llm-primer
brew install llm-primer
```

Requires `tmux`.

## Use

```bash
primer start      # start the daemon (lazy pool of 2)
primer            # attach to a warm session
primer switch     # pre-warm a replacement when your context fills up
primer status     # see which slots are warm
primer stop       # stop the daemon
```

That's the default surface. Two optional modes extend it: **hold mode** and **log filter** (both opt-in, off by default, additive since v0.2.0).

## How it works

`primerd` keeps a tmux session with N windows. Each window runs your CLI (default `claude`) and receives a warmup message that asks it to run its startup routine and print a marker when ready. When the pane output contains that marker (default `SESSION START`), the slot is marked warm.

`primer` attaches you to the first warm slot. A file watcher on an optional config dir rewarms slots when your `CLAUDE.md` changes.

Warmth is signaled by the CLI printing the marker, so detection is only as reliable as the CLI following the warmup prompt. If a slot stalls, `primer logs` will show the timeout.

## Configuration

Environment variables, or `~/.llm-primer/config` with `KEY=value` lines:

```ini
PRIMER_CLI=claude
PRIMER_POOL_SIZE=2
PRIMER_WARMUP_MARKER=SESSION START
PRIMER_WATCH_DIR=/path/to/your/vault/_config
```

The default warmup message already asks Claude to print `SESSION START` when its startup routine finishes, so this works on a stock Claude Code install. Override `PRIMER_WARMUP_MSG` or `PRIMER_WARMUP_MARKER` if your CLI prints something different or you want your own protocol.

## Hold mode (v0.2)

Some setups don't need the warmup-and-detect dance. They just want N persistent Claude sessions that stay alive in the background, each pinned to a specific agent or flag set, attachable by name.

Hold mode does exactly that:

```ini
PRIMER_HOLD=1
PRIMER_SLOTS=claude|claude --agent engineer|claude --agent writer
```

Every pipe-separated entry in `PRIMER_SLOTS` becomes its own tmux session, named by the `--agent` value (or `Claude` for a bare `claude`). Each session runs under a respawn loop so if Claude exits, it comes back up within a couple of seconds.

```bash
primer              # attach to the first slot
primer attach writer # attach to a specific named slot
primer switch writer # kill + respawn that slot with a fresh process
primer status       # list slots and whether their sessions are alive
```

No warmup message is sent. No marker is expected. Use this when you want llm-primer to be the session holder and you want to drive Claude yourself.

## Log filter (v0.2)

Optional. Off by default. When set, pipes each pane's output through a filter command into `~/.llm-primer/logs/<slot>.log`, so you have a tailable record of your sessions.

```ini
PRIMER_LOG_FILTER=primer-log-filter
```

`primer-log-filter` ships with llm-primer — it strips ANSI escapes and spinner frames so the log file is plaintext-friendly. You can substitute any command that reads stdin and writes filtered stdout.

**This is a privacy-sensitive feature, so it behaves loudly when enabled:**

- It is off by default. You must explicitly set `PRIMER_LOG_FILTER` to turn it on.
- When on, primerd sends a one-time prompt into each session at startup telling Claude to announce to the user that `DEBUG MODE` is active and that output is being logged to a specific file. Claude will say so in its first response.
- The log path is included in the announcement so you (or anyone sharing the machine) can see exactly where logs go.

Don't use this to log somebody else's work without telling them. That's what the announcement prompt is there to prevent — the session tells the user it's logged before anything useful happens.

Tail a specific slot's log: `primer logs <slot>`.

## What's coming

Weekly releases. Each one adds a feature and ships with a post about what we built. Open an issue if you want something specific.

## License

MIT
