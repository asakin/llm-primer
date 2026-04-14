# Release Process

Two repos need to stay in sync on every release:

- **`asakin/llm-primer`** — the actual code
- **`asakin/homebrew-llm-primer`** — the Homebrew tap formula

This is currently manual. A GitHub Action to automate it is on the backlog.

---

## Cutting a release

1. **Land all changes on `main`.** Run `primer selftest` locally one more time.

2. **Pick the version.** Follow SemVer:
   - **patch** (`v0.X.Y → v0.X.(Y+1)`): bug fixes, doc changes, test improvements
   - **minor** (`v0.X.Y → v0.(X+1).0`): new features, new binaries, new env vars, renames with a backwards-compat alias
   - **major** (`v1.0.0+`): breaking removals, incompatible config changes

3. **Tag and push from `main`:**
   ```bash
   git tag v0.X.0
   git push origin v0.X.0
   ```

4. **Create a GitHub release** for the tag. Paste release notes — one-line bullets, grouped by type (fixes / features / docs). The auto-generated PR list from GitHub is fine as a starting point but clean it up.

5. **Compute the tarball sha256:**
   ```bash
   curl -sL https://github.com/asakin/llm-primer/archive/refs/tags/v0.X.0.tar.gz | shasum -a 256
   ```

6. **Open a PR in `asakin/homebrew-llm-primer`** that updates three lines in `Formula/llm-primer.rb`:
   - `url` → new tag
   - `sha256` → the value from step 5
   - `version` → new version

   Merge the PR immediately — the formula is mechanical.

7. **Verify the install works** on a clean environment:
   ```bash
   brew update
   brew upgrade llm-primer
   primer selftest --fast
   ```

---

## Release notes template

```markdown
## v0.X.0 — Short title

### Fixes
- One-line description of each bug fixed

### Features
- One-line description of each new capability

### Breaking changes
- What was renamed/removed, and the backwards-compat window (if any)

### Docs
- Notable doc changes only — don't list typo fixes

---

Upgrade: `brew upgrade llm-primer` or `curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/v0.X.0/install.sh | VERSION=v0.X.0 bash`
```

---

## Version policy

- The `main` branch always works (selftest passes). Never push broken code that will sit on `main`.
- `install.sh` defaults to `main` for bleeding-edge, but users can pin with `VERSION=v0.X.0`.
- The Homebrew formula always points at a released tag, never at `main`. That's what `brew` is for.
- Deprecations get one minor release with a backwards-compat alias + warning. Then they can be removed.

---

## Future: automate steps 4–6

A GitHub Action on `push` of a `v*` tag could:

1. Auto-create the release with generated notes
2. Compute the sha256
3. Open a PR in `homebrew-llm-primer` bumping the three lines (using a PAT with `repo` scope on that repo)

Reference: [dawidd6/action-homebrew-bump-formula](https://github.com/dawidd6/action-homebrew-bump-formula). Until that's in place, do it by hand — five minutes per release.
