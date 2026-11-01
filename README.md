# Dot Files Repository

This is the repository of dot files from Pedro Magnus.

## Installation

Clone the repo into `~/.dot` (the configs reference that path) and run:

```sh
./install.sh              # menu to pick what to install
./install.sh tmux zsh     # install only the listed items
./install.sh --all        # install everything without asking
```

Items: `zsh`, `tmux`, `zellij`, `alacritty`. The script creates symlinks and can be
run again safely: items already linked are skipped. If something else already exists
at the destination, it warns and asks whether to remove it with a backup (`*.bak`),
remove it without a backup, or skip it. Without a terminal it always makes a backup.

In the menu: `↑/↓` or `j/k` move, `space` toggles, `a` toggles all, `enter` confirms, `q` quits.

## Contents

This repository contains configuration files for various applications and tools. Customize them as needed to fit your setup.
