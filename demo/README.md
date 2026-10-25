# Demo GIF

`demo.gif` in the repo root is generated from `flipper-ls.tape` with [VHS](https://github.com/charmbracelet/vhs). Regenerate it whenever the plugin's behavior or the README demo should change.

## Requirements

- [VHS](https://github.com/charmbracelet/vhs#installation) (`brew install vhs`)
- Neovim >= 0.11, git, and bash
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) (optional, the tape tries MonoLisaCode first and VHS falls back to a default font)
- Network access on the first run, to clone [onedark.nvim](https://github.com/navarasu/onedark.nvim) and [blink.cmp](https://github.com/saghen/blink.cmp) into `/tmp`

## Regenerate

From the repo root:

```shell
vhs demo/flipper-ls.tape
```

This overwrites `demo.gif`. Commit it along with any tape changes.

## How it works

- `sample/` is a tiny Rails-style project: a `Gemfile` for root detection, `config/feature-descriptions.yml`, and a controller. The demo edits the controller in the buffer but never saves it.
- `init.lua` is a minimal config with blink.cmp (pinned, Lua matcher so no binary download), onedark, and `flipper_ls` enabled. The completion menu shows labels only, because VHS draws Nerd Font kind icons wider than one cell, and shows each feature's description below the menu.
- Hover (`K`) and go-to-definition (`gd`) run through keymaps with `showcmd` off, so popups appear without commands on screen.
- Steps wait on screen text (`Wait+Screen`), so if the plugin's behavior changes the render fails instead of recording a broken demo.
