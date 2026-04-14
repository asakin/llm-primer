# Self-test

Run the built-in test suite to verify your install works:

```bash
primer selftest           # full suite, including pool lifecycle with a mock CLI
primer selftest --fast    # skip tmux-dependent tests (takes < 1s)
primer selftest --verbose # print every check as it runs
```

No real pool is touched. No LLM API calls. Everything runs in a temp directory with a mock CLI.

## What it covers

- **Config file parsing** — plain KEY=value, env overrides file, comments and blanks tolerated
- **Alt slot resolution** — `PRIMER_CLI` default, `PRIMER_ALT_CLI` targeted, `PRIMER_SLOT_N_CLI` override, uniform pool when alt empty
- **`primer switch` and `primer warm`** — create the right signal files
- **Garbage collector** — stray detection, auto-move, lint flags for missing frontmatter, duplicate slug detection, policy file overrides, custom inbox destination
- **Help outputs** — each binary's help text mentions the major commands/flags
- **Pool lifecycle** — daemon start, slot warming to the `warm` state (verified via state file + status output), daemon stop

A failed test prints a diff of expected vs. actual. Exit 0 on green, 1 on any failure.

## When to run it

- After every install or `brew upgrade`
- When contributing a change (required, see [CONTRIBUTING.md](../CONTRIBUTING.md))
- When anything behaves unexpectedly — the selftest catches most regressions quickly
