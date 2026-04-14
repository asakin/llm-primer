# llm-primer

Two tools for anyone running an [LLM wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): a pool of pre-warmed sessions so you skip the startup protocol, and a garbage collector that catches drift before it compounds.

If your `CLAUDE.md` loads a session-start protocol — inbox state, spend, publishing signals, the kind of thing you see across Karpathy-inspired wikis — a cold session takes 30–60 seconds to initialize before you can type. llm-primer runs that in the background so you don't wait.

The GC is the other half. LLM wikis degrade from lack of tidiness that accumulates over time — files dropped in the wrong location, conventions that slip, frontmatter that disappears. Small, invisible individually. Collectively fatal to the AI's ability to navigate what you've built. `primer gc` walks your vault on a policy **your LLM maintains** and moves strays to your inbox. Smart work once, when conventions change. Not continuously.

Works with any LLM CLI that prints a recognizable marker when it's ready: Claude Code, Aider, Ollama, Gemini CLI, Simon Willison's `llm`.

---

## Install

```bash
brew tap asakin/llm-primer
brew install llm-primer
```

Or without Homebrew:
```bash
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/v0.5.0/install.sh | VERSION=v0.5.0 bash
```

Requires `tmux`. On macOS the installer offers to set up a launchd agent so `primerd` starts on login — say yes.

---

## First run

Generate a config file and edit it:

```bash
primerd config-template > ~/.llm-primer/config
$EDITOR ~/.llm-primer/config
```

Minimum config (for Claude Code):
```ini
PRIMER_CLI=claude
```

Start the pool and attach:
```bash
primerd start
primer attach
```

The first attach triggers a warm; you'll see the startup protocol run live once. After that, every attach is instant.

---

## Moving between slots

With a pool of N slots, you need a way to remember which is which. The commands:

| Command | What it does |
|---|---|
| `primer attach` | Attach to a warm slot (first non-alt) |
| `primer attach N` | Attach to a specific slot by number |
| `primer alt` | Attach to the alt slot (cheap/fast CLI) |
| `primer switch` | Pre-warm a replacement, tells you when to jump |
| `primer status` | Show pool state — which slots are warm, which CLI each runs |

Three ways to keep the commands in muscle memory:

**Aliases** — two-keystroke invocations in your shell:
```bash
alias cc='primer attach'    # main slot
alias ca='primer alt'       # alt slot (cheap/fast CLI)
alias cb='primer attach 1'  # backup slot
```

**Per-slot colors** — `PRIMER_SLOT_COLORS` tints each slot's pane so you can tell tabs apart at a glance:
```ini
PRIMER_SLOT_COLORS=#0d1b2a,#1b263b,#0e2a1a
```

**Terminal profile** — set `primer attach` as the shell command for your default iTerm / Ghostty / Warp profile. Every new tab opens into a warm session.

---

## Always-warm setup (for heavy users)

If you live in your LLM CLI and the startup cost is always worth paying up front, run eager mode. The pool warms every slot at daemon boot and keeps them fresh via the file watcher:

```ini
# ~/.llm-primer/config
PRIMER_MODE=eager
PRIMER_POOL_SIZE=3
PRIMER_WATCH_DIR=/path/to/your/wiki/config
```

Pair it with the launchd agent (macOS) and every login brings up a fully-warmed pool. Not free — eager mode pays the session-start cost N times on each daemon restart, whether you end up using the slots or not. Lazy is the right default unless your attach-to-done loop is shorter than a typical workday.

## The other half: a garbage collector your LLM maintains

Untidiness in an LLM wiki comes from two directions. AI output in the wrong place, you fix with better instructions. Files *you* drop in the wrong place — late-night Obsidian captures, mis-saved downloads, notes dashed off wherever the cursor happened to be — those no instruction catches. They accumulate.

`primer gc` is the worker that closes that loop. It scans your vault for `.md` files outside their allowed locations and moves them to your inbox so they flow through normal filing.

The non-obvious part: rules live in a plain `.primer-gc` file at your vault root, and **your LLM maintains that file**.

Example — a real `.primer-gc` for an [llm-context-base](https://github.com/asakin/llm-context-base) vault:

```ini
ALLOWED_DIRS=0-Ideas,1-Projects,2-Knowledge,3-Journal,4-Private,5-Publishing,docs
ALLOWED_ROOT_FILES=README.md,PHILOSOPHY.md,CLAUDE.md,CONTRIBUTING.md
INBOX_DIR=_inbox
LINT_SKIP_DIRS=_inbox,3-Journal
FILENAME_REGEX=^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$
```

And the `CLAUDE.md` snippet that tells Claude to keep it current:

```markdown
The GC policy for this vault is at `.primer-gc`. When we add a new top-level
content directory, update ALLOWED_DIRS. When we introduce a new root-level
convention file, update ALLOWED_ROOT_FILES. When the filename convention
changes, update FILENAME_REGEX. Never run `primer gc --auto` without approval.
```

Now when you tell Claude "let's add a `6-Recipes/` dir for cooking content," it updates the policy in the same conversation. The GC learns without you editing anything. The LLM is smart *periodically* — when conventions change — and its intelligence is frozen into a file a shell script can execute cheaply every hour.

More examples (PARA, Zettelkasten) and full field reference: [garbage-collector.md](docs/garbage-collector.md).

## What else it can do

| | |
|---|---|
| [**Alt slot**](docs/alt-slot.md) | A second slot running a different CLI — Haiku for quick questions, Ollama for offline work, a totally different tool. Attach with `primer alt`. |
| [**Context switching**](docs/context-switching.md) | When your context gets heavy, `primer switch` pre-warms a replacement and tells you when to jump. The default warmup message teaches the LLM to offer this proactively. |
| [**Self-test**](docs/self-test.md) | `primer selftest --fast` runs the full suite without touching your real pool or making any API calls. |
| [**Full configuration**](docs/configuration.md) | Every environment variable, every config field, shell/terminal setup. |
| [**Troubleshooting**](docs/troubleshooting.md) | "Pool not found", warmup timeouts, config ignored, alias collisions. |
| [**Roadmap**](docs/roadmap.md) | What's coming (LLM-assisted GC), what's not (Go rewrite, yet), what's stable. |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: open an issue for anything non-trivial, run `primer selftest` before submitting, include the output in your PR.

## License

MIT
