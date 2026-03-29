local M = {}

local _caches = {}

function M._reset_cache(root_dir)
  if root_dir then
    _caches[root_dir] = nil
  else
    _caches = {}
  end
end

local function get_cache(root_dir)
  if not _caches[root_dir] then
    _caches[root_dir] = {
      features = nil,
      js_features = nil,
      js_to_original = nil,
      lines = nil,
    }
  end
  return _caches[root_dir]
end

local function load_features(root_dir, features_path)
  local cache = get_cache(root_dir)
  if cache.features then
    return
  end

  local filepath = root_dir .. '/' .. features_path

  local features = {}
  local lines = {}

  local ok, _ = pcall(function()
    local line_num = 0
    for line in io.lines(filepath) do
      local name, description = line:match('^([A-Za-z0-9_]+): (.+)$')

      if name and description then
        if name ~= 'ROLLOUT_test_feature_with_description' then
          description = vim.trim(description)
          description = description:gsub('^["\']', ''):gsub('["\']$', '')
          features[name] = description
          lines[name] = line_num
        end
      end

      line_num = line_num + 1
    end
  end)

  if ok then
    cache.features = features
    cache.lines = lines
  else
    cache.features = {}
    cache.lines = {}
  end
end

local function ensure_js_features(root_dir, features_path)
  local cache = get_cache(root_dir)
  if cache.js_features then
    return
  end

  load_features(root_dir, features_path)

  local js_features = {}
  local js_to_original = {}

  for name, description in pairs(cache.features) do
    local new_name = name:match('_([_a-z]+)')
    if new_name then
      new_name = new_name:gsub('enable_', ''):gsub('disable_', '')
      js_features[new_name] = description
      js_to_original[new_name] = name
    end
  end

  cache.js_features = js_features
  cache.js_to_original = js_to_original
end

function M.all(root_dir, features_path)
  load_features(root_dir, features_path)
  return get_cache(root_dir).features
end

function M.all_js(root_dir, features_path)
  ensure_js_features(root_dir, features_path)
  return get_cache(root_dir).js_features
end

function M.description(root_dir, name, features_path)
  load_features(root_dir, features_path)
  return get_cache(root_dir).features[name] or ''
end

function M.line(root_dir, name, features_path)
  load_features(root_dir, features_path)
  return get_cache(root_dir).lines[name]
end

function M.resolve_js_name(root_dir, js_name, features_path)
  ensure_js_features(root_dir, features_path)
  return get_cache(root_dir).js_to_original[js_name]
end

function M.valid_prefix(prefix, prefixes)
  if prefix == nil or prefix == '' then
    return false
  end

  for _, valid_prefix in ipairs(prefixes) do
    if vim.startswith(prefix, valid_prefix) then
      return true
    end
  end

  return false
end

return M
