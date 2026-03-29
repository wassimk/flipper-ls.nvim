describe('flipper-ls.flippers', function()
  local flippers
  local root_dir
  local features_path = 'config/feature-descriptions.yml'

  local default_prefixes = {
    'Features.enabled?',
    'Features.feature_enabled?',
    'featureEnabled',
    'feature_enabled?',
    'with_feature',
    'without_feature',
  }

  before_each(function()
    package.loaded['flipper-ls.flippers'] = nil
    flippers = require('flipper-ls.flippers')

    local source = debug.getinfo(1, 'S').source:sub(2)
    root_dir = vim.fn.fnamemodify(source, ':h') .. '/fixtures'

    flippers._reset_cache()
  end)

  describe('all', function()
    it('loads features from YAML file', function()
      local result = flippers.all(root_dir, features_path)

      assert.is_not_nil(result)
      assert.equals('Allow users to toggle dark mode', result['ROLLOUT_enable_dark_mode'])
      assert.equals('Phase out old interface', result['ROLLOUT_disable_legacy_ui'])
      assert.equals('Push notification support', result['ROLLOUT_enable_notifications'])
    end)

    it('excludes ROLLOUT_test_feature_with_description', function()
      local result = flippers.all(root_dir, features_path)

      assert.is_nil(result['ROLLOUT_test_feature_with_description'])
    end)

    it('strips surrounding quotes from descriptions', function()
      local result = flippers.all(root_dir, features_path)

      assert.equals('Enables the new search feature', result['ROLLOUT_enable_search'])
    end)

    it('returns empty table when file does not exist', function()
      local result = flippers.all(root_dir, 'nonexistent.yml')

      assert.is_not_nil(result)
      assert.same({}, result)
    end)
  end)

  describe('all_js', function()
    it('transforms names for JS prefix', function()
      local result = flippers.all_js(root_dir, features_path)

      assert.is_not_nil(result)
      assert.is_nil(result['ROLLOUT_enable_dark_mode'])
      assert.equals('Allow users to toggle dark mode', result['dark_mode'])
      assert.equals('Phase out old interface', result['legacy_ui'])
      assert.equals('Push notification support', result['notifications'])
    end)
  end)

  describe('description', function()
    it('returns description for a known feature', function()
      local desc = flippers.description(root_dir, 'ROLLOUT_enable_dark_mode', features_path)

      assert.equals('Allow users to toggle dark mode', desc)
    end)

    it('returns empty string for unknown feature', function()
      local desc = flippers.description(root_dir, 'unknown_feature', features_path)

      assert.equals('', desc)
    end)
  end)

  describe('line', function()
    it('returns 0-indexed line number for first feature', function()
      local line_num = flippers.line(root_dir, 'ROLLOUT_enable_dark_mode', features_path)

      assert.equals(0, line_num)
    end)

    it('returns correct line for non-first feature', function()
      local line_num = flippers.line(root_dir, 'ROLLOUT_enable_notifications', features_path)

      assert.equals(3, line_num)
    end)

    it('returns nil for unknown feature', function()
      local line_num = flippers.line(root_dir, 'unknown_feature', features_path)

      assert.is_nil(line_num)
    end)
  end)

  describe('resolve_js_name', function()
    it('maps JS name back to original YAML name', function()
      local original = flippers.resolve_js_name(root_dir, 'dark_mode', features_path)

      assert.equals('ROLLOUT_enable_dark_mode', original)
    end)

    it('returns nil for unknown JS name', function()
      local original = flippers.resolve_js_name(root_dir, 'unknown', features_path)

      assert.is_nil(original)
    end)
  end)

  describe('valid_prefix', function()
    it('validates known prefixes', function()
      assert.is_true(flippers.valid_prefix('Features.enabled?', default_prefixes))
      assert.is_true(flippers.valid_prefix('Features.feature_enabled?', default_prefixes))
      assert.is_true(flippers.valid_prefix('featureEnabled', default_prefixes))
      assert.is_true(flippers.valid_prefix('feature_enabled?', default_prefixes))
      assert.is_true(flippers.valid_prefix('with_feature', default_prefixes))
      assert.is_true(flippers.valid_prefix('without_feature', default_prefixes))
    end)

    it('rejects invalid prefixes', function()
      assert.is_false(flippers.valid_prefix('SomeOther', default_prefixes))
      assert.is_false(flippers.valid_prefix('', default_prefixes))
      assert.is_false(flippers.valid_prefix(nil, default_prefixes))
    end)

    it('works with custom prefixes', function()
      local custom = { 'CustomPrefix' }

      assert.is_true(flippers.valid_prefix('CustomPrefix', custom))
      assert.is_false(flippers.valid_prefix('Features.enabled?', custom))
    end)
  end)

  describe('caching', function()
    it('returns same results on repeated calls', function()
      local result1 = flippers.all(root_dir, features_path)
      local result2 = flippers.all(root_dir, features_path)

      assert.equals(result1, result2)
    end)

    it('clears cache for a specific root', function()
      flippers.all(root_dir, features_path)
      flippers._reset_cache(root_dir)

      local result = flippers.all(root_dir, features_path)
      assert.truthy(next(result))
    end)
  end)
end)
