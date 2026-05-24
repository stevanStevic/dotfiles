# dotfiles

Modular, idempotent setup scripts for a Linux (Ubuntu/Debian, GNOME) workstation.
Brings a fresh machine to a known baseline: keyboard remap (Caps→Ctrl), Ghostty
terminal, zsh + oh-my-zsh, neovim 0.11+, tmux, JetBrainsMono + Meslo Nerd Fonts,
and dotfile symlinks into `$HOME`.

## Bootstrap (fresh machine)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/bootstrap.sh)"
```

That installs `git`, clones this repo to `~/ws/dotfiles`, and runs all modules.

## What it does

| Module | Purpose |
|---|---|
| `00-apt-base` | apt refresh + base packages (curl, git, build-essential, …) |
| `10-keyboard` | Caps Lock → Ctrl via `/etc/default/keyboard` |
| `20-ghostty` | Install Ghostty (snap), register as terminal, GNOME `Ctrl+Alt+T` shortcut |
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

- **Caps→Ctrl** and **default shell** take effect after a logout/login (or reboot).
- **GNOME shortcut** binds `Ctrl+Alt+T` to Ghostty immediately.

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
- **Caps→Ctrl didn't take effect** — log out / log back in. The remap is at the
  X / Wayland session level.
- **Snap install fails** — `sudo snap install core` first, or rerun later.

## Testing

```bash
./test/test_helpers.sh                                # unit tests for lib/common.sh
./test/docker-run.sh                                  # full install run inside ubuntu:24.04, twice
shellcheck -x --source-path=SCRIPTDIR \
  install.sh uninstall.sh bootstrap.sh lib/*.sh modules/*.sh test/*.sh
```

CI runs `shellcheck` on every push.
