local M = {}

local flippers = require('flipper-ls.flippers')

local DEFAULT_FEATURES_PATH = 'config/feature-descriptions.yml'

local DEFAULT_PREFIXES = {
  'Features.enabled?',
  'Features.feature_enabled?',
  'featureEnabled',
  'feature_enabled?',
  'with_feature',
  'without_feature',
}

local capabilities = {
  textDocumentSync = vim.lsp.protocol.TextDocumentSyncKind.None,
  completionProvider = {
    triggerCharacters = { '"', "'", ':' },
  },
  hoverProvider = true,
  definitionProvider = true,
}

--- Parse feature reference at cursor position.
--- @param line string
--- @param col integer 0-indexed cursor column
--- @param prefixes string[]
--- @return { feature_name: string, prefix: string }?
function M.parse_feature_at_cursor(line, col, prefixes)
  -- Expand from cursor to find the word boundary
  local left = col + 1
  while left > 1 and line:sub(left - 1, left - 1):match('[%w_]') do
    left = left - 1
  end
  local right = col + 1
  while right < #line and line:sub(right + 1, right + 1):match('[%w_]') do
    right = right + 1
  end

  local word = line:sub(left, right)
  if word == '' then
    return nil
  end

  -- Check if preceded by a string delimiter (" or ' or :)
  local char_before = left > 1 and line:sub(left - 1, left - 1) or ''
  if char_before == '"' or char_before == "'" or char_before == ':' then
    -- Look backward from the delimiter for the method prefix pattern: prefix(
    local before = line:sub(1, left - 2)
    local method_prefix = before:match('([%w_.?]+)%($')
    if method_prefix and flippers.valid_prefix(method_prefix, prefixes) then
      return { feature_name = word, prefix = method_prefix }
    end
  end

  return nil
end

local function get_line(params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  return vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1]
end

function M.create(dispatchers)
  local root_dir
  local closing = false
  local request_id = 0
  local features_path = DEFAULT_FEATURES_PATH
  local prefixes = DEFAULT_PREFIXES

  local methods = {}

  function methods.initialize(params, callback)
    root_dir = type(params.rootUri) == 'string' and vim.uri_to_fname(params.rootUri) or nil

    local opts = params.initializationOptions or {}
    if opts.features_path then
      features_path = opts.features_path
    end
    if opts.prefixes then
      prefixes = opts.prefixes
    end

    return callback(nil, { capabilities = capabilities })
  end

  function methods.shutdown(_, callback)
    return callback(nil, nil)
  end

  methods['textDocument/completion'] = function(params, callback)
    if not root_dir then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local line = get_line(params)
    if not line then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local col = params.position.character
    local before_cursor = line:sub(1, col)

    local method_prefix = before_cursor:match('([%w_.?]+)%(["\':]$')
    if not method_prefix then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    if not flippers.valid_prefix(method_prefix, prefixes) then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local len = #before_cursor
    local trigger_char = before_cursor:sub(len, len)

    local all_flippers
    if method_prefix == 'featureEnabled' then
      all_flippers = flippers.all_js(root_dir, features_path)
    else
      all_flippers = flippers.all(root_dir, features_path)
    end

    if not all_flippers or vim.tbl_isempty(all_flippers) then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local items = {}
    for name, description in pairs(all_flippers) do
      table.insert(items, {
        filterText = trigger_char .. name,
        label = trigger_char .. name,
        documentation = description,
        textEdit = {
          newText = trigger_char .. name,
          range = {
            start = {
              line = params.position.line,
              character = len - 1,
            },
            ['end'] = {
              line = params.position.line,
              character = len,
            },
          },
        },
      })
    end

    callback(nil, { isIncomplete = false, items = items })
  end

  methods['textDocument/hover'] = function(params, callback)
    if not root_dir then
      return callback(nil, nil)
    end

    local line = get_line(params)
    if not line then
      return callback(nil, nil)
    end

    local ref = M.parse_feature_at_cursor(line, params.position.character, prefixes)
    if not ref then
      return callback(nil, nil)
    end

    local description
    if ref.prefix == 'featureEnabled' then
      local original = flippers.resolve_js_name(root_dir, ref.feature_name, features_path)
      if not original then
        return callback(nil, nil)
      end
      description = flippers.description(root_dir, original, features_path)
    else
      description = flippers.description(root_dir, ref.feature_name, features_path)
    end

    if description == '' then
      return callback(nil, nil)
    end

    callback(nil, {
      contents = {
        kind = vim.lsp.protocol.MarkupKind.Markdown,
        value = '**' .. ref.feature_name .. '**\n\n' .. description,
      },
    })
  end

  methods['textDocument/definition'] = function(params, callback)
    if not root_dir then
      return callback(nil, nil)
    end

    local line = get_line(params)
    if not line then
      return callback(nil, nil)
    end

    local ref = M.parse_feature_at_cursor(line, params.position.character, prefixes)
    if not ref then
      return callback(nil, nil)
    end

    local target_name = ref.feature_name
    if ref.prefix == 'featureEnabled' then
      local original = flippers.resolve_js_name(root_dir, ref.feature_name, features_path)
      if not original then
        return callback(nil, nil)
      end
      target_name = original
    end

    local target_line = flippers.line(root_dir, target_name, features_path)
    if not target_line then
      return callback(nil, nil)
    end

    local file = root_dir .. '/' .. features_path

    callback(nil, {
      uri = vim.uri_from_fname(file),
      range = {
        start = { line = target_line, character = 0 },
        ['end'] = { line = target_line, character = 0 },
      },
    })
  end

  -- Dispatch table
  local res = {}

  function res.request(method, params, callback)
    local handler = methods[method]
    if handler then
      handler(params, callback)
    end
    request_id = request_id + 1
    return true, request_id
  end

  function res.notify(method, _)
    if method == 'exit' then
      dispatchers.on_exit(0, 15)
    end
    return false
  end

  function res.is_closing()
    return closing
  end

  function res.terminate()
    closing = true
  end

  return res
end

return M
