# Installation

## macOS — Homebrew

```bash
brew tap asakin/llm-primer
brew install llm-primer
```

## Any Unix — curl

```bash
# Latest release (recommended)
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/v0.5.0/install.sh | VERSION=v0.5.0 bash

# Bleeding edge (tracks main, may break)
curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash
```

The installer will ask whether to install a launchd agent (macOS only) so `primerd` starts on login. Strongly recommended; otherwise you have to run `primerd start` after every reboot.

## Dependencies

- `tmux`
- Whatever LLM CLI you're using (the installer warns if it's not in PATH)

That's it. No build step, no runtime.

## Verify

```bash
primer selftest --fast
```

Should pass every assertion in under a second.

## launchd agent (macOS)

The installer sets it up interactively. To install after the fact:
```bash
LAUNCHD=yes bash install.sh
```

To unload:
```bash
launchctl unload ~/Library/LaunchAgents/io.github.asakin.primerd.plist
```

The plist doesn't bake any PRIMER_* variables into itself — they're read from `~/.llm-primer/config` at startup. Edit the config, restart primerd, no plist regeneration needed.

## iTerm2 profile — open straight into a warm session

Preferences → Profiles → [your profile] → General → Command:
- Select **Command**
- Enter: `/opt/homebrew/bin/primer attach` (or `/usr/local/bin/primer attach` on Intel Macs)

New tab = warm session, no `primer attach` needed.

## Obsidian embedded terminal

Install the ObsidianTerminal community plugin.
Settings → Community Plugins → Obsidian Terminal → Custom Shell Command → `primer attach`.

## Uninstall

```bash
# Homebrew
brew uninstall llm-primer
brew untap asakin/llm-primer

# Manual (curl install)
rm /opt/homebrew/bin/primer /opt/homebrew/bin/primerd /opt/homebrew/bin/primer-gc /opt/homebrew/bin/primer-selftest
# (or wherever INSTALL_DIR pointed)

# Launchd
launchctl unload ~/Library/LaunchAgents/io.github.asakin.primerd.plist
rm ~/Library/LaunchAgents/io.github.asakin.primerd.plist

# State (optional — your config lives here)
rm -rf ~/.llm-primer
```
