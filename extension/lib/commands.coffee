###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
# Copyright Wang Zhuochun 2013, 2014.
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

help       = require('./help')
{ Marker } = require('./marker')
utils      = require('./utils')

{ isProperLink, isTextInputElement, isContentEditable } = utils

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

XULDocument = Ci.nsIDOMXULDocument

commands = {}



commands.focus_location_bar = ({ vim }) ->
  # This function works even if the Address Bar has been removed.
  vim.rootWindow.focusAndSelectUrlBar()

commands.focus_search_bar = ({ vim }) ->
  # The `.webSearch()` method opens a search engine in a tab if the Search Bar
  # has been removed. Therefore we first check if it exists.
  if vim.rootWindow.BrowserSearch.searchBar
    vim.rootWindow.BrowserSearch.webSearch()

helper_paste = (vim) ->
  url = vim.rootWindow.readFromClipboard()
  postData = null
  if not utils.isURL(url) and submission = utils.browserSearchSubmission(url)
    url = submission.uri.spec
    { postData } = submission
  return {url, postData}

commands.paste_and_go = ({ vim }) ->
  { url, postData } = helper_paste(vim)
  vim.rootWindow.gBrowser.loadURIWithFlags(url, {postData})

commands.paste_and_go_in_tab = ({ vim }) ->
  { url, postData } = helper_paste(vim)
  vim.rootWindow.gBrowser.selectedTab =
    vim.rootWindow.gBrowser.addTab(url, {postData})

commands.copy_current_url = ({ vim }) ->
  utils.writeToClipboard(vim.rootWindow.gBrowser.currentURI.spec)

# Go up one level in the URL hierarchy.
commands.go_up_path = ({ vim, count }) ->
  { pathname } = vim.window.location
  vim.window.location.pathname = pathname.replace(
    /// (?: /[^/]+ ){1,#{ count ? 1 }} /?$ ///, ''
  )

# Go up to root of the URL hierarchy.
commands.go_to_root = ({ vim }) ->
  vim.window.location.href = vim.window.location.origin

commands.go_home = ({ vim }) ->
  vim.rootWindow.BrowserHome()

helper_go_history = (num, { vim, count }) ->
  { gBrowser } = vim.rootWindow
  { index, count: length } = gBrowser.sessionHistory
  newIndex = index + num * (count ? 1)
  newIndex = Math.max(newIndex, 0)
  newIndex = Math.min(newIndex, length - 1)
  gBrowser.gotoIndex(newIndex) unless newIndex == index

commands.history_back    = helper_go_history.bind(null, -1)

commands.history_forward = helper_go_history.bind(null, +1)

commands.reload = ({ vim }) ->
  vim.rootWindow.BrowserReload()

commands.reload_force = ({ vim }) ->
  vim.rootWindow.BrowserReloadSkipCache()

commands.reload_all = ({ vim }) ->
  vim.rootWindow.gBrowser.reloadAllTabs()

commands.reload_all_force = ({ vim }) ->
  for tab in vim.rootWindow.gBrowser.visibleTabs
    gBrowser = tab.linkedBrowser
    consts = gBrowser.webNavigation
    flags = consts.LOAD_FLAGS_BYPASS_PROXY | consts.LOAD_FLAGS_BYPASS_CACHE
    gBrowser.reload(flags)
  return

commands.stop = ({ vim }) ->
  vim.rootWindow.BrowserStop()

commands.stop_all = ({ vim }) ->
  for tab in vim.rootWindow.gBrowser.visibleTabs
    window = tab.linkedBrowser.contentWindow
    window.stop()
  return



axisMap =
  x: ['left', 'scrollLeftMax', 'clientWidth',  'horizontalScrollDistance',  5]
  y: ['top',  'scrollTopMax',  'clientHeight', 'verticalScrollDistance',   20]

helper_scroll = (method, type, axis, amount, { vim, event, count }) ->
  frameDocument = event.target.ownerDocument
  element =
    if vim.state.scrollableElements.has(event.target)
      event.target
    else
      frameDocument.documentElement

  [ direction, max, dimension, distance, lineAmount ] = axisMap[axis]

  if method == 'scrollTo'
    amount = Math.min(amount, element[max])
  else
    unit = switch type
      when 'lines'
        prefs.root.get("toolkit.scrollbox.#{ distance }") * lineAmount
      when 'pages'
        element[dimension]
    amount *= unit * (count ? 1)

  options = {}
  options[direction] = amount
  if prefs.root.get('general.smoothScroll') and
     prefs.root.get("general.smoothScroll.#{ type }")
    options.behavior = 'smooth'

  prefs.root.tmp(
    'layout.css.scroll-behavior.spring-constant',
    vim.parent.options["smoothScroll.#{ type }.spring-constant"],
    ->
      element[method](options)
      # When scrolling the whole page, the body sometimes needs to be scrolled
      # too.
      if element == frameDocument.documentElement
        frameDocument.body?[method](options)
  )

scroll = Function::bind.bind(helper_scroll, null)

commands.scroll_left           = scroll('scrollBy', 'lines', 'x', -1)
commands.scroll_right          = scroll('scrollBy', 'lines', 'x', +1)
commands.scroll_down           = scroll('scrollBy', 'lines', 'y', +1)
commands.scroll_up             = scroll('scrollBy', 'lines', 'y', -1)
commands.scroll_page_down      = scroll('scrollBy', 'pages', 'y', +1)
commands.scroll_page_up        = scroll('scrollBy', 'pages', 'y', -1)
commands.scroll_half_page_down = scroll('scrollBy', 'pages', 'y', +0.5)
commands.scroll_half_page_up   = scroll('scrollBy', 'pages', 'y', -0.5)
commands.scroll_to_top         = scroll('scrollTo', 'other', 'y', 0)
commands.scroll_to_bottom      = scroll('scrollTo', 'other', 'y', Infinity)
commands.scroll_to_left        = scroll('scrollTo', 'other', 'x', 0)
commands.scroll_to_right       = scroll('scrollTo', 'other', 'x', Infinity)



commands.tab_new = ({ vim }) ->
  vim.rootWindow.BrowserOpenTab()

commands.tab_duplicate = ({ vim }) ->
  { gBrowser } = vim.rootWindow
  gBrowser.duplicateTab(gBrowser.selectedTab)

absoluteTabIndex = (relativeIndex, gBrowser) ->
  tabs = gBrowser.visibleTabs
  { selectedTab } = gBrowser

  currentIndex  = tabs.indexOf(selectedTab)
  absoluteIndex = currentIndex + relativeIndex
  numTabs       = tabs.length

  wrap = (Math.abs(relativeIndex) == 1)
  if wrap
    absoluteIndex %%= numTabs
  else
    absoluteIndex = Math.max(0, absoluteIndex)
    absoluteIndex = Math.min(absoluteIndex, numTabs - 1)

  return absoluteIndex

helper_switch_tab = (direction, { vim, count }) ->
  { gBrowser } = vim.rootWindow
  gBrowser.selectTabAtIndex(absoluteTabIndex(direction * (count ? 1), gBrowser))

commands.tab_select_previous = helper_switch_tab.bind(null, -1)

commands.tab_select_next     = helper_switch_tab.bind(null, +1)

helper_move_tab = (direction, { vim, count }) ->
  { gBrowser }    = vim.rootWindow
  { selectedTab } = gBrowser
  { pinned }      = selectedTab

  index = absoluteTabIndex(direction * (count ? 1), gBrowser)

  if index < gBrowser._numPinnedTabs
    gBrowser.pinTab(selectedTab) unless pinned
  else
    gBrowser.unpinTab(selectedTab) if pinned

  gBrowser.moveTabTo(selectedTab, index)

commands.tab_move_backward = helper_move_tab.bind(null, -1)

commands.tab_move_forward  = helper_move_tab.bind(null, +1)

commands.tab_select_first = ({ vim }) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(0)

commands.tab_select_first_non_pinned = ({ vim }) ->
  firstNonPinned = vim.rootWindow.gBrowser._numPinnedTabs
  vim.rootWindow.gBrowser.selectTabAtIndex(firstNonPinned)

commands.tab_select_last = ({ vim }) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(-1)

commands.tab_toggle_pinned = ({ vim }) ->
  currentTab = vim.rootWindow.gBrowser.selectedTab
  if currentTab.pinned
    vim.rootWindow.gBrowser.unpinTab(currentTab)
  else
    vim.rootWindow.gBrowser.pinTab(currentTab)

commands.tab_close = ({ vim, count }) ->
  { gBrowser } = vim.rootWindow
  return if gBrowser.selectedTab.pinned
  currentIndex = gBrowser.visibleTabs.indexOf(gBrowser.selectedTab)
  for tab in gBrowser.visibleTabs[currentIndex...(currentIndex + (count ? 1))]
    gBrowser.removeTab(tab)
  return

commands.tab_restore = ({ vim, count }) ->
  vim.rootWindow.undoCloseTab() for [1..count ? 1] by 1

commands.tab_close_to_end = ({ vim }) ->
  { gBrowser } = vim.rootWindow
  gBrowser.removeTabsToTheEndFrom(gBrowser.selectedTab)

commands.tab_close_other = ({ vim }) ->
  { gBrowser } = vim.rootWindow
  gBrowser.removeAllTabsBut(gBrowser.selectedTab)



# Combine links with the same href.
combine = (hrefs, marker) ->
  if marker.type == 'link'
    { href } = marker.element
    if href of hrefs
      parent = hrefs[href]
      marker.parent = parent
      parent.weight += marker.weight
      parent.numChildren++
    else
      hrefs[href] = marker
  return marker

follow_callback = (vim, { inTab, inBackground }, marker, count, keyStr) ->
  isLast = (count == 1)
  isLink = (marker.type == 'link')

  switch
    when keyStr.startsWith(vim.parent.options.hints_toggle_in_tab)
      inTab = not inTab
    when keyStr.startsWith(vim.parent.options.hints_toggle_in_background)
      inTab = true
      inBackground = not inBackground
    else
      unless isLast
        inTab = true
        inBackground = true

  inTab = false unless isLink

  if marker.type == 'text' or (isLink and not (inTab and inBackground))
    isLast = true

  { element } = marker
  utils.focusElement(element)

  if inTab
    utils.openTab(vim.rootWindow, element.href, {
      inBackground
      relatedToCurrent: true
    })
  else
    if element.target == '_blank' and vim.parent.options.prevent_target_blank
      targetReset = element.target
      element.target = ''
    utils.simulateClick(element)
    element.target = targetReset if targetReset

  return not isLast

# Follow links, focus text inputs and click buttons with hint markers.
commands.follow = ({ vim, count }) ->
  hrefs = {}
  filter = (element, getElementShape) ->
    document = element.ownerDocument
    isXUL = (document instanceof XULDocument)
    semantic = true
    switch
      when isProperLink(element)
        type = 'link'
      when isTextInputElement(element) or isContentEditable(element)
        type = 'text'
      when element.tabIndex > -1 and
           not (isXUL and element.nodeName.endsWith('box'))
        type = 'clickable'
        unless isXUL or element.nodeName in ['A', 'INPUT', 'BUTTON']
          semantic = false
      when element != document.documentElement and
           vim.state.scrollableElements.has(element)
        type = 'scrollable'
      when element.hasAttribute('onclick') or
           element.hasAttribute('onmousedown') or
           element.hasAttribute('onmouseup') or
           element.hasAttribute('oncommand') or
           element.getAttribute('role') in ['link', 'button'] or
           # Twitter special-case.
           element.classList.contains('js-new-tweets-bar') or
           # Feedly special-case.
           element.hasAttribute('data-app-action') or
           element.hasAttribute('data-uri') or
           element.hasAttribute('data-page-action')
        type = 'clickable'
        semantic = false
      # Putting markers on `<label>` elements is generally redundant, because
      # its `<input>` gets one. However, some sites hide the actual `<input>`
      # but keeps the `<label>` to click, either for styling purposes or to keep
      # the `<input>` hidden until it is used. In those cases we should add a
      # marker for the `<label>`.
      when element.nodeName == 'LABEL'
        if element.htmlFor
          input = document.getElementById(element.htmlFor)
          if input and not getElementShape(input)
            type = 'clickable'
      # Elements that have “button” somewhere in the class might be clickable,
      # unless they contain a real link or button or yet an element with
      # “button” somewhere in the class, in which case they likely are
      # “button-wrapper”s. (`<SVG element>.className` is not a string!)
      when not isXUL and typeof element.className == 'string' and
           element.className.toLowerCase().contains('button')
        unless element.querySelector('a, button, [class*=button]')
          type = 'clickable'
          semantic = false
      # When viewing an image it should get a marker to toggle zoom.
      when document.body?.childElementCount == 1 and
           element.nodeName == 'IMG' and
           (element.classList.contains('overflowing') or
            element.classList.contains('shrinkToFit'))
        type = 'clickable'
    return unless type
    return unless shape = getElementShape(element)
    return combine(hrefs, new Marker(element, shape, {semantic, type}))

  callback = follow_callback.bind(null, vim, {inTab: false, inBackground: true})

  vim.enterMode('hints', filter, callback, count)

# Follow links in a new background tab with hint markers.
commands.follow_in_tab = ({ vim, count }, inBackground = true) ->
  hrefs = {}
  filter = (element, getElementShape) ->
    return unless isProperLink(element)
    return unless shape = getElementShape(element)
    return combine(hrefs, new Marker(element, shape,
                                     {semantic: true, type: 'link'}))

  callback = follow_callback.bind(null, vim, {inTab: true, inBackground})

  vim.enterMode('hints', filter, callback, count)

# Follow links in a new foreground tab with hint markers.
commands.follow_in_focused_tab = (args) ->
  commands.follow_in_tab(args, false)

# Like command_follow but multiple times.
commands.follow_multiple = (args) ->
  args.count = Infinity
  commands.follow(args)

# Copy the URL or text of a markable element to the system clipboard.
commands.follow_copy = ({ vim }) ->
  hrefs = {}
  filter = (element, getElementShape) ->
    type = switch
      when isProperLink(element)       then 'link'
      when isTextInputElement(element) then 'textInput'
      when isContentEditable(element)  then 'contenteditable'
    return unless type
    return unless shape = getElementShape(element)
    return combine(hrefs, new Marker(element, shape, {semantic: true, type}))

  callback = (marker) ->
    { element } = marker
    text = switch marker.type
      when 'link'            then element.href
      when 'textInput'       then element.value
      when 'contenteditable' then element.textContent
    utils.writeToClipboard(text)

  vim.enterMode('hints', filter, callback)

# Focus element with hint markers.
commands.follow_focus = ({ vim }) ->
  filter = (element, getElementShape) ->
    type = switch
      when element.tabIndex > -1
        'focusable'
      when element != element.ownerDocument.documentElement and
           vim.state.scrollableElements.has(element)
        'scrollable'
    return unless type
    return unless shape = getElementShape(element)
    return new Marker(element, shape, {semantic: true, type})

  callback = (marker) ->
    { element } = marker
    utils.focusElement(element, {select: true})

  vim.enterMode('hints', filter, callback)

helper_follow_pattern = (type, { vim }) ->
  { document } = vim.window

  # If there’s a `<link rel=prev/next>` element we use that.
  for link in document.head?.getElementsByTagName('link')
    # Also support `rel=previous`, just like Google.
    if type == link.rel.toLowerCase().replace(/^previous$/, 'prev')
      vim.rootWindow.gBrowser.loadURI(link.href)
      return

  # Otherwise we look for a link or button on the page that seems to go to the
  # previous or next page.
  candidates = document.querySelectorAll(vim.parent.options.pattern_selector)

  # Note: Earlier patterns should be favored.
  patterns = vim.parent.options["#{ type }_patterns"]

  # Search for the prev/next patterns in the following attributes of the
  # element. `rel` should be kept as the first attribute, since the standard way
  # of marking up prev/next links (`rel="prev"` and `rel="next"`) should be
  # favored. Even though some of these attributes only allow a fixed set of
  # keywords, we pattern-match them anyways since lots of sites don’t follow the
  # spec and use the attributes arbitrarily.
  attrs = vim.parent.options.pattern_attrs

  matchingLink = do ->
    # Helper function that matches a string against all the patterns.
    matches = (text) -> patterns.some((regex) -> regex.test(text))

    # First search in attributes (favoring earlier attributes) as it's likely
    # that they are more specific than text contexts.
    for attr in attrs
      for element in candidates
        return element if matches(element.getAttribute(attr))

    # Then search in element contents.
    for element in candidates
      return element if matches(element.textContent)

    return null

  utils.simulateClick(matchingLink) if matchingLink

commands.follow_previous = helper_follow_pattern.bind(null, 'prev')

commands.follow_next     = helper_follow_pattern.bind(null, 'next')

# Focus last focused or first text input.
commands.focus_text_input = ({ vim, storage, count }) ->
  { lastFocusedTextInput } = vim.state
  inputs = Array.filter(
    vim.window.document.querySelectorAll('input, textarea'), (element) ->
      return utils.isTextInputElement(element) and utils.area(element) > 0
  )
  if lastFocusedTextInput and lastFocusedTextInput not in inputs
    inputs.push(lastFocusedTextInput)
  return unless inputs.length > 0
  inputs.sort((a, b) -> a.tabIndex - b.tabIndex)
  unless count?
    count =
      if lastFocusedTextInput
        inputs.indexOf(lastFocusedTextInput) + 1
      else
        1
  index = Math.min(count, inputs.length) - 1
  utils.focusElement(inputs[index], {select: true})
  storage.inputs = inputs

# Switch between text inputs or simulate `<tab>`.
helper_move_focus = (direction, { vim, storage }) ->
  if storage.inputs
    { inputs } = storage
    nextInput = inputs[(storage.inputIndex + direction) %% inputs.length]
    utils.focusElement(nextInput, {select: true})
  else
    focusManager = Cc['@mozilla.org/focus-manager;1']
      .getService(Ci.nsIFocusManager)
    direction =
      if direction == -1
        focusManager.MOVEFOCUS_BACKWARD
      else
        focusManager.MOVEFOCUS_FORWARD
    focusManager.moveFocus(
      null, # Use current window.
      null, # Move relative to the currently focused element.
      direction,
      focusManager.FLAG_BYKEY
    )

commands.focus_next     = helper_move_focus.bind(null, +1)
commands.focus_previous = helper_move_focus.bind(null, -1)



findStorage = {lastSearchString: ''}

helper_find = (highlight, { vim }) ->
  findBar = vim.rootWindow.gBrowser.getFindBar()

  findBar.onFindCommand()
  utils.focusElement(findBar._findField, {select: true})

  return unless highlightButton = findBar.getElement('highlight')
  if highlightButton.checked != highlight
    highlightButton.click()

# Open the find bar, making sure that hightlighting is off.
commands.find = helper_find.bind(null, false)

# Open the find bar, making sure that hightlighting is on.
commands.find_highlight_all = helper_find.bind(null, true)

helper_find_again = (direction, { vim }) ->
  findBar = vim.rootWindow.gBrowser.getFindBar()
  if findStorage.lastSearchString.length > 0
    findBar._findField.value = findStorage.lastSearchString
    findBar.onFindAgainCommand(direction)

commands.find_next     = helper_find_again.bind(null, false)

commands.find_previous = helper_find_again.bind(null, true)



commands.enter_mode_ignore = ({ vim }) ->
  vim.enterMode('ignore')

# Quote next keypress (pass it through to the page).
commands.quote = ({ vim, count }) ->
  vim.enterMode('ignore', count ? 1)

# Display the Help Dialog.
commands.help = ({ vim }) ->
  help.injectHelp(vim.rootWindow, vim.parent)

# Open and focus the Developer Toolbar.
commands.dev = ({ vim }) ->
  vim.rootWindow.DeveloperToolbar.show(true) # `true` to focus.

commands.esc = ({ vim, event }) ->
  utils.blurActiveElement(vim.window)

  # Blur active XUL control.
  callback = -> event.originalTarget?.ownerDocument?.activeElement?.blur()
  vim.window.setTimeout(callback, 0)

  help.removeHelp(vim.rootWindow)

  vim.rootWindow.DeveloperToolbar.hide()

  vim.rootWindow.gBrowser.getFindBar().close()

  vim.rootWindow.TabView.hide()

  { document } = vim.window
  if document.exitFullscreen
    document.exitFullscreen()
  else
    document.mozCancelFullScreen()



module.exports = {
  commands
  findStorage
}
