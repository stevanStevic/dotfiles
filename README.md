# dotfiles

Modular, idempotent setup scripts for a Linux (Ubuntu/Debian, GNOME) workstation.
Brings a fresh machine to a known baseline: keyboard remap (Caps→Ctrl), Ghostty
terminal, zsh + oh-my-zsh, neovim 0.11+, tmux, JetBrainsMono + Meslo Nerd Fonts,
and dotfile symlinks into `$HOME`.

## Bootstrap (fresh machine)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/stevanStevic/dotfiles/main/bootstrap.sh)"
```

That installs `git`, clones this repo to `~/ws/dotfiles`, and runs all modules.

## What it does

| Module | Purpose |
|---|---|
| `00-apt-base` | apt refresh + base packages (curl, git, build-essential, …) |
| `10-keyboard` | Caps Lock → Ctrl via `/etc/default/keyboard` **and** GNOME `input-sources` xkb-options |
| `20-ghostty` | Install Ghostty (snap), register as terminal, clear GNOME's built-in terminal key, bind `Ctrl+Alt+T` → Ghostty |
| `30-zsh` | zsh + oh-my-zsh, set as login shell |
| `40-nvim` | neovim ≥ 0.11 from stable PPA |
| `50-tmux` | tmux |
| `60-fonts` | JetBrainsMono Nerd Font + Meslo Nerd Font (user-local) |
| `90-symlinks` | Symlink `dotfiles/*` into `$HOME` |

## Running individual modules

```bash
./install.sh                # all modules
./install.sh ghostty zsh    # only matching modules (substring match)
./install.sh --dry-run      # log-only, no system changes
```

## After install

- **Caps→Ctrl**: on GNOME/Wayland it applies immediately (set via GNOME
  `input-sources`); the `/etc/default/keyboard` change for console/non-GNOME
  sessions takes effect after a logout/login. **Default shell** takes effect
  after a logout/login (or reboot).
- **GNOME `Ctrl+Alt+T` → Ghostty**: the module binds the shortcut, clears
  GNOME's conflicting built-in terminal key, and reloads `gnome-settings-daemon`
  so it works right away. If it still opens the old terminal, log out/in.

## Editing configs

Configs live in `dotfiles/` and are symlinked into `$HOME`. Edit them in place
under `dotfiles/`, commit, push — every machine that pulls picks up the change.

```
dotfiles/.zshrc                 -> ~/.zshrc
dotfiles/.tmux.conf             -> ~/.tmux.conf
dotfiles/config/ghostty/config  -> ~/.config/ghostty/config
dotfiles/config/nvim/           -> ~/.config/nvim/
```

## Uninstalling

```bash
./uninstall.sh              # restore backups, remove symlinks; keep apt packages
./uninstall.sh ghostty      # only unwind matching modules
./uninstall.sh --purge      # also remove oh-my-zsh, ghostty snap, reset login shell
```

## Troubleshooting

- **Symlink conflicts** — a real file already exists where a symlink should go.
  The script backs it up to `<path>.bak-<UTC-timestamp>`. Move or remove the
  backup if it's no longer needed.
- **Caps→Ctrl didn't take effect** — on GNOME/Wayland the active option lives in
  GNOME, not `/etc/default/keyboard`. Check `gsettings get
  org.gnome.desktop.input-sources xkb-options` (should contain
  `'caps:ctrl_modifier'`); rerun `./install.sh keyboard` to set it, or log out/in.
- **Snap install fails** — `sudo snap install core` first, or rerun later.
- **`Ctrl+Alt+T` opens the wrong terminal (or nothing)** — GNOME's built-in
  terminal media key holds that shortcut and `gnome-settings-daemon` hasn't
  re-grabbed the Ghostty binding. Rerun `./install.sh ghostty` (it clears the
  built-in key and reloads gsd), or log out/in. Diagnose with
  `journalctl --user -b | grep -i 'failed to grab.*custom0'` — if that line
  appears, gsd couldn't claim the shortcut.

## Testing

```bash
./test/test_helpers.sh                                # unit tests for lib/common.sh
./test/docker-run.sh                                  # full install run inside ubuntu:24.04, twice
shellcheck -x --source-path=SCRIPTDIR \
  install.sh uninstall.sh bootstrap.sh lib/*.sh modules/*.sh test/*.sh
```

CI runs `shellcheck` on every push.
