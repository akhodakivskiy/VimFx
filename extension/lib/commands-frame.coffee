###
# Copyright Simon Lydell 2015, 2016.
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

# This file is the equivalent to commands.coffee, but for frame scripts,
# allowing interaction with web page content. Most “commands” here have the
# same name as the command in commands.coffee that calls it. There are also a
# few more generalized “commands” used in more than one place.

hints     = require('./hints')
translate = require('./l10n')
utils     = require('./utils')

{isProperLink, isTextInputElement, isTypingElement, isContentEditable} = utils

XULDocument = Ci.nsIDOMXULDocument

# <http://www.w3.org/html/wg/drafts/html/master/dom.html#wai-aria>
CLICKABLE_ARIA_ROLES = [
  'link', 'button', 'tab'
  'checkbox', 'radio', 'combobox', 'option', 'slider', 'textbox'
  'menuitem', 'menuitemcheckbox', 'menuitemradio'
]

commands = {}

commands.go_up_path = ({vim, count = 1}) ->
  {pathname}  = vim.content.location
  newPathname = pathname.replace(/// (?: /[^/]+ ){1,#{count}} /?$ ///, '')
  if newPathname == pathname
    vim.notify(translate('notification.go_up_path.limit'))
  else
    vim.content.location.pathname = newPathname

commands.go_to_root = ({vim}) ->
  # `.origin` is `'null'` (as a string) on `about:` pages.
  if "#{vim.content.location.origin}/" in [vim.content.location.href, 'null/']
    vim.notify(translate('notification.go_up_path.limit'))
  else
    vim.content.location.href = vim.content.location.origin

commands.scroll = (args) ->
  {vim} = args
  return unless activeElement = utils.getActiveElement(vim.content)
  element =
    # If no element is focused on the page, the the active element is the
    # topmost `<body>`, and blurring it is a no-op. If it is scrollable, it
    # means that you can’t blur it in order to scroll `<html>`. Therefore it may
    # only be scrolled if it has been explicitly focused.
    if vim.state.scrollableElements.has(activeElement) and
       (activeElement != vim.content.document.body or
        vim.state.explicitBodyFocus)
      activeElement
    else
      vim.state.scrollableElements.filterSuitableDefault()
  utils.scroll(element, args)

commands.mark_scroll_position = ({vim, keyStr, notify = true}) ->
  element = vim.state.scrollableElements.filterSuitableDefault()
  vim.state.marks[keyStr] = [element.scrollTop, element.scrollLeft]
  if notify
    vim.notify(translate('notification.mark_scroll_position.success', keyStr))

commands.scroll_to_mark = (args) ->
  {vim, amounts: keyStr} = args
  unless keyStr of vim.state.marks
    vim.notify(translate('notification.scroll_to_mark.none', keyStr))
    return

  args.amounts = vim.state.marks[keyStr]
  element = vim.state.scrollableElements.filterSuitableDefault()
  utils.scroll(element, args)

helper_follow = ({id, combine = true}, matcher, {vim}) ->
  hrefs = {}
  vim.state.markerElements = []

  filter = (element, getElementShape) ->
    {type, semantic} = matcher({vim, element, getElementShape})

    customMatcher = FRAME_SCRIPT_ENVIRONMENT.VimFxHintMatcher
    if customMatcher
      {type, semantic} = customMatcher(id, element, {type, semantic})

    return unless type
    return unless shape = getElementShape(element)

    originalRect = element.getBoundingClientRect()
    length = vim.state.markerElements.push({element, originalRect})
    wrapper = {type, semantic, shape, elementIndex: length - 1}

    if wrapper.type == 'link'
      {href} = element
      wrapper.href = href

      # Combine links with the same href.
      if combine and wrapper.type == 'link' and
         # If the element has an 'onclick' attribute we cannot be sure that all
         # links with this href actually do the same thing. On some pages, such
         # as startpage.com, actual proper links have the 'onclick' attribute,
         # so we can’t exclude such links in `utils.isProperLink`.
         not element.hasAttribute('onclick') and
         # GitHub’s diff expansion buttons are links with both `href` and
         # `data-url`. They are JavaScript-powered using the latter attribute.
         not element.hasAttribute('data-url')
        if href of hrefs
          parent = hrefs[href]
          wrapper.parentIndex = parent.elementIndex
          parent.shape.area += wrapper.shape.area
          parent.numChildren++
        else
          wrapper.numChildren = 0
          hrefs[href] = wrapper

    return wrapper

  return hints.getMarkableElementsAndViewport(vim.content, filter)

commands.follow = helper_follow.bind(null, {id: 'normal'},
  ({vim, element, getElementShape}) ->
    document = element.ownerDocument
    isXUL = (document instanceof XULDocument)
    type = null
    semantic = true
    switch
      # Bootstrap. Match these before regular links, because especially slider
      # “buttons” often get the same hint otherwise.
      when element.hasAttribute('data-toggle') or
           element.hasAttribute('data-dismiss') or
           element.hasAttribute('data-slide') or
           element.hasAttribute('data-slide-to')
        # Some elements may not be semantic, but _should be_ and still deserve a
        # good hint.
        type = 'clickable'
      when isProperLink(element)
        type = 'link'
      when isTypingElement(element)
        type = 'text'
      when element.getAttribute('role') in CLICKABLE_ARIA_ROLES or
           # <http://www.w3.org/TR/wai-aria/states_and_properties>
           element.hasAttribute('aria-controls') or
           element.hasAttribute('aria-pressed') or
           element.hasAttribute('aria-checked') or
           (element.hasAttribute('aria-haspopup') and
            element.getAttribute('role') != 'menu')
        type = 'clickable'
      when element.tabIndex > -1 and
           # Google Drive Documents. The hint for this element would cover the
           # real hint that allows you to focus the document to start typing.
           element.id != 'docs-editor' and
           not (isXUL and element.nodeName.endsWith('box') and
                element.nodeName != 'checkbox')
        type = 'clickable'
        unless isXUL or element.nodeName in ['A', 'INPUT', 'BUTTON']
          semantic = false
      when element != vim.state.scrollableElements.largest and
           vim.state.scrollableElements.has(element)
        type = 'scrollable'
      when element.hasAttribute('onclick') or
           element.hasAttribute('onmousedown') or
           element.hasAttribute('onmouseup') or
           element.hasAttribute('oncommand') or
           # Twitter.
           element.classList.contains('js-new-tweets-bar') or
           # Feedly.
           element.hasAttribute('data-app-action') or
           element.hasAttribute('data-uri') or
           element.hasAttribute('data-page-action') or
           # CodeMirror.
           element.classList.contains('CodeMirror-scroll') or
           # Google Drive Document.
           element.classList.contains('kix-appview-editor')
        type = 'clickable'
        semantic = false
      # Facebook comment fields.
      when element.parentElement?.classList.contains('UFIInputContainer')
        type = 'clickable-special'
      # Putting markers on `<label>` elements is generally redundant, because
      # its `<input>` gets one. However, some sites hide the actual `<input>`
      # but keeps the `<label>` to click, either for styling purposes or to keep
      # the `<input>` hidden until it is used. In those cases we should add a
      # marker for the `<label>`.
      when element.nodeName == 'LABEL'
        input =
          if element.htmlFor
            document.getElementById(element.htmlFor)
          else
            element.querySelector('input, textarea, select')
        if input and not getElementShape(input)
          type = 'clickable'
      # Last resort checks for elements that might be clickable because of
      # JavaScript.
      when (not isXUL and
            # It is common to listen for clicks on `<html>` or `<body>`. Don’t
            # waste time on them.
            element not in [document.documentElement, document.body]) and
           (utils.includes(element.className, 'button') or
            utils.includes(element.getAttribute('aria-label'), 'close') or
            # Do this last as it’s a potentially expensive check.
            utils.hasEventListeners(element, 'click'))
        # Make a quick check for likely clickable descendants, to reduce the
        # number of false positives. the element might be a “button-wrapper” or
        # a large element with a click-tracking event listener.
        unless element.querySelector('a, button, input, [class*=button]')
          type = 'clickable'
          semantic = false
      # When viewing an image it should get a marker to toggle zoom. This is the
      # most unlikely rule to match, so keep it last.
      when document.body?.childElementCount == 1 and
           element.nodeName == 'IMG' and
           (element.classList.contains('overflowing') or
            element.classList.contains('shrinkToFit'))
        type = 'clickable'
    type = null if isXUL and element.classList.contains('textbox-input')
    return {type, semantic}
)

commands.follow_in_tab = helper_follow.bind(null, {id: 'tab'},
  ({element}) ->
    type = if isProperLink(element) then 'link' else null
    return {type, semantic: true}
)

commands.follow_copy = helper_follow.bind(null, {id: 'copy'},
  ({element}) ->
    type = switch
      when isProperLink(element)      then 'link'
      when isContentEditable(element) then 'contenteditable'
      when isTypingElement(element)   then 'text'
      else null
    return {type, semantic: true}
)

commands.follow_focus = helper_follow.bind(null, {id: 'focus', combine: false},
  ({vim, element}) ->
    type = switch
      when element.tabIndex > -1
        'focusable'
      when element != vim.state.scrollableElements.largest and
           vim.state.scrollableElements.has(element)
        'scrollable'
      else
        null
    return {type, semantic: true}
)

commands.focus_marker_element = ({vim, elementIndex, options}) ->
  {element} = vim.state.markerElements[elementIndex]
  # To be able to focus scrollable elements, `FLAG_BYKEY` _has_ to be used.
  options.flag = 'FLAG_BYKEY' if vim.state.scrollableElements.has(element)
  utils.focusElement(element, options)
  vim.clearHover()
  vim.setHover(element)

commands.click_marker_element = (args) ->
  {vim, elementIndex, type, preventTargetBlank} = args
  {element} = vim.state.markerElements[elementIndex]
  if element.target == '_blank' and preventTargetBlank
    targetReset = element.target
    element.target = ''
  if type == 'clickable-special'
    element.click()
  else
    utils.simulateMouseEvents(element, 'click')
  element.target = targetReset if targetReset

commands.copy_marker_element = ({vim, elementIndex, property}) ->
  {element} = vim.state.markerElements[elementIndex]
  utils.writeToClipboard(element[property])

commands.follow_pattern = ({vim, type, options}) ->
  {document} = vim.content

  # If there’s a `<link rel=prev/next>` element we use that.
  for link in document.head?.getElementsByTagName('link')
    # Also support `rel=previous`, just like Google.
    if type == link.rel.toLowerCase().replace(/^previous$/, 'prev')
      vim.content.location.href = link.href
      return

  # Otherwise we look for a link or button on the page that seems to go to the
  # previous or next page.
  candidates = document.querySelectorAll(options.pattern_selector)

  # Note: Earlier patterns should be favored.
  {patterns} = options

  # Search for the prev/next patterns in the following attributes of the
  # element. `rel` should be kept as the first attribute, since the standard way
  # of marking up prev/next links (`rel="prev"` and `rel="next"`) should be
  # favored. Even though some of these attributes only allow a fixed set of
  # keywords, we pattern-match them anyways since lots of sites don’t follow the
  # spec and use the attributes arbitrarily.
  attrs = options.pattern_attrs

  matchingLink = do ->
    # First search in attributes (favoring earlier attributes) as it's likely
    # that they are more specific than text contexts.
    for attr in attrs
      for regex in patterns
        for element in candidates
          return element if regex.test(element.getAttribute(attr))

    # Then search in element contents.
    for regex in patterns
      for element in candidates
        return element if regex.test(element.textContent)

    return null

  if matchingLink
    utils.simulateMouseEvents(matchingLink, 'click')
    # When you go to the next page of GitHub’s code search results, the page is
    # loaded with AJAX. GitHub then annoyingly focuses its search input. This
    # autofocus cannot be prevented in a reliable way, because the case is
    # indistinguishable from a button whose job is to focus some text input.
    # However, in this command we know for sure that we can prevent the next
    # focus. This must be done _after_ the click has been triggered, since
    # clicks count as page interactions.
    vim.markPageInteraction(false)
  else
    vim.notify(translate("notification.follow_#{type}.none"))

commands.focus_text_input = ({vim, count = null}) ->
  {lastFocusedTextInput} = vim.state
  candidates = utils.querySelectorAllDeep(
    vim.content, 'input, textarea, [contenteditable]'
  )
  inputs = Array.filter(candidates, (element) ->
    return isTextInputElement(element) and utils.area(element) > 0
  )
  if lastFocusedTextInput and lastFocusedTextInput not in inputs
    inputs.push(lastFocusedTextInput)
  inputs.sort((a, b) -> a.tabIndex - b.tabIndex)

  if inputs.length == 0
    vim.notify(translate('notification.focus_text_input.none'))
    return

  num = switch
    when count?
      count
    when lastFocusedTextInput
      inputs.indexOf(lastFocusedTextInput) + 1
    else
      1
  index = Math.min(num, inputs.length) - 1
  select = (count? or not vim.state.hasFocusedTextInput)
  utils.focusElement(inputs[index], {select})
  vim.state.inputs = inputs

commands.clear_inputs = ({vim}) ->
  vim.state.inputs = null

commands.move_focus = ({vim, direction}) ->
  return false unless vim.state.inputs
  index = vim.state.inputs.indexOf(utils.getActiveElement(vim.content))
  # If there’s only one input, `<tab>` would cycle to itself, making it feel
  # like `<tab>` was not working. Then it’s better to let `<tab>` work as it
  # usually does.
  if index == -1 or vim.state.inputs.length <= 1
    vim.state.inputs = null
    return false
  else
    {inputs} = vim.state
    nextInput = inputs[(index + direction) %% inputs.length]
    utils.focusElement(nextInput, {select: true})
    return true

commands.esc = (args) ->
  {vim} = args
  commands.blur_active_element(args)
  vim.clearHover()

  {document} = vim.content
  if document.exitFullscreen
    document.exitFullscreen()
  else
    document.mozCancelFullScreen()

commands.blur_active_element = ({vim}) ->
  vim.state.explicitBodyFocus = false
  utils.blurActiveElement(vim.content)

module.exports = commands
