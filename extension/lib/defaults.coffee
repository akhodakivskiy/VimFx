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

    'tabs':
      't':         'tab_new'
      'yt':        'tab_duplicate'
      'J    gT':   'tab_select_previous'
      'K    gt':   'tab_select_next'
      'gJ':        'tab_move_backward'
      'gK':        'tab_move_forward'
      'g0':        'tab_select_first'
      'g^':        'tab_select_first_non_pinned'
      'g$':        'tab_select_last'
      'gp':        'tab_toggle_pinned'
      'x':         'tab_close'
      'X':         'tab_restore'
      'gx$':       'tab_close_to_end'
      'gxa':       'tab_close_other'

    'browsing':
      'f':         'follow'
      'F':         'follow_in_tab'
      'gf':        'follow_in_focused_tab'
      'af':        'follow_multiple'
      'yf':        'follow_copy'
      'zf':        'follow_focus'
      '[':         'follow_previous'
      ']':         'follow_next'
      'gi':        'focus_text_input'
      '<force><late><tab>':   'focus_next'
      '<force><late><s-tab>': 'focus_previous'

    'find':
      '/':         'find'
      'a/':        'find_highlight_all'
      'n':         'find_next'
      'N':         'find_previous'

    'misc':
      'i':         'enter_mode_ignore'
      'I':         'quote'
      '?':         'help'
      ':':         'dev'
      '<force><escape>': 'esc'

  'hints':
    '':
      '<escape>':        'exit'
      '<space>':         'rotate_markers_forward'
      '<s-space>':       'rotate_markers_backward'
      '<backspace>':     'delete_hint_char'
      '<enter>':         'increase_count'

  'ignore':
    '':
      '<s-escape>':      'exit'
      '<s-f1>':          'unquote'

  'find':
    '':
      '<escape>    <enter>': 'exit'

options =
  'hint_chars':             'fjdkslaghrueiwovncm'
  'prev_patterns':          'prev  previous  ‹  «  ◀  ←  <<  <  back  newer'
  'next_patterns':          'next  ›  »  ▶  →  >>  >  more  older'
  'black_list':             ''
  'prevent_autofocus':      false
  'ignore_keyboard_layout': false
  'timeout':                2000

advanced_options =
  'prevent_target_blank':               true
  'prevent_autofocus_modes':            'normal'
  'hints_timeout':                      200
  'smoothScroll.lines.spring-constant': '1000'
  'smoothScroll.pages.spring-constant': '2500'
  'smoothScroll.other.spring-constant': '2500'
  'pattern_selector':                   'a, button'
  'pattern_attrs':                      'rel  role  data-tooltip  aria-label'
  'hints_toggle_in_tab':                '<c-'
  'hints_toggle_in_background':         '<a-'
  'activatable_element_keys':           '<enter>'
  'adjustable_element_keys':            '<arrowup>  <arrowdown>  <arrowleft>
                                         <arrowright>  <space>  <enter>'
  'options.key.quote':                  '<c-q>'
  'options.key.insert_default':         '<c-d>'
  'options.key.reset_default':          '<c-r>'

parsed_options =
  'translations': {}
  'categories':   {} # Will be filled in below.



# The above easy-to-read data is transformed in to easy-to-consume (for
# computers) formats below.

translate = require('./l10n')
utils     = require('./utils')

addCategory = (category, order) ->
  uncategorized = (category == '')
  categoryName =
    if uncategorized
      -> ''
    else
      translate.bind(null, "category.#{ category }")
  parsed_options.categories[category] = {
    name:  categoryName
    order: if uncategorized then 0 else order
  }

shortcut_prefs = {}
categoryMap    = {}
mode_order     = {}
command_order  = {}

createCounter   = -> new utils.Counter({step: 100})
modeCounter     = createCounter()
categoryCounter = createCounter()

for modeName, modeCategories of shortcuts
  mode_order[modeName] = modeCounter.tick()
  for categoryName, modeShortcuts of modeCategories
    addCategory(categoryName, categoryCounter.tick())
    commandIndex = createCounter()
    for shortcut, commandName of modeShortcuts
      pref = "mode.#{ modeName }.#{ commandName }"
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
