utils = require 'utils'
prefs = require 'prefs'
{ _ } = require 'l10n'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

CONTAINER_ID = 'VimFxHelpDialogContainer'

removeHelp = (document) ->
  if div = document.getElementById(CONTAINER_ID)
    div.parentNode.removeChild(div)

injectHelp = (document, commands) ->
  if document.documentElement
    removeHelp(document)
    container = utils.parseHTML(document, helpDialogHtml(commands) )
    installHandlers(document, container.querySelector('*'), commands)
    document.documentElement.appendChild(container)


helpDialogHtml = (commands) ->
  return """
    <div id="#{ CONTAINER_ID }" class="VimFxReset">
      <div id="VimFxHelpDialog" class="VimFxReset">
        <div class="VimFxReset VimFxHeader">
          <div class="VimFxReset VimFxTitle">
            <span class="VimFxReset VimFxTitleVim">Vim</span><span class="VimFxReset VimFxTitleFx">Fx</span>
            <span class="VimFxReset">#{ _('help') }</span>
          </div>
          <span class="VimFxReset VimFxVersion">#{ _('help_version') } #{ utils.getVersion() }</span>
          <a class="VimFxReset VimFxClose" id="VimFxClose" href="#">&#10006;</a>
          <div class="VimFxReset VimFxClearFix"></div>
        </div>

        <div class="VimFxReset VimFxBody">
          <div class="VimFxReset VimFxColumn">
            #{ section('urls',   commands) }
            #{ section('nav',    commands) }
          </div>
          <div class="VimFxReset VimFxColumn">
            #{ section('tabs',   commands) }
            #{ section('browse', commands) }
            #{ section('misc',   commands) }
          </div>
          <div class="VimFxReset VimFxClearFix"></div>
        </div>

        <div class="VimFxReset VimFxFooter">
          <div class="VimFxReset VimFxSocial">
            <p class="VimFxReset">
              #{ _('help_found_bug') }
              <a class="VimFxReset" target="_blank" href="https://github.com/akhodakivskiy/VimFx/issues">
                #{ _('help_report_bug') }
              </a>
            </p>
            <p class="VimFxReset">
              #{ _('help_enjoying') }
              <a class="VimFxReset" target="_blank" href="https://addons.mozilla.org/en-US/firefox/addon/vimfx/">
                #{ _('help_feedback') }
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
    """

section = (name, commands) ->
  return """
    <div class="VimFxReset VimFxSectionTitle">#{ _("help_section_#{name}") }</div>
    #{ table(commands.filter((command) -> command.group == name)) }
    """

table = (commands) ->
  return """
    <table class="VimFxReset">
      #{ (tr(command) for command in commands).join('') }
    </table>
    """

tr = (command) ->
  enabled = if command.enabled() then 'checked' else ''
  hints = (hint(command, key) for key in command.keys()).join('\n')
  addButton = """
    <button data-command="#{ command.name }"
        class="VimFxReset VimFxAddShortcut">&#8862;</button>
    """
  dot = """<span class="VimFxReset VimFxDot">&#8729;</span>"""
  checkbox = """
    <input type="checkbox" class="VimFxReset VimFxKeyCheckbox"
      data-name="#{ command.name }" #{ enabled }></input>
    """
  description = command.help()

  return """
    <tr class="VimFxReset" data-command="#{ command.name }">
        #{ td(hints, 'VimFxKeySequence') }
        #{ td(addButton) }
        #{ td(dot) }
        #{ td(checkbox) }
        #{ td(description) }
    </tr>
    """

td = (text, klass='') ->
  return """<td class="VimFxReset #{ klass }">#{ text }</td>"""

hint = (command, key) ->
  return """
    <input type="text" class="VimFxReset VimFxKey" maxlength="10"
      data-command="#{ command.name }" data-key="#{ key }" value="#{ key }" />
    """


installHandlers = (document, container, commands) ->
  delegate = utils.delegate.bind(undefined, document)

  getCommand = (name) ->
    break for command in commands when command.name == name
    return command


  closeHelp = (event) ->
    event.stopPropagation()
    event.preventDefault()
    removeHelp(document)
  container.querySelector('#VimFxClose').addEventListener('click', closeHelp, false)

  checkboxHandler = (checkbox, event) ->
    { name } = checkbox.dataset
    command = getCommand(name)
    command.enabled(checkbox.checked)

  delegate('change', 'VimFxKeyCheckbox', checkboxHandler)


  editHandler = (input, event) ->
    { command: name, key } = input.dataset
    value = input.value.trim()

    command = getCommand(name)
    keys = command.keys()
    pos = keys.indexOf(key)
    if value is ''
      keys.splice(pos, 1)
      input.parentNode.removeChild(input)
    else
      if pos == -1
        keys.push(value)
      else
        keys[pos] = value
      input.value = input.dataset.key = value
      autoResize(input)
    command.keys(keys)

  checkConflicts = do ->
    keys = container.getElementsByClassName('VimFxKey') # NOTE: _Live_ list!
    startsWith = (a, b) ->
      aParts = a.trim().split(/\s+/)
      bParts = b.trim().split(/\s+/)
      return bParts.every((part, index) -> part == aParts[index])

    return (baseInput) ->
      allOk = true
      if baseInput.value != ''
        for input in keys when input != baseInput and input.value != ''
          if startsWith(input.value, baseInput.value) or startsWith(baseInput.value, input.value)
            allOk = false
            input.classList.add('VimFxKeyConflict')
      if allOk
        baseInput.classList.remove('VimFxKeyConflict')
      else
        baseInput.classList.add('VimFxKeyConflict')

  conflictsHandler = (targetInput, event) ->
    # NOTE: `.getElementsByClassName` cannot be used, since it returns a _live_ list
    # and `checkConflicts` might alter it
    for input in container.querySelectorAll('.VimFxKeyConflict')
      checkConflicts(input)
    checkConflicts(targetInput)

  autoResize = (element)->
    # `0.3` is simply to make the element look better
    element.style.width = "#{ element.value.length + 0.3 }ch"

  blurOnEnter = (input, event) ->
    enter = 13
    if event.keyCode == enter
      input.blur()

  filterChars = do ->
    disallowedChars = /\ (?= )/g
    return (input, event) ->
      { value } = input
      newValue = value.replace(disallowedChars, '')
      if newValue != value
        { selectionStart } = input
        input.value = newValue
        input.selectionStart = input.selectionEnd = selectionStart - (value.length - newValue.length)

  delegate('input',   'VimFxKey', filterChars)
  delegate('input',   'VimFxKey', autoResize)
  delegate('blur',    'VimFxKey', editHandler)
  delegate('keydown', 'VimFxKey', blurOnEnter)
  delegate('input',   'VimFxKey', conflictsHandler)

  for input in container.getElementsByClassName('VimFxKey')
    autoResize(input)
    checkConflicts(input)


  addHandler = (addButton, event) ->
    event.preventDefault()
    event.stopPropagation()
    name = addButton.dataset.command
    command = getCommand(name)
    parent = container.querySelector("tr[data-command='#{name}'] .VimFxKeySequence")
    node = utils.parseHTML(document, hint(command, ''))
    input = node.querySelector('*')
    autoResize(input)
    parent.appendChild(node)
    input.focus()

  delegate('click', 'VimFxAddShortcut', addHandler)


exports.injectHelp = injectHelp
exports.removeHelp = removeHelp
