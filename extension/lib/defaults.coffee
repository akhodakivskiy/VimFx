###
# Copyright Simon Lydell 2015.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

notation = require('vim-like-key-notation')



shortcuts =
  'normal':
    'o':          'focus'
    'O':          'focus_search'
    'p':          'paste'
    'P':          'paste_tab'
    'yf':         'marker_yank'
    'vf':         'marker_focus'
    'yy':         'yank'
    'r':          'reload'
    'R':          'reload_force'
    'ar':         'reload_all'
    'aR':         'reload_all_force'
    's':          'stop'
    'as':         'stop_all'

    'gg':         'scroll_to_top'
    'G':          'scroll_to_bottom'
    '0  ^':       'scroll_to_left'
    '$':          'scroll_to_right'
    'j':          'scroll_down'
    'k':          'scroll_up'
    'h':          'scroll_left'
    'l':          'scroll_right'
    'd':          'scroll_half_page_down'
    'u':          'scroll_half_page_up'
    '<space>':    'scroll_page_down'
    '<s-space>':  'scroll_page_up'

    't':          'open_tab'
    'J  gT':      'tab_prev'
    'K  gt':      'tab_next'
    'gJ':         'tab_move_left'
    'gK':         'tab_move_right'
    'gh':         'home'
    'gH  g0':     'tab_first'
    'g^':         'tab_first_non_pinned'
    'gL  g$':     'tab_last'
    'gp':         'toggle_pin_tab'
    'yt':         'duplicate_tab'
    'gx$':        'close_tabs_to_end'
    'gxa':        'close_other_tabs'
    'x':          'close_tab'
    'X':          'restore_tab'

    'f':          'follow'
    'F':          'follow_in_tab'
    'gf':         'follow_in_focused_tab'
    'af':         'follow_multiple'
    '[':          'follow_previous'
    ']':          'follow_next'
    'gi':         'text_input'
    'gu':         'go_up_path'
    'gU':         'go_to_root'
    'H':          'back'
    'L':          'forward'

    '/':          'find'
    'a/':         'find_hl'
    'n':          'find_next'
    'N':          'find_prev'
    'i':          'insert_mode'
    'I':          'quote'
    '?':          'help'
    ':':          'dev'
    '<escape>':   'Esc'

  'insert':
    '<s-escape>':  'exit'

  'hints':
    '<escape>':    'exit'
    '<space>':     'rotate_markers_forward'
    '<s-space>':   'rotate_markers_backward'
    '<backspace>': 'delete_hint_char'

  'find':
    '<escape>  <enter>': 'exit'

options =
  'hint_chars':             'fjdkslaghrueiwovncm'
  'prev_patterns':          'prev,previous,‹,«,◀,←,<<,<,back,newer'
  'next_patterns':          'next,›,»,▶,→,>>,>,more,older'
  'black_list':             ''
  'prevent_autofocus':      true
  'ignore_keyboard_layout': false

advanced_options =
  'autofocus_limit':                    100
  'smoothScroll.lines.spring-constant': '1000'
  'smoothScroll.pages.spring-constant': '2500'
  'smoothScroll.other.spring-constant': '2500'
  'translations':                       '{}'



key_options = {}
for modeName, modeShortcuts of shortcuts
  for keys, name of modeShortcuts
    name = "mode_#{ modeName }_#{ name }" unless modeName == 'normal'
    key_options["commands.#{ name }.keys"] =
      keys.split(/\s+/).map(notation.parseSequence)

all = Object.assign({}, options, advanced_options, key_options)

exports.options          = options
exports.advanced_options = advanced_options
exports.key_options      = key_options
exports.all              = all
exports.BRANCH           = 'extensions.VimFx.'
