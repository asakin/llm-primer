# Garbage collector

`primer-gc` finds `.md` files that drifted into the wrong place in your vault and moves them to your inbox.

Drift in an LLM wiki comes from two directions: AI output (fix with better instructions) and casual human drops (fix with a background worker). This is that worker.

## Run it

```bash
primer gc ~/path/to/vault           # dry run
primer gc ~/path/to/vault --auto    # move strays to inbox
primer gc ~/path/to/vault --lint    # flag frontmatter/slug issues, no moves
```

## The policy file

Rules are driven by a `.primer-gc` file at your vault root. Without one, built-in defaults kick in (llm-context-base-shaped). Override what you need:

```ini
# <vault>/.primer-gc

# Top-level directories where .md files are allowed
ALLOWED_DIRS=notes,projects,archive

# Root-level files allowed as-is
ALLOWED_ROOT_FILES=README.md,INDEX.md

# Where strays get moved (relative to vault root)
INBOX_DIR=incoming

# Regex filenames must match (empty to skip)
FILENAME_REGEX=

# Directories where frontmatter lint is skipped
LINT_SKIP_DIRS=incoming,scratch

# Directories to skip entirely during scan
SCAN_EXCLUDE_DIRS=node_modules,_tools

# File extensions always allowed anywhere
ASSET_EXTENSIONS=png,jpg,pdf,sh,py,js,json,toml,yaml,yml
```

Any field omitted uses the built-in default. Dotdirs (`.git`, `.claude`, `.venv`, `.obsidian`) are always skipped.

## Let your LLM maintain it

The policy file is plain text that an LLM assistant can read and edit. Add one line to your `CLAUDE.md`:

```markdown
The GC policy for this vault is at `.primer-gc`.
When we add a new top-level content directory, update ALLOWED_DIRS.
When we introduce a new root-level convention file, update ALLOWED_ROOT_FILES.
When the filename convention changes, update FILENAME_REGEX.
```

Now when you tell your LLM "let's add a `6-Recipes/` directory for cooking content," it updates the policy at the same time. The GC learns without you editing a config file.

## What it checks

**Stray detection.** A `.md` file is stray if it's not in a `_*` dir, not in `ALLOWED_DIRS`, not an `ALLOWED_ROOT_FILES` entry, and not excluded by `SCAN_EXCLUDE_DIRS`. Strays get moved to `INBOX_DIR` (with today's date prefixed if not already dated).

**Lint.** For every file in an allowed location (outside `LINT_SKIP_DIRS`), checks for a frontmatter block (`---` on line 1). Flags missing frontmatter without moving anything.

**Duplicate slugs.** Vault-wide check for files whose slug (filename minus leading `YYYY-MM-DD-`) collides with another file's slug. Flagged, not fixed.

## Run it on a cron

Add to `~/.llm-primer/config`:

```ini
PRIMER_GC_VAULT=~/path/to/your/vault
PRIMER_GC_INTERVAL=3600   # seconds between runs (1 hour)
```

primerd runs the GC in the background every `PRIMER_GC_INTERVAL` seconds. Moved files appear in your inbox for normal triage.

## Exit codes

- `0` — clean (nothing stray, no lint issues)
- `2` — strays found (dry run only; --auto exits 0 after moving them)
- `3` — lint issues found

Useful for CI or scripting.

## Coming in v0.6.0

Static rules handle the obvious 95%. The remaining 5% — "is this file actually misplaced, or just unusual?" — deserves LLM judgment. Planned: ambiguous files get queued for an idle warm session to review, with decisions applied as moves. See [roadmap.md](roadmap.md).
