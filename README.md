# flipper-ls.nvim

An in-process Neovim LSP server for [Flipper](https://github.com/jnunemaker/flipper) feature flag names. Provides completion, hover, and go-to-definition by reading feature names and descriptions from a YAML config file.

## Requirements

- Neovim 0.11+
- A `config/feature-descriptions.yml` file in your project root

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'wassimk/flipper-ls.nvim',
  ft = { 'ruby', 'eruby', 'javascript', 'typescript', 'typescriptreact', 'javascriptreact' },
  config = function()
    vim.lsp.enable('flipper_ls')
  end,
}
```

## Features

### Completion

Completions trigger when typing flipper method calls such as:

- `Features.enabled?("`
- `Features.feature_enabled?("`
- `featureEnabled("`
- `feature_enabled?("`
- `with_feature("`
- `without_feature("`

The trigger characters are `"`, `'`, and `:` (for Ruby symbols).

When using the `featureEnabled` JavaScript/TypeScript prefix, feature names are automatically transformed by stripping the `ROLLOUT_` prefix and `enable_`/`disable_` prefixes. For example, `ROLLOUT_enable_dark_mode` becomes `dark_mode`.

### Hover

Hover over a feature name to see its description from the YAML file.

### Go-to-definition

Jump to the feature's line in the YAML config file.

## How It Works

The plugin reads feature names from `config/feature-descriptions.yml` (relative to your project root). This file should contain lines in the format:

```yaml
ROLLOUT_enable_dark_mode: Allow users to toggle dark mode
ROLLOUT_disable_legacy_ui: Phase out old interface
```

The LSP server runs entirely in-process within Neovim. No external process is spawned. Feature data is cached in memory after the first request.

The server only activates when it finds `config/feature-descriptions.yml` under a project root (detected via `Gemfile`, `package.json`, or `.git`).

## Configuration

The defaults work for most projects. For custom paths or prefixes, use `vim.lsp.config`:

```lua
vim.lsp.config('flipper_ls', {
  init_options = {
    features_path = 'config/custom-features.yml',
    prefixes = {
      'Features.enabled?',
      'Features.feature_enabled?',
      'featureEnabled',
      'feature_enabled?',
      'with_feature',
      'without_feature',
    },
  },
})
vim.lsp.enable('flipper_ls')
```

| Option | Default | Description |
| --- | --- | --- |
| `features_path` | `config/feature-descriptions.yml` | Path to the YAML features file (relative to project root) |
| `prefixes` | See above | List of method prefixes that trigger completion |

## Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```

This activates a pre-commit hook that auto-generates `doc/flipper-ls.nvim.txt` from `README.md` whenever the README is staged. Requires [pandoc](https://pandoc.org/installing.html).
