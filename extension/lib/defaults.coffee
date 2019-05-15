# coffeelint: disable=colon_assignment_spacing
# coffeelint: disable=no_implicit_braces

# This file defines all VimFx’s options in an easy-to-read way.

shortcuts =
  'normal':
    'location':
      'o':         'focus_location_bar'
      'O':         'focus_search_bar'
      'p':         'paste_and_go'
      'P':         'paste_and_go_in_tab'
      'yy':        'copy_current_url'
      'gu':        'go_up_path'
      'gU':        'go_to_root'
      'gh':        'go_home'
      'H':         'history_back'
      'L':         'history_forward'
      'gH':        'history_list'
      'r':         'reload'
      'R':         'reload_force'
      'ar':        'reload_all'
      'aR':        'reload_all_force'
      's':         'stop'
      'as':        'stop_all'

    'scrolling':
      'h':         'scroll_left'
      'l':         'scroll_right'
      'j':         'scroll_down'
      'k':         'scroll_up'
      '<space>':   'scroll_page_down'
      '<s-space>': 'scroll_page_up'
      'd':         'scroll_half_page_down'
      'u':         'scroll_half_page_up'
      'gg':        'scroll_to_top'
      'G':         'scroll_to_bottom'
      '0  ^':      'scroll_to_left'
      '$':         'scroll_to_right'
      'm':         'mark_scroll_position'
      "'":         'scroll_to_mark'
      'g[':        'scroll_to_previous_position'
      'g]':        'scroll_to_next_position'

    'tabs':
      't':         'tab_new'
      'T':         'tab_new_after_current'
      'yt':        'tab_duplicate'
      'J    gT':   'tab_select_previous'
      'K    gt':   'tab_select_next'
      'gl':        'tab_select_most_recent'
      'gL':        'tab_select_oldest_unvisited'
      'gJ':        'tab_move_backward'
      'gK':        'tab_move_forward'
      'gw':        'tab_move_to_window'
      'g0':        'tab_select_first'
      'g^':        'tab_select_first_non_pinned'
      'g$':        'tab_select_last'
      'gp':        'tab_toggle_pinned'
      'x':         'tab_close'
      'X':         'tab_restore'
      'gX':        'tab_restore_list'
      'gx$':       'tab_close_to_end'
      'gxa':       'tab_close_other'

    'browsing':
      'f':         'follow'
      'F':         'follow_in_tab'
      'et':        'follow_in_focused_tab'
      'ew':        'follow_in_window'
      'ep':        'follow_in_private_window'
      'af':        'follow_multiple'
      'yf':        'follow_copy'
      'ef':        'follow_focus'
      'ec':        'open_context_menu'
      'eb':        'click_browser_element'
      '[':         'follow_previous'
      ']':         'follow_next'
      'gi':        'focus_text_input'
      'v':         'element_text_caret'
      'av':        'element_text_select'
      'yv':        'element_text_copy'

    'find':
      '/':         'find'
      'a/':        'find_highlight_all'
      'g/':        'find_links_only'
      'n':         'find_next'
      'N':         'find_previous'

    'misc':
      'w':         'window_new'
      'W':         'window_new_private'
      'i':         'enter_mode_ignore'
      'I':         'quote'
      'gr':        'enter_reader_view'
      'gB':        'edit_blacklist'
      'gC':        'reload_config_file'
      '?':         'help'
      '<force><escape>': 'esc'

  'caret':
    '':
      'h':         'move_left'
      'l':         'move_right'
      'j':         'move_down'
      'k':         'move_up'
      'b':         'move_word_left'
      'w':         'move_word_right'
      '0    ^':    'move_to_line_start'
      '$':         'move_to_line_end'
      'v':         'toggle_selection'
      'o':         'toggle_selection_direction'
      'y':         'copy_selection_and_exit'
      '<escape>':  'exit'

  'hints':
    '':
      '<escape>':        'exit'
      '<enter>    \
       <c-enter>    \
       <a-enter>':       'activate_highlighted'
      '<c-space>':       'rotate_markers_forward'
      '<s-space>':       'rotate_markers_backward'
      '<backspace>':     'delete_char'
      '<c-backspace>':   'toggle_complementary'
      '<up>':            'increase_count'

  'ignore':
    '':
      '<s-escape>':      'exit'
      '<s-f1>':          'unquote'

  'find':
    '':
      '<escape>    <enter>': 'exit'

  'marks':
    '':
      '<escape> ':       'exit'

options =
  'prevent_autofocus':      false
  'ignore_keyboard_layout': false
  'blacklist':              '*example.com*  http://example.org/editor/*'
  'hints.chars':            'fjdkslaghrueiwonc mv'
  'hints.auto_activate':    true
  'hints.timeout':          400
  'timeout':                2000
  'prev_patterns':          'prev  previous  ‹  «  ◀  ←  <<  <  back  newer'
  'next_patterns':          'next  ›  »  ▶  →  >>  >  more  older'

advanced_options =
  'notifications_enabled':              true
  'notify_entered_keys':                true
  'prevent_target_blank':               true
  'counts_enabled':                     true
  'find_from_top_of_viewport':          true
  'browsewithcaret':                    false
  'ignore_ctrl_alt':                    (Services.appinfo.OS == 'WINNT')
  'prevent_autofocus_modes':            'normal'
  'config_file_directory':              ''
  'blur_timeout':                       50
  'refocus_timeout':                    100
  'smoothScroll.lines.spring-constant': '1000'
  'smoothScroll.pages.spring-constant': '2500'
  'smoothScroll.other.spring-constant': '2500'
  'scroll.reset_timeout':               1000
  'scroll.repeat_timeout':              65
  'scroll.horizontal_boost':            6
  'scroll.vertical_boost':              3
  'scroll.full_page_adjustment':        40
  'scroll.half_page_adjustment':        20
  'scroll.last_position_mark':          "'"
  'scroll.last_find_mark':              '/'
  'pattern_selector':                   ':-moz-any(
                                           a, button, input[type="button"]
                                         ):not([role="menu"]):not([role="tab"])'
  'pattern_attrs':                      'rel  role  data-tooltip  aria-label'
  'hints.matched_timeout':              200
  'hints.sleep':                        15
  'hints.match_text':                   true
  'hints.peek_through':                 '<c-s->'
  'hints.toggle_in_tab':                '<c-'
  'hints.toggle_in_background':         '<a-'
  'activatable_element_keys':           '<enter>'
  'adjustable_element_keys':            '<arrowup>  <arrowdown>  <arrowleft>
                                         <arrowright>  <space>  <enter>'
  'focus_previous_key':                 '<s-tab>'
  'focus_next_key':                     '<tab>'
  'options.key.quote':                  '<c-q>'
  'options.key.insert_default':         '<c-d>'
  'options.key.reset_default':          '<c-r>'

parsed_options =
  'translations': {}
  'categories':   {} # Will be filled in below.



# The above easy-to-read data is transformed in to easy-to-consume (for
# computers) formats below.

# coffeelint: enable=colon_assignment_spacing
# coffeelint: enable=no_implicit_braces

translate = require('./translate')
utils = require('./utils')

addCategory = (category, order) ->
  uncategorized = (category == '')
  categoryName = if uncategorized then '' else translate("category.#{category}")
  parsed_options.categories[category] = {
    name: categoryName
    order: if uncategorized then 0 else order
  }

shortcut_prefs = {}
categoryMap = {}
mode_order = {}
command_order = {}

createCounter = -> new utils.Counter({step: 100})
modeCounter = createCounter()
categoryCounter = createCounter()

for modeName, modeCategories of shortcuts
  mode_order[modeName] = modeCounter.tick()
  for categoryName, modeShortcuts of modeCategories
    addCategory(categoryName, categoryCounter.tick())
    commandIndex = createCounter()
    for shortcut, commandName of modeShortcuts
      pref = "mode.#{modeName}.#{commandName}"
      shortcut_prefs[pref] = shortcut
      command_order[pref] = commandIndex.tick()
      categoryMap[pref] = categoryName

# All options, excluding shortcut customizations.
all_options = Object.assign({}, options, advanced_options, parsed_options)
# All things that are saved in Firefox’s prefs system.
all_prefs   = Object.assign({}, options, advanced_options, shortcut_prefs)

module.exports = {
  options
  advanced_options
  parsed_options
  all_options
  shortcut_prefs
  all_prefs
  categoryMap
  mode_order
  command_order
  BRANCH: 'extensions.VimFx.'
}
