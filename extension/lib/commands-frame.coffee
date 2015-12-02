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

# This file is the equivalent to commands.coffee, but for frame scripts,
# allowing interaction with web page content. Most “commands” here have the
# same name as the command in commands.coffee that calls it. There are also a
# few more generalized “commands” used in more than one place.

hints     = require('./hints')
translate = require('./l10n')
utils     = require('./utils')

{isProperLink, isTextInputElement, isTypingElement, isContentEditable} = utils

XULDocument = Ci.nsIDOMXULDocument

commands = {}

commands.go_up_path = ({vim, count = 1}) ->
  vim.content.location.pathname = vim.content.location.pathname.replace(
    /// (?: /[^/]+ ){1,#{count}} /?$ ///, ''
  )

commands.go_to_root = ({vim}) ->
  vim.content.location.href = vim.content.location.origin

helper_scroll = (element, args) ->
  {method, type, directions, amounts, properties, smooth} = args
  options = {}
  for direction, index in directions
    amount = amounts[index]
    options[direction] = switch type
      when 'lines' then amount
      when 'pages' then amount * element[properties[index]]
      when 'other' then Math.min(amount, element[properties[index]])
  options.behavior = 'smooth' if smooth
  element[method](options)

commands.scroll = (args) ->
  {vim} = args
  activeElement = utils.getActiveElement(vim.content)
  element =
    if vim.state.scrollableElements.has(activeElement)
      activeElement
    else
      vim.state.scrollableElements.filterSuitableDefault()
  helper_scroll(element, args)

commands.mark_scroll_position = ({vim, keyStr, notify = true}) ->
  element = vim.state.scrollableElements.filterSuitableDefault()
  vim.state.marks[keyStr] = [element.scrollTop, element.scrollLeft]
  vim.notify(translate('mark_scroll_position.success', keyStr)) if notify

commands.scroll_to_mark = (args) ->
  {vim, amounts: keyStr} = args
  unless keyStr of vim.state.marks
    vim.notify(translate('scroll_to_mark.error', keyStr))
    return

  args.amounts = vim.state.marks[keyStr]
  element = vim.state.scrollableElements.filterSuitableDefault()
  helper_scroll(element, args)

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

    length = vim.state.markerElements.push(element)
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
         not element.hasAttribute('onclick')
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
      when isProperLink(element)
        type = 'link'
      when isTypingElement(element) or isContentEditable(element)
        type = 'text'
      when element.tabIndex > -1 and
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
           element.getAttribute('role') in ['link', 'button'] or
           # Twitter special-case.
           element.classList.contains('js-new-tweets-bar') or
           # Feedly special-case.
           element.hasAttribute('data-app-action') or
           element.hasAttribute('data-uri') or
           element.hasAttribute('data-page-action')
        type = 'clickable'
        semantic = false
      # Facebook special-case (comment fields).
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
      # Elements that have “button” somewhere in the class might be clickable,
      # unless they contain a real link or button or yet an element with
      # “button” somewhere in the class, in which case they likely are
      # “button-wrapper”s. (`<SVG element>.className` is not a string!)
      when not isXUL and typeof element.className == 'string' and
           element.className.toLowerCase().includes('button')
        unless element.querySelector('a, button, [class*=button]')
          type = 'clickable'
          semantic = false
      # When viewing an image it should get a marker to toggle zoom.
      when document.body?.childElementCount == 1 and
           element.nodeName == 'IMG' and
           (element.classList.contains('overflowing') or
            element.classList.contains('shrinkToFit'))
        type = 'clickable'
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
      when isTypingElement(element)   then 'text'
      when isContentEditable(element) then 'contenteditable'
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
  element = vim.state.markerElements[elementIndex]
  utils.focusElement(element, options)

commands.click_marker_element = (args) ->
  {vim, elementIndex, type, preventTargetBlank} = args
  element = vim.state.markerElements[elementIndex]
  if element.target == '_blank' and preventTargetBlank
    targetReset = element.target
    element.target = ''
  if type == 'clickable-special'
    element.click()
  else
    utils.simulateClick(element)
  element.target = targetReset if targetReset

commands.copy_marker_element = ({vim, elementIndex, property}) ->
  element = vim.state.markerElements[elementIndex]
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

  utils.simulateClick(matchingLink) if matchingLink

commands.focus_text_input = ({vim, count = null}) ->
  {lastFocusedTextInput} = vim.state
  inputs = Array.filter(
    utils.querySelectorAllDeep(vim.content, 'input, textarea'), (element) ->
      return isTextInputElement(element) and utils.area(element) > 0
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
  commands.blur_active_element(args)

  {document} = args.vim.content
  if document.exitFullscreen
    document.exitFullscreen()
  else
    document.mozCancelFullScreen()

commands.blur_active_element = ({vim}) ->
  utils.blurActiveElement(vim.content)

module.exports = commands
