# llm-primer Manual Test Plan

Run through this before any public release. Each section is independent — you can run them in any order, but Prerequisites must pass first.

---

## Prerequisites

- [ ] tmux installed (`tmux -V` prints a version)
- [ ] `claude` in PATH (`claude --version` works)
- [ ] `primer` and `primerd` both in PATH (`which primer`, `which primerd`)
- [ ] No primerd already running (`primer status` shows "daemon: not running")
- [ ] No leftover pool session (`tmux ls` does not show `primer-pool`)

Clean up before starting:

```bash
primerd stop 2>/dev/null; tmux kill-session -t primer-pool 2>/dev/null; rm -rf ~/.llm-primer
```

---

## 1. Install

### 1a. curl-pipe installer

```bash
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

- [ ] Prints "→ Downloading llm-primer..."
- [ ] Prints "→ Installed: /usr/local/bin/primer" and "primerd"
- [ ] Prints the quick-start block at the end
- [ ] `primer help` runs without error
- [ ] `primerd help` runs without error

### 1b. Homebrew (if formula is wired to a release tag)

```bash
brew tap asakin/llm-primer && brew install llm-primer
```

- [ ] Installs without error
- [ ] `primer help` and `primerd help` work

---

## 2. Daemon lifecycle

```bash
primerd start
```

- [ ] Prints "primerd started in lazy mode (pid XXXXX)"
- [ ] `primerd status` shows "primerd: running"

```bash
primerd stop
```

- [ ] Prints "primerd stopped"
- [ ] `primerd status` shows "primerd: not running"

```bash
primerd start
primerd start   # second start
```

- [ ] Second start prints "primerd is already running (pid ...)" and exits cleanly

---

## 3. Lazy mode — warm on demand

```bash
primerd start   # lazy is default
primer status
```

- [ ] Pool slots show "cold" — nothing warming yet, zero background work

```bash
primer warm
sleep 5
primer status
```

- [ ] One slot transitions from cold → warming → warm ✓
- [ ] `primerd logs` shows "Warm request received" and "Slot 0 is warm ✓"

---

## 4. Attach — outside tmux

Run this from a plain terminal (not inside a tmux session):

```bash
primer attach
```

- [ ] Drops you into the tmux session at the warm window
- [ ] Claude Code is running and has already printed the session summary (SESSION START block visible)
- [ ] You can type a message and Claude responds normally
- [ ] Detach with `Ctrl+B D` — you're back at your original terminal

---

## 5. Attach — inside tmux

Open a fresh tmux session of your own:

```bash
tmux new-session -s mywork
```

Inside that session:

```bash
primer attach
```

- [ ] Switches you to the primer-pool session (not your mywork session)
- [ ] Claude is running and warm in the primer window
- [ ] `Ctrl+B D` detaches back to primer-pool; `tmux switch-client -t mywork` to return to your session

---

## 6. Slot replacement after attach

After attaching (test 4 or 5), detach and check:

```bash
primer status
```

- [ ] The slot you just used is rewarming or already warm again (eager replacement)
- [ ] Logs show a second warm cycle starting

---

## 7. Eager mode

```bash
primerd stop
PRIMER_MODE=eager primerd start
sleep 90   # wait for both slots to warm
primer status
```

- [ ] Both slots show "warm ✓" without any `primer warm` needed
- [ ] Logs show "Eager mode: pre-warming 2 slots"

---

## 8. Config file watcher

```bash
primerd stop
export PRIMER_WATCH_DIR=~/.llm-primer   # watch something that exists
PRIMER_MODE=eager primerd start
sleep 90   # wait for warm
touch ~/.llm-primer/test-change.md
sleep 10
```

- [ ] Logs show "Config change detected" and "rewarming all warm slots"
- [ ] Slots go through rewarming → warm cycle

Clean up:

```bash
rm ~/.llm-primer/test-change.md
```

---

## 9. Reset: kill-and-respawn fallback

For CLIs with no soft-reset command. Uses Ctrl+C + respawn instead of `/clear`.

```bash
primerd stop
PRIMER_RESET_CMD="" PRIMER_MODE=eager primerd start
sleep 90
primer status   # confirm warm
# Now trigger a rewarm
touch ~/.llm-primer/warm-request
sleep 90
```

- [ ] Logs show "no PRIMER_RESET_CMD set, using kill+respawn"
- [ ] Slot goes stale, gets killed, CLI relaunches, reaches warm again

---

## 10. Non-Claude CLI (smoke test)

Substitute any CLI that prints something on start. `cat` works as a trivial stand-in:

```bash
primerd stop
PRIMER_CLI="bash" PRIMER_WARMUP_MSG="echo SESSION_START_CUSTOM" \
  PRIMER_WARMUP_MARKER="SESSION_START_CUSTOM" \
  PRIMER_MODE=eager primerd start
sleep 15
primer status
```

- [ ] Slot reaches warm using the custom marker
- [ ] `primer attach` drops into the bash window

---

## 11. Error handling

**No warm slots:**

```bash
primerd stop
primerd start   # lazy, nothing warm
primer attach
```

- [ ] Prints "⚠ No warm slots available. Attaching to slot 0 (may not be fully ready)."
- [ ] Still attaches (slot 0 may be cold or mid-warm)

**Daemon not running:**

```bash
primerd stop
primer status
```

- [ ] Shows "daemon: not running (start with 'primerd start')"
- [ ] Shows pool status if tmux session still exists, or "no tmux session found"

**Missing tmux:**

Rename tmux temporarily, or test on a machine without it. Expect:

- [ ] `primerd start` exits with `ERROR: 'tmux' is required but not installed`

---

## 12. `primer logs`

```bash
primer logs
```

- [ ] Tails `~/.llm-primer/primerd.log` in real time
- [ ] New log lines appear as the daemon does work
- [ ] `Ctrl+C` exits cleanly

---

## Post-test cleanup

```bash
primerd stop
tmux kill-session -t primer-pool 2>/dev/null
rm -rf ~/.llm-primer
```

---

## Known limitations to document (not test failures)

- **WSL2:** tmux works. Native Windows: does not work.
- **VSCode integrated terminal:** tmux attach opens in a new window, not inline. Expected.
- **Eager mode token cost:** both warm slots ran a full startup protocol. If you never use one, you paid for a cold start that did nothing.
- **Stale context:** sessions sitting warm for hours may have read files that changed since warmup. Same tradeoff as having two Claude windows open.
