# This file creates VimFx’s Keyboard Shortcuts help screen.

translate = require('./translate')
utils = require('./utils')

CONTAINER_ID = 'VimFxHelpDialogContainer'
MAX_FONT_SIZE = 20
SEARCH_MATCH_CLASS = 'search-match'
SEARCH_NON_MATCH_CLASS = 'search-non-match'
SEARCH_HIGHLIGHT_CLASS = 'search-highlight'

injectHelp = (window, vimfx) ->
  removeHelp(window)

  {document} = window

  container = utils.createBox(document)
  container.id = CONTAINER_ID

  wrapper = utils.createBox(document, 'wrapper', container)

  header = createHeader(window, vimfx)
  wrapper.appendChild(header)

  content = createContent(window, vimfx)
  wrapper.appendChild(content)

  searchInput = document.createElement('textbox')
  utils.setAttributes(searchInput, {
    class: 'search-input'
    placeholder: translate('help.search')
  })
  searchInput.oninput = -> search(content, searchInput.value.trimLeft())
  searchInput.onkeydown = (event) -> searchInput.blur() if event.key == 'Enter'
  container.appendChild(searchInput)

  window.gBrowser.selectedBrowser.parentNode.appendChild(container)

  # The font size of menu items is used by default, which is usually quite
  # small. Try to increase it without causing a scrollbar.
  computedStyle = window.getComputedStyle(container)
  fontSize = originalFontSize =
    parseFloat(computedStyle.getPropertyValue('font-size'))
  while wrapper.scrollTopMax == 0 and fontSize <= MAX_FONT_SIZE
    fontSize += 1
    container.style.fontSize = "#{fontSize}px"
  container.style.fontSize = "#{Math.max(fontSize - 1, originalFontSize)}px"

  # Uncomment this line if you want to use `gulp help.html`!
  # utils.writeToClipboard(container.outerHTML)

removeHelp = (window) -> getHelp(window)?.remove()

toggleHelp = (window, vimfx) ->
  helpContainer = getHelp(window)
  if helpContainer
    helpContainer.remove()
  else
    injectHelp(window, vimfx)

getHelp = (window) -> window.document.getElementById(CONTAINER_ID)

getSearchInput = (window) -> getHelp(window)?.querySelector('.search-input')

createHeader = (window, vimfx) ->
  $ = utils.createBox.bind(null, window.document)

  header = $('header')

  mainHeading = $('heading-main', header)
  $('logo',  mainHeading) # Content is added by CSS.
  $('title', mainHeading, translate('help.title'))

  closeButton = $('close-button', header, '×')
  closeButton.onclick = -> removeHelp(window)

  return header

createContent = (window, vimfx) ->
  $ = utils.createBox.bind(null, window.document)
  extraCommands = getExtraCommands(vimfx)

  content = $('content')

  for mode in vimfx.getGroupedCommands({enabledOnly: true})
    modeHeading = $('heading-mode search-item', null, mode.name)

    for category, index in mode.categories
      categoryContainer = $('category', content)
      utils.setAttributes(categoryContainer, {
        'data-mode': mode._name
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
        commandContainer = $('command has-click search-item', categoryContainer)
        commandContainer.setAttribute('data-command', name)
        commandContainer.onclick = goToCommandSetting.bind(
          null, window, vimfx, command
        )
        for sequence in enabledSequences
          keySequence = $('key-sequence', commandContainer)
          [specialKeys, rest] =
            splitSequence(sequence, Object.keys(vimfx.SPECIAL_KEYS))
          $('key-sequence-special-keys', keySequence, specialKeys)
          $('key-sequence-rest search-text', keySequence, rest)
        $('description search-text', commandContainer, command.description)

      categoryExtraCommands = extraCommands[mode._name]?[category._name]
      if categoryExtraCommands
        for name, sequences of categoryExtraCommands when sequences.length > 0
          commandContainer = $('command search-item', categoryContainer)
          commandContainer.setAttribute('data-command', name)
          for sequence in sequences
            keySequence = $('key-sequence', commandContainer)
            $('key-sequence-rest search-text', keySequence, sequence)
          description = translate("mode.#{mode._name}.#{name}")
          $('description search-text', commandContainer, description)

  return content

getExtraCommands = (vimfx) ->
  lastHintChar = translate('help.last_hint_char')
  return {
    'hints': {
      '': {
        'peek_through':
          if vimfx.options['hints.peek_through']
            [vimfx.options['hints.peek_through']]
          else
            []
        'toggle_in_tab':
          if vimfx.options['hints.toggle_in_tab']
            ["#{vimfx.options['hints.toggle_in_tab']}#{lastHintChar}>"]
          else
            []
        'toggle_in_background':
          if vimfx.options['hints.toggle_in_background']
            ["#{vimfx.options['hints.toggle_in_background']}#{lastHintChar}>"]
          else
            []
      }
    }
  }

splitSequence = (sequence, specialKeys) ->
  specialKeyEnds = specialKeys.map((key) ->
    pos = sequence.lastIndexOf(key)
    return if pos == -1 then 0 else pos + key.length
  )
  splitPos = Math.max(specialKeyEnds...)
  return [sequence[0...splitPos], sequence[splitPos..]]

goToCommandSetting = (window, vimfx, command) ->
  vimfx.goToCommand = command
  removeHelp(window)
  uri = "#{ADDON_PATH}/content/options.xhtml"
  utils.nextTick(window, ->
    window.gBrowser.selectedTab = window.gBrowser.addTab(uri, {
      triggeringPrincipal: Services.scriptSecurityManager.getSystemPrincipal()
    })
  )

search = (content, term) ->
  document = content.ownerDocument
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
  toggleHelp
  getHelp
  getSearchInput
}
