return {
  cmd = function(dispatchers)
    return require('flipper-ls.server').create(dispatchers)
  end,
  filetypes = { 'ruby', 'eruby', 'javascript', 'typescript', 'typescriptreact', 'javascriptreact' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'Gemfile', 'package.json', '.git' })
    if not root then
      return on_dir()
    end

    if vim.uv.fs_stat(root .. '/config/feature-descriptions.yml') then
      return on_dir(root)
    end

    on_dir()
  end,
}
