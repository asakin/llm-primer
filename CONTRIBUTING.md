# Contributing to llm-primer

Thanks for wanting to help. This is a small project — keep it simple.

## What's useful right now

- **Warmup marker defaults** for popular CLIs. If you added llm-primer support for Aider, Ollama, Gemini CLI, or something else, a PR adding the right `PRIMER_WARMUP_MARKER` default and a README example is welcome.
- **Linux packaging**: AUR PKGBUILD, Nix flake, `.deb` recipe. curl-pipe works but package managers are friendlier.
- **`primer init` wizard**: interactive setup that asks "what CLI are you using?" and writes the right env vars to your shell config.
- **Bug fixes**: especially anything that breaks on Linux or causes silent failures.

## What's not useful right now

- Go rewrite — the shell script is intentionally simple. A Go binary is planned for v1.0 but not now.
- VSCode/Cursor extension — tmux can't attach into editor terminal panes. Different problem, different tool.
- Non-tmux session management — the tmux assumption is core to how this works.

## How to contribute

1. Open an issue first for anything non-trivial. Describe the problem, not the solution. This saves time if the direction isn't right.
2. Fork, branch (`feat/your-thing` or `fix/your-thing`), make the change.
3. Test it manually — see the Testing section below.
4. Open a PR with what you changed and a copy of your manual test output.

## Dev setup

```bash
git clone https://github.com/asakin/llm-primer
cd llm-primer

# Test without installing — run scripts directly from the repo
export PATH="$PWD/bin:$PATH"
export PRIMER_DIR="/tmp/primer-test"   # keep test state separate from your real install
```

No build step. No dependencies beyond bash and tmux.

## Testing

There's no automated test suite yet. Manual test plan:

```bash
# Clean state
export PRIMER_DIR=/tmp/primer-test
rm -rf /tmp/primer-test

# Start in lazy mode
primerd start

# Check status — all slots cold
primer status

# Warm a slot
primer warm
sleep 10   # wait for warmup (depends on your LLM CLI startup time)
primer status   # slot should show warm ✓

# Attach
primer attach   # should connect to the warm slot

# In another terminal: check haiku slot
primer status   # slot 2 should show [haiku]
primer haiku    # attach to haiku slot (may need to warm first)

# Test switch
primer switch   # should print instructions and touch warm-request

# GC test
primer gc /path/to/a/vault             # dry run
primer gc /path/to/a/vault --lint      # lint only

# Stop
primerd stop
```

Include the output of `primer status` before and after your change in your PR.

## Code style

- bash, `set -euo pipefail` at the top
- Functions named `verb_noun` (snake_case)
- `local` all variables inside functions
- No external dependencies beyond tmux, bash builtins, and standard POSIX tools (`find`, `stat`, `grep`, etc.)
- Curly braces next to the closing paren — `(){` not `()\n{`
- Prefer `[[ ]]` over `[ ]`

## Adding a new LLM CLI

The relevant variables are `PRIMER_WARMUP_MARKER` (the string to watch for in stdout when the session is ready) and `PRIMER_WARMUP_MSG` (what to send to trigger initialization).

For a new CLI, find:
1. What string reliably appears in stdout once the session is fully initialized
2. Whether `/clear` (or equivalent) + a message re-triggers initialization, or if you need kill+respawn

Document it in the README config examples table and open a PR.
