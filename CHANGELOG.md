# Changelog

## v0.2.3 — 2026-04-19

### Added

- `PRIMER_CWD` config variable (default `$HOME`). Hold-mode tmux sessions
  open with this as their initial working directory instead of inheriting
  whatever directory `primer start` was run from. Set it to your vault root
  or project root so `cd` is never needed inside the session.

- `primerd run-foreground` subcommand. Runs the daemon in the foreground
  instead of forking. This is the form launchd / systemd want — they track
  the running process directly and `KeepAlive` can actually keep the daemon
  alive. Not for interactive use (it blocks). `primerd start` still forks
  and disowns as before; unchanged for everyday use.

## v0.2.2 — 2026-04-19

### Fixed

- `primer-log-filter` was producing thousands of empty/whitespace-only lines
  when capturing Claude Code's pane. Claude's Ink/React renderer redraws the
  whole screen with cursor-positioning sequences (not carriage returns), so
  after ANSI stripping the stream was dominated by blank lines and exact
  duplicates. The filter now drops blank lines and collapses consecutive
  identical lines. Logs are meaningfully readable instead of mostly-empty.

## v0.2.1 — 2026-04-19

### Fixed

- `primer attach <name>`, `primer status`, and `primer switch <name>` now
  work in any shell without requiring `PRIMER_SLOTS` to be exported in the
  environment or defined in `~/.llm-primer/config`. The CLI discovers live
  hold-mode slots directly from tmux (`primer-<name>` sessions), so you can
  open a fresh terminal, run `primer attach §sakinos`, and it just works as
  long as the daemon is running.

## v0.2.0 — 2026-04-19

Additive release. All new features are opt-in; default behavior is unchanged
for existing users.

### Added

- **Hold mode** (`PRIMER_HOLD=1`). Skip the warmup-message + marker-wait
  protocol. Each slot holds a live Claude process alive under a respawn loop,
  so if Claude exits the daemon brings it back within a couple of seconds.
  Use this when you want llm-primer to be the session holder and you drive
  Claude yourself.

- **Named slots** (`PRIMER_SLOTS`). Pipe-separated list of commands, one per
  slot. Slot names are derived from each command's `--agent` flag (or
  `Claude` for bare `claude`). Each slot runs in its own tmux session
  (`primer-<slotname>`), so multiple UI attachments can live side by side
  without fighting over the active window.

  ```ini
  PRIMER_SLOTS=claude|claude --agent engineer|claude --agent writer
  ```

  `primer attach <name>` attaches to a specific slot. `primer switch <name>`
  kills and respawns it, for when `/clear` isn't enough.

- **Log filter** (`PRIMER_LOG_FILTER`). Optional pane-output piping via
  `tmux pipe-pane` into `~/.llm-primer/logs/<slot>.log`. Off by default.
  When turned on, primerd injects a one-time prompt into each session telling
  Claude to announce `DEBUG MODE` (and the log path) to the user in its first
  response — logging is never silent.

  A `primer-log-filter` command ships with llm-primer. It strips ANSI and
  spinner frames so the log is plaintext-friendly. Any stdin→stdout command
  can be substituted.

- `primer logs <slot>` — tail a specific slot's log file.

### Unchanged

- Default (warm) mode with numbered slots and the `SESSION START` marker
  works exactly as in v0.1.x. No config migration needed.

## v0.1.1

Document marker-detection caveat; installer version bump.

## v0.1.0

Initial release.
