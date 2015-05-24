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
    # Location
    'o':           'focus_location_bar'
    'O':           'focus_search_bar'
    'p':           'paste_and_go'
    'P':           'paste_and_go_in_tab'
    'yy':          'copy_current_url'
    'gu':          'go_up_path'
    'gU':          'go_to_root'
    'gh':          'go_home'
    'H':           'history_back'
    'L':           'history_forward'
    'r':           'reload'
    'R':           'reload_force'
    'ar':          'reload_all'
    'aR':          'reload_all_force'
    's':           'stop'
    'as':          'stop_all'

    # Scrolling
    'h':           'scroll_left'
    'l':           'scroll_right'
    'j':           'scroll_down'
    'k':           'scroll_up'
    '<space>':     'scroll_page_down'
    '<s-space>':   'scroll_page_up'
    'd':           'scroll_half_page_down'
    'u':           'scroll_half_page_up'
    'gg':          'scroll_to_top'
    'G':           'scroll_to_bottom'
    '0  ^':        'scroll_to_left'
    '$':           'scroll_to_right'

    # Tabs
    't':           'tab_new'
    'yt':          'tab_duplicate'
    'J  gT':       'tab_select_previous'
    'K  gt':       'tab_select_next'
    'gJ':          'tab_move_backward'
    'gK':          'tab_move_forward'
    'gH  g0':      'tab_select_first'
    'g^':          'tab_select_first_non_pinned'
    'gL  g$':      'tab_select_last'
    'gp':          'tab_toggle_pinned'
    'x':           'tab_close'
    'X':           'tab_restore'
    'gx$':         'tab_close_to_end'
    'gxa':         'tab_close_other'

    # Browsing
    'f':           'follow'
    'F':           'follow_in_tab'
    'gf':          'follow_in_focused_tab'
    'af':          'follow_multiple'
    'yf':          'follow_copy'
    'vf':          'follow_focus'
    '[':           'follow_previous'
    ']':           'follow_next'
    'gi':          'text_input'

    # Find
    '/':           'find'
    'a/':          'find_highlight_all'
    'n':           'find_next'
    'N':           'find_previous'

    # Misc
    'i':           'enter_mode_insert'
    'I':           'quote'
    '?':           'help'
    ':':           'dev'
    '<escape>':    'esc'

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
    key_options["mode.#{ modeName }.#{ name }"] = keys

all = Object.assign({}, options, advanced_options, key_options)

exports.options          = options
exports.advanced_options = advanced_options
exports.key_options      = key_options
exports.all              = all
exports.BRANCH           = 'extensions.VimFx.'
