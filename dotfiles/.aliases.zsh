# Aliases shared by every machine: the laptop's ~/.zshrc and the loptech-ws
# server (its home-manager config sources this file too), so muscle memory
# is the same everywhere.

alias cc='claude --dangerously-skip-permissions'

# Git
alias gs='git status'
alias gc='git checkout'
alias gb='git checkout -b'
alias gp='git push'
alias gl='git log --oneline'

# loptech-ws: switch this shell (or tmux pane) to your agent account; `exit`
# comes back. Only defined where the agent account exists, so not on the laptop.
if id "${USER}-agent" &>/dev/null; then
  alias agent='sudo -iu "${USER}-agent"'
fi
