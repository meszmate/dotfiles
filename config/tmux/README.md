# tmux

`tmux.conf` bootstraps itself: if tpm, a plugin or the tmux-thumbs binary is
missing on server start it runs `scripts/bootstrap`, which clones
[tpm](https://github.com/tmux-plugins/tpm) into `plugins/` (gitignored),
installs every `@plugin` listed and drops in the prebuilt tmux-thumbs binary —
so the Catppuccin status bar and all plugins work on the first `tmux`, no
`prefix + I` needed. `setup/arch.sh` runs the same script; `prefix + U`
updates plugins.

`prefix + ?` opens the keybind cheatsheet (`bin/keybinds tmux`, the same
overlay as `SUPER + /` on the desktop; a popup over ssh). Binds live in
`tmux.reset.conf` as `bind -N "Section · What it does" key cmd`.
