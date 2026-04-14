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

## What else it can do

| | |
|---|---|
| [**Alt slot**](docs/alt-slot.md) | A second slot running a different CLI — Haiku for quick questions, Ollama for offline work, a totally different tool. Attach with `primer alt`. |
| [**Context switching**](docs/context-switching.md) | When your context gets heavy, `primer switch` pre-warms a replacement and tells you when to jump. The default warmup message teaches the LLM to offer this proactively. |
| [**Garbage collector**](docs/garbage-collector.md) | `primer gc` scans your vault for `.md` files that drifted into the wrong place and moves them to your inbox. Rules driven by a `.primer-gc` policy file your LLM can maintain. |
| [**Self-test**](docs/self-test.md) | `primer selftest --fast` runs the full suite without touching your real pool or making any API calls. |
| [**Full configuration**](docs/configuration.md) | Every environment variable, every config field, shell/terminal setup. |
| [**Troubleshooting**](docs/troubleshooting.md) | "Pool not found", warmup timeouts, config ignored, alias collisions. |
| [**Roadmap**](docs/roadmap.md) | What's coming (LLM-assisted GC), what's not (Go rewrite, yet), what's stable. |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: open an issue for anything non-trivial, run `primer selftest` before submitting, include the output in your PR.

## License

MIT
