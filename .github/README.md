# vapenyk dotfiles ✨

cachyos - base system
stow - for dotfiles
metapac - for package installation

niri • dms

## install

```bash
git clone https://github.com/vapenyk/dotfiles.git ~/dotfiles
cd ~/dotfiles && git config core.hooksPath .githooks
paru -S stow metapac rbw
stow --no-folding -R .
metapac sync
```

## update

```bash
cd ~/dotfiles && git pull
```

Packages and stow links are refreshed automatically via the `post-merge` hook.

## license? hmm...
