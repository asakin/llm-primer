# Roadmap

## Shipping now — v0.5.0

- Pool of 3 slots with per-slot CLI configuration (alt slot)
- Plain-text config file (`~/.llm-primer/config`) with LLM-maintainable format
- Slot-targeted warm requests (`primer alt` warms its own slot on demand)
- Primer-aware warmup message — the LLM knows it's running in a pool
- `primer switch` — pre-warm a replacement and print instructions
- Garbage collector with vault-scoped policy file (`.primer-gc`)
- Self-test suite (41 assertions, no API calls)
- macOS launchd agent
- iTerm2 / Obsidian embedded terminal setup docs

## Next — v0.6.0

**LLM-assisted garbage collection.** Static rules handle the obvious 95%. The remaining 5% — "this file doesn't match any policy rule, but is it actually misplaced?" — deserves LLM judgment, not a heuristic.

Planned architecture:
- Ambiguous files go to an "LLM review queue"
- A background worker drains the queue by asking a **warm idle session** (configurable: `use_slot: alt`) to make the call
- The LLM already has your wiki's context loaded — no separate session needed
- Decisions applied as moves; moves logged to a GC audit trail

Why warm pool and not a dedicated LLM: cost (no redundant context reload), freshness (pool rotates on CLAUDE.md changes), non-interference (skips when no session is idle).

## Future

- **Go binary.** Single binary, no bash deps. Not a rewrite for rewrite's sake — only when the current script's limits are hurting (probably when Windows support or plugin ecosystem becomes a thing).
- **`primer init` wizard.** Interactive setup: "what CLI do you use? What's your vault path? Need an alt slot?" → writes `~/.llm-primer/config` correctly.
- **Linux packaging.** AUR PKGBUILD, Nix flake, maybe `.deb`. curl-pipe works but package managers are friendlier.
- **Warmup marker defaults for common CLIs.** Contribute a table of `(CLI, marker)` pairs; primerd auto-detects what you're running.
- **Release automation.** Tag push → auto-create GitHub release, compute sha256, open homebrew formula PR. Manual for now (see [../RELEASE.md](../RELEASE.md)).

## Known limitations

- **Undocumented dependency.** `/clear` re-injecting CLAUDE.md and re-running the session protocol isn't in any spec. If Anthropic changes it, warmth detection breaks silently. The selftest catches this in CI.
- **bash + tmux only.** VSCode/Cursor integrated terminal users: tmux can't attach into those panes. WSL2 works; native Windows doesn't.
- **Eager mode cost.** Warm sessions already ran the startup protocol. Keep 3 eager sessions and never use 2 → you paid for 2 startups that did nothing. Lazy mode avoids this.

## Not planned

- **VSCode/Cursor extension.** tmux can't attach into editor panes. Different tool, different problem.
- **Non-tmux backend.** The tmux assumption is core to how this works — replacing it means rewriting everything.
- **Hosted service.** llm-primer is a local daemon. No server component exists or is planned.
