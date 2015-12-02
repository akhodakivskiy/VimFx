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

# This file creates VimFx’s Keyboard Shortcuts help screen.

translate = require('./l10n')
utils     = require('./utils')

CONTAINER_ID  = 'VimFxHelpDialogContainer'
MAX_FONT_SIZE = 20
SEARCH_MATCH_CLASS     = 'search-match'
SEARCH_NON_MATCH_CLASS = 'search-non-match'
SEARCH_HIGHLIGHT_CLASS = 'search-highlight'

injectHelp = (window, vimfx) ->
  removeHelp(window)

  {document} = window

  container = utils.createBox(document)
  container.id = CONTAINER_ID

  wrapper = utils.createBox(document, 'wrapper', container)

  header = createHeader(document, vimfx)
  wrapper.appendChild(header)

  content = createContent(document, vimfx)
  wrapper.appendChild(content)

  searchInput = document.createElement('textbox')
  utils.setAttributes(searchInput, {
    class: 'search-input'
    placeholder: translate('help.search')
  })
  searchInput.oninput = -> search(content, searchInput.value.trimLeft())
  container.appendChild(searchInput)

  window.gBrowser.mCurrentBrowser.parentNode.appendChild(container)
  searchInput.focus()

  # The font size of menu items is used by default, which is usually quite
  # small. Try to increase it without causing a scrollbar.
  computedStyle = window.getComputedStyle(container)
  fontSize = originalFontSize =
    parseFloat(computedStyle.getPropertyValue('font-size'))
  while container.scrollTopMax == 0 and fontSize <= MAX_FONT_SIZE
    fontSize++
    container.style.fontSize = "#{fontSize}px"
  container.style.fontSize = "#{Math.max(fontSize - 1, originalFontSize)}px"

  # Uncomment this line if you want to use `gulp help.html`!
  # utils.writeToClipboard(container.outerHTML)

removeHelp = (window) ->
  window.document.getElementById(CONTAINER_ID)?.remove()

createHeader = (document, vimfx) ->
  $ = utils.createBox.bind(null, document)

  header = $('header')

  mainHeading = $('heading-main', header)
  $('logo',  mainHeading) # Content is added by CSS.
  $('title', mainHeading, translate('help.title'))

  closeButton = $('close-button', header, '×')
  closeButton.onclick = removeHelp.bind(null, document.ownerGlobal)

  return header

createContent = (document, vimfx) ->
  $ = utils.createBox.bind(null, document)

  content = $('content')

  for mode in vimfx.getGroupedCommands({enabledOnly: true})
    modeHeading = $('heading-mode search-item', null, mode.name)

    for category, index in mode.categories
      categoryContainer = $('category', content)
      # `data-` attributes are currently unused by VimFx, but provide a great
      # way to customize the help dialog with custom CSS.
      utils.setAttributes(categoryContainer, {
        'data-mode':     mode._name
        'data-category': category._name
      })

      # Append the mode heading inside the first category container, rather than
      # before it, for layout purposes.
      if index == 0
        categoryContainer.appendChild(modeHeading)
        categoryContainer.classList.add('first')

      if category.name
        $('heading-category search-item', categoryContainer, category.name)

      for {command, name, enabledSequences} in category.commands
        commandContainer = $('command search-item', categoryContainer)
        utils.setAttributes(commandContainer, {'data-command': command.name})
        commandContainer.setAttribute('data-command', name)
        for sequence in enabledSequences
          keySequence = $('key-sequence', commandContainer)
          [specialKeys, rest] = splitSequence(sequence, vimfx.SPECIAL_KEYS)
          $('key-sequence-special-keys', keySequence, specialKeys)
          $('key-sequence-rest search-text', keySequence, rest)
        $('description search-text', commandContainer, command.description())

  return content

splitSequence = (sequence, specialKeys) ->
  specialKeyEnds = specialKeys.map((key) ->
    pos = sequence.lastIndexOf(key)
    return if pos == -1 then 0 else pos + key.length
  )
  splitPos = Math.max(specialKeyEnds...)
  return [sequence[0...splitPos], sequence[splitPos..]]

search = (content, term) ->
  document   = content.ownerDocument
  ignoreCase = (term == term.toLowerCase())
  regex = RegExp("(#{utils.regexEscape(term)})", if ignoreCase then 'i' else '')
  clear = (term == '')

  for item in content.querySelectorAll('.search-item')
    texts = item.querySelectorAll('.search-text')
    texts = [item] if texts.length == 0
    className = SEARCH_NON_MATCH_CLASS

    for element in texts
      {textContent} = element
      # Clear the previous highlighting. This is possible to do for non-matches
      # as well, but too slow.
      if item.classList.contains(SEARCH_MATCH_CLASS)
        element.textContent = textContent

      continue if clear or not regex.test(textContent)

      className = SEARCH_MATCH_CLASS
      element.textContent = '' # Empty the element.
      for part, index in textContent.split(regex)
        # Even indices are surrounding text, odd ones are matches.
        if index % 2 == 0
          element.appendChild(document.createTextNode(part))
        else
          utils.createBox(document, SEARCH_HIGHLIGHT_CLASS, element, part)

    item.classList.remove(SEARCH_MATCH_CLASS, SEARCH_NON_MATCH_CLASS)
    item.classList.add(className) unless clear

  return

module.exports = {
  injectHelp
  removeHelp
}
