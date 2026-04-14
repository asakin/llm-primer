# llm-primer

Pre-warmed LLM CLI sessions in tmux. Attach instantly, skip the startup protocol.

Built because a loaded-up Claude Code session takes 30–60 seconds to initialize before you can type: it reads `CLAUDE.md`, runs the session-start protocol, checks inbox state, spend, publishing signals. Every session. llm-primer runs that in the background so you don't wait.

Works with any LLM CLI that prints something recognizable when it's ready: Claude Code, Aider, Ollama, Gemini CLI, Simon Willison's `llm`.

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

## Shortcuts worth aliasing

```bash
alias cc='primer attach'    # warm session in two keystrokes
alias ca='primer alt'       # jump to the alt slot (cheap/fast model)
```

Or configure iTerm2 / your terminal profile to run `primer attach` as the shell command. Every new tab opens into a warm session.

---

## The other half: a garbage collector your LLM maintains

Drift in an LLM wiki comes from two directions. AI output in the wrong place, you fix with better instructions. Files *you* drop in the wrong place — late-night Obsidian captures, mis-saved downloads — those no instruction catches.

`primer gc` is the worker that closes that loop. It scans your vault for `.md` files outside their allowed locations and moves them to your inbox so they flow through normal filing.

The non-obvious part: rules live in a plain `.primer-gc` file at your vault root, and **your LLM maintains that file**. One line in your `CLAUDE.md`:

```markdown
The GC policy for this vault is at `.primer-gc`. When we add a new top-level
content directory, update ALLOWED_DIRS. When the filename convention changes,
update FILENAME_REGEX.
```

Now when you tell your LLM "let's add a `6-Recipes/` dir for cooking content," it updates the policy in the same conversation. The GC learns without you editing anything. The LLM is smart *periodically* — when conventions change — and its intelligence is frozen into a file a shell script can execute cheaply every hour.

Full docs: [garbage-collector.md](docs/garbage-collector.md).

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
