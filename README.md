dotfiles README

These are my (drmdrew) dotfiles. Use at your own risk ;-)

## Install

Needs [mise](https://mise.jdx.dev). From this directory:

```sh
mise trust && mise run install
```

This symlinks the dotfiles into `~` and builds the agent skills. `mise tasks`
lists the other tasks, such as `mise run skills:setup` to rebuild the skills
after pulling an update.
