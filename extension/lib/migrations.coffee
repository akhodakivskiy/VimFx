# This file contains a list of functions that upgrade certain parts of VimFx
# from an old format to a new one, without breaking backwards compatibility.

legacy = require('./legacy')
prefs = require('./prefs')

migrations = []

migrations[0] = ->
  # coffeelint: disable=colon_assignment_spacing
  # coffeelint: disable=no_implicit_braces

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
    'insert_mode': 'normal.enter_mode_ignore'
    'quote':       'normal.quote'
    'help':        'normal.help'
    'dev':         'normal.dev'
    'Esc':         'normal.esc'

    'mode_insert_exit': 'ignore.exit'

    'mode_hints_exit':                    'hints.exit'
    'mode_hints_rotate_markers_forward':  'hints.rotate_markers_forward'
    'mode_hints_rotate_markers_backward': 'hints.rotate_markers_backward'
    'mode_hints_delete_hint_char':        'hints.delete_hint_char'

    'mode_find_exit': 'find.exit'

  # coffeelint: enable=colon_assignment_spacing
  # coffeelint: enable=no_implicit_braces

  convert = (value) ->
    keys = try JSON.parse(value)
    keys = [] unless Array.isArray(keys)
    for key, index in keys when typeof key == 'string'
      keys[index] = legacy.convertKey(key)
    return keys.map((key) -> key.join('')).join('    ')

  for name, newName of conversions
    pref = "commands.#{name}.keys"
    prefs.set("mode.#{newName}", convert(prefs.get(pref))) if prefs.has(pref)
  return

migrations[1] = ->
  pref = 'black_list'
  return unless prefs.has(pref)
  blacklist = prefs.get(pref)
  prefs.set(pref, legacy.splitListString(blacklist).join('  '))

migrations[2] = ->
  convert = (pref) ->
    return unless prefs.has(pref)
    patterns = prefs.get(pref)
    converted = legacy.splitListString(patterns)
      .map(legacy.convertPattern)
      .join('  ')
    prefs.set(pref, converted)

  convert('prev_patterns')
  convert('next_patterns')

migrations[3] = ->
  pref = 'mode.normal.esc'
  return unless prefs.has(pref)
  prefs.set(pref, prefs.get(pref).replace(
    /(^|\s)(?!(?:<late>)?<force>)(?=\S)/g,
    '$1<force>'
  ))

migrations[4] = ->
  pref = 'last_scroll_position_mark'
  return unless prefs.has(pref)
  prefs.set('scroll.last_position_mark', prefs.get(pref))

# The reasons for this migration are:
#
# - Make sure that people who have edited the pref and then blanked it out get
#   the new default.
# - Try to help users who thought that the list was comma separated.
# - Rename to `blacklist`.
migrations[5] = ->
  pref = 'black_list'
  return unless prefs.has(pref)
  oldValue = prefs.get(pref).trim()
  unless oldValue == ''
    prefs.set('blacklist', oldValue.replace(/,(?:\s+|(?=\*))/g, '  '))

migrations[6] = ->
  prefMap = {
    'hint_chars': 'hints.chars'
    'hints_sleep': 'hints.sleep'
    'hints_timeout': 'hints.matched_timeout'
    'hints_peek_through': 'hints.peek_through'
    'hints_toggle_in_tab': 'hints.toggle_in_tab'
    'hints_toggle_in_background': 'hints.toggle_in_background'
    'mode.hints.delete_hint_char': 'mode.hints.delete_char'
  }

  for pref, newPref of prefMap when prefs.has(pref)
    prefs.set(newPref, prefs.get(pref))
  return

module.exports = migrations
