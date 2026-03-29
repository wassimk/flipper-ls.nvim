describe('flipper-ls.server', function()
  local server

  local default_prefixes = {
    'Features.enabled?',
    'Features.feature_enabled?',
    'featureEnabled',
    'feature_enabled?',
    'with_feature',
    'without_feature',
  }

  before_each(function()
    package.loaded['flipper-ls.server'] = nil
    server = require('flipper-ls.server')
  end)

  describe('parse_feature_at_cursor', function()
    -- col is 0-indexed (LSP convention)

    it('parses feature name inside double-quoted string', function()
      --                 0         1         2         3         4
      --                 0123456789012345678901234567890123456789012345678
      local line = 'Features.enabled?("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 25, default_prefixes) -- on 'e' of 'enable'

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('Features.enabled?', ref.prefix)
    end)

    it('parses feature name inside single-quoted string', function()
      local line = "Features.enabled?('ROLLOUT_enable_dark_mode')"
      local ref = server.parse_feature_at_cursor(line, 25, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('Features.enabled?', ref.prefix)
    end)

    it('parses feature name after colon', function()
      local line = 'Features.enabled?(:ROLLOUT_enable_dark_mode)'
      local ref = server.parse_feature_at_cursor(line, 25, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('Features.enabled?', ref.prefix)
    end)

    it('parses JS-style featureEnabled prefix', function()
      --                 0         1
      --                 0123456789012345678
      local line = 'featureEnabled("dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 18, default_prefixes) -- on 'd' of 'dark'

      assert.is_not_nil(ref)
      assert.equals('dark_mode', ref.feature_name)
      assert.equals('featureEnabled', ref.prefix)
    end)

    it('parses with_feature prefix', function()
      local line = 'with_feature("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 20, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('with_feature', ref.prefix)
    end)

    it('parses without_feature prefix', function()
      local line = 'without_feature("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 23, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('without_feature', ref.prefix)
    end)

    it('parses feature_enabled? prefix', function()
      local line = 'feature_enabled?("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 24, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('feature_enabled?', ref.prefix)
    end)

    it('works with indented lines', function()
      local line = '    if Features.enabled?("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 31, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('ROLLOUT_enable_dark_mode', ref.feature_name)
      assert.equals('Features.enabled?', ref.prefix)
    end)

    it('works inside JS if-condition parentheses', function()
      local line = 'if (featureEnabled("dark_mode"))'
      local ref = server.parse_feature_at_cursor(line, 23, default_prefixes)

      assert.is_not_nil(ref)
      assert.equals('dark_mode', ref.feature_name)
      assert.equals('featureEnabled', ref.prefix)
    end)

    it('returns nil for plain text', function()
      local line = 'some plain text'
      local ref = server.parse_feature_at_cursor(line, 5, default_prefixes)

      assert.is_nil(ref)
    end)

    it('returns nil on empty line', function()
      local line = ''
      local ref = server.parse_feature_at_cursor(line, 0, default_prefixes)

      assert.is_nil(ref)
    end)

    it('returns nil on whitespace', function()
      local line = '    '
      local ref = server.parse_feature_at_cursor(line, 2, default_prefixes)

      assert.is_nil(ref)
    end)

    it('returns nil for invalid prefix', function()
      local line = 'SomeOther.method("ROLLOUT_enable_dark_mode")'
      local ref = server.parse_feature_at_cursor(line, 24, default_prefixes)

      assert.is_nil(ref)
    end)

    it('returns nil for word not inside method call', function()
      local line = '    result = ROLLOUT_enable_dark_mode'
      local ref = server.parse_feature_at_cursor(line, 20, default_prefixes)

      assert.is_nil(ref)
    end)
  end)
end)
