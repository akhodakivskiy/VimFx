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

legacy = require('./legacy')
{ getPref
, setPref
, isPrefSet} = require('./prefs')

applyMigrations = (migrations) ->
  for migration, index in migrations
    pref = "migration.#{ index }.applied"
    # This allows to manually choose migrations to apply. Be careful, though,
    # since some migrations might have to run in order!
    unless isPrefSet(pref) and getPref(pref)
      migration()
      setPref(pref, true)
  return

migrations = []

migrations[0] = ->
  conversions =
    'focus':                 'normal.focus_location_bar'
    'focus_search':          'normal.focus_search_bar'
    'paste':                 'normal.paste_and_go'
    'paste_tab':             'normal.paste_and_go_in_tab'
    'marker_yank':           'normal.follow_copy'
    'marker_focus':          'normal.follow_focus'
    'yank':                  'normal.copy_current_url'
    'reload':                'normal.reload'
    'reload_force':          'normal.reload_force'
    'reload_all':            'normal.reload_all'
    'reload_all_force':      'normal.reload_all_force'
    'stop':                  'normal.stop'
    'stop_all':              'normal.stop_all'

    'scroll_to_top':         'normal.scroll_to_top'
    'scroll_to_bottom':      'normal.scroll_to_bottom'
    'scroll_to_left':        'normal.scroll_to_left'
    'scroll_to_right':       'normal.scroll_to_right'
    'scroll_down':           'normal.scroll_down'
    'scroll_up':             'normal.scroll_up'
    'scroll_left':           'normal.scroll_left'
    'scroll_right':          'normal.scroll_right'
    'scroll_half_page_down': 'normal.scroll_half_page_down'
    'scroll_half_page_up':   'normal.scroll_half_page_up'
    'scroll_page_down':      'normal.scroll_page_down'
    'scroll_page_up':        'normal.scroll_page_up'

    'open_tab':              'normal.tab_new'
    'tab_prev':              'normal.tab_select_previous'
    'tab_next':              'normal.tab_select_next'
    'tab_move_left':         'normal.tab_move_backward'
    'tab_move_right':        'normal.tab_move_forward'
    'home':                  'normal.go_home'
    'tab_first':             'normal.tab_select_first'
    'tab_first_non_pinned':  'normal.tab_select_first_non_pinned'
    'tab_last':              'normal.tab_select_last'
    'toggle_pin_tab':        'normal.tab_toggle_pinned'
    'duplicate_tab':         'normal.tab_duplicate'
    'close_tabs_to_end':     'normal.tab_close_to_end'
    'close_other_tabs':      'normal.tab_close_other'
    'close_tab':             'normal.tab_close'
    'restore_tab':           'normal.tab_restore'

    'follow':                'normal.follow'
    'follow_in_tab':         'normal.follow_in_tab'
    'follow_in_focused_tab': 'normal.follow_in_focused_tab'
    'follow_multiple':       'normal.follow_multiple'
    'follow_previous':       'normal.follow_previous'
    'follow_next':           'normal.follow_next'
    'text_input':            'normal.text_input'
    'go_up_path':            'normal.go_up_path'
    'go_to_root':            'normal.go_to_root'
    'back':                  'normal.history_back'
    'forward':               'normal.history_forward'

    'find':        'normal.find'
    'find_hl':     'normal.find_highlight_all'
    'find_next':   'normal.find_next'
    'find_prev':   'normal.find_previous'
    'insert_mode': 'normal.enter_mode_insert'
    'quote':       'normal.quote'
    'help':        'normal.help'
    'dev':         'normal.dev'
    'Esc':         'normal.esc'

    'mode_insert_exit': 'insert.exit'

    'mode_hints_exit':                    'hints.exit'
    'mode_hints_rotate_markers_forward':  'hints.rotate_markers_forward'
    'mode_hints_rotate_markers_backward': 'hints.rotate_markers_backward'
    'mode_hints_delete_hint_char':        'hints.delete_hint_char'

    'mode_find_exit': 'find.exit'


  convert = (value) ->
    keys =
      try JSON.parse(value)
      catch then []
    for key, index in keys when typeof key == 'string'
      keys[index] = legacy.convertKey(key)
    return keys.map((key) -> key.join('')).join('  ')

  for name, newName of conversions
    pref = "commands.#{ name }.keys"
    setPref("mode.#{ newName }", convert(getPref(pref))) if isPrefSet(pref)
  return

exports.applyMigrations = applyMigrations
exports.migrations      = migrations
