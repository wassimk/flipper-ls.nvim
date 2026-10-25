# README demo for flipper-ls.nvim
#
# Render from the repo root:
#   vhs demo/flipper-ls.tape
#
# Runs in demo/sample, a tiny Rails-style project with config/feature-descriptions.yml. The
# controller is edited in the buffer but never saved.

Output demo.gif

Require bash
Require git
Require nvim

Set Shell "bash"
Set FontFamily "MonoLisaCode, JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1000
Set Height 560
Set Padding 16
Set Theme "OneHalfDark"
Set TypingSpeed 70ms
Set CursorBlink false

# Setup: open the controller in nvim with the minimal config
Hide
Type "cd demo/sample && nvim -u ../init.lua app/controllers/dashboard_controller.rb"
Enter
Wait+Screen@60s /class DashboardController/
Sleep 1.5s
Show

Sleep 800ms

# Completion: feature names with their descriptions
Type "6G"
Sleep 400ms
Type "O"
Type "return unless Features.enabled?(:"
Wait+Screen /ROLLOUT_enable_audit_log/
Sleep 1.5s
Down@900ms 4
Sleep 800ms
Type "analy"
Sleep 1.5s
Enter
Type ")"
Escape
Sleep 800ms

# Hover a feature name: its description
Type "F:l"
Sleep 400ms
Type "K"
Wait+Screen /usage trends/
Sleep 3s

# Go to definition: the feature's line in the YAML file
Type "gd"
Wait+Screen /feature-descriptions\.yml/

# Hold on the result before looping
Sleep 3s
