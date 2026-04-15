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

That's the whole surface.

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

## What's coming

Weekly releases. Each one adds a feature and ships with a post about what we built. Open an issue if you want something specific.

## License

MIT
