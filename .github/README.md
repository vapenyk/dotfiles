# vapenyk dotfiles ✨

cachyos - base system

stow - for dotfiles

pkg - for package installation

niri • dms

## install

```bash
paru -S stow git 
git clone https://github.com/vapenyk/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --no-folding -R base
stow --no-folding -R pkg
./scripts/install-bashrc-d.sh
source .bashrc
pkg sync
```

## update

```bash
cd ~/dotfiles && git pull
```

Packages and stow links are refreshed automatically via the `post-merge` hook.

## pkg `pkg/.local/bin/pkg`

Is a single-file, declarative package manager wrapper. Was inspired by pacdef/metapac. [README](../pkg/README.md)

## screensaver `screensaver/.local/bin/screensaver`

tte • foot • swayidle (for niri integration).

Idea was partially copied from basecamp/omarchy and slightly modified so I could at least understand how it works. Edit the ASCII in `.local/screensaver/logo.txt`.

## license? hmm... MIT
