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
    if div = document.getElementById(CONTAINER_ID)
      div.parentNode.removeChild(div)
    div = document.createElement 'div'
    div.id = CONTAINER_ID
    div.className = 'VimFxReset'

    div.appendChild(utils.parseHTML(document, helpDialogHtml(commands)))

    document.documentElement.appendChild(div)

    installHandlers(document, commands)

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        removeHelp(document)
      button.addEventListener('click', clickHandler, false)

installHandlers = (document, commands) ->
  promptService = Cc["@mozilla.org/embedcomp/prompt-service;1"].getService(Ci.nsIPromptService);

  changeHandler = (event) ->
    { name } = event.target.dataset
    cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    cmd.enabled(event.target.checked)

  for cb in document.getElementsByClassName('VimFxKeyCheckbox')
    cb.addEventListener('change', changeHandler)

  editHandler = (event) ->
    { command: name, key } = event.target.dataset
    valueDisplay = event.target.value
    value = (valueDisplay.match(/(?:[ac]-)?./g) or []).join(',')

    if value == key
      return

    if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
      keys = cmd.keys()
      pos = keys.indexOf(key)
      if value is ''
        keys.splice(pos, 1)
        event.target.parentNode.removeChild(event.target)
      else
        if pos == -1
          keys.push(value)
        else
          keys[pos] = value
        event.target.value = valueDisplay
        event.target.dataset.key = value
        autoResize(event.target)
      cmd.keys(keys)

  # NOTE: _Live_ list!
  keyLinks = document.getElementsByClassName('VimFxKeyLink')

  checkConflicts = (baseInput) ->
    allOk = true
    if baseInput.value != ''
      for input in keyLinks when input != baseInput and input.value != ''
        if input.value.startsWith(baseInput.value) or baseInput.value.startsWith(input.value)
          allOk = false
          input.classList.add('VimFxKeyConflict')
    if allOk
      baseInput.classList.remove('VimFxKeyConflict')
    else
      baseInput.classList.add('VimFxKeyConflict')

  conflictsHandler = (event) ->
    # NOTE: `.getElementsByClassName` cannot be used, since it returns a _live_ list
    # and `checkConflicts` might alter it.
    for input in document.querySelectorAll('.VimFxKeyConflict')
      checkConflicts(input)
    checkConflicts(event.target)

  autoResize = (element)->
    # `0.3` is simply to make the element look better.
    element.style.width = "#{ element.value.length + 0.3 }ch"

  resizingHandler = (event) ->
    autoResize(event.target)

  blurOnEnter = (event) ->
    enter = 13
    if event.keyCode == enter
      event.target.blur()

  filterChars = do ->
    disallowedChars = /[ ]/g
    return (event) ->
      { value } = event.target
      match = value.match(disallowedChars)
      if match
        { selectionStart, selectionEnd } = event.target
        event.target.value = value.replace(disallowedChars, '')
        event.target.setSelectionRange(selectionStart - match.length, selectionEnd - match.length)

  prepareInput = (input) ->
    input.addEventListener('input', filterChars)
    input.addEventListener('input', resizingHandler)
    input.addEventListener('blur', editHandler)
    input.addEventListener('keydown', blurOnEnter)
    input.addEventListener('input', conflictsHandler)
    autoResize(input)
    checkConflicts(input)

  for inputSafe in keyLinks
    prepareInput(inputSafe)

  addHandler = (event) ->
    event.preventDefault()
    event.stopPropagation()
    name = event.target.dataset.command
    if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
      div = document.querySelector(".VimFxKeySequence[data-command='#{name}']")
      node = utils.parseHTML(document, hint(cmd, ''))
      input = node.querySelector('input')
      prepareInput(input)
      div.appendChild(node)
      input.focus()

  for a in document.getElementsByClassName('VimFxAddShortcutLink')
    a.addEventListener('click', addHandler, false)

td = (text, klass='') ->
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

hint = (cmd, key) ->
  keyDisplay = key.replace(/,/g, '')
  """<input type="text" class="VimFxReset VimFxKeyLink"
          data-command="#{ cmd.name }" data-key="#{ key }" value="#{ keyDisplay }" />"""

tr = (cmd) ->
  checked = if cmd.enabled() then 'checked' else null
  hints = """
    <div class="VimFxKeySequence" data-command="#{ cmd.name }">
      #{ (hint(cmd, key) for key in cmd.keys()).join('\n') }
    </div>
  """
  dot = """<span class="VimFxReset VimFxDot">&#8729;</span>"""
  cb = """<input type="checkbox" class="VimFxReset VimFxKeyCheckbox" data-name="#{ cmd.name }" #{ checked }></input>"""
  a = """#{ cmd.help() }"""
  add = """
    <a href="#" data-command="#{ cmd.name }"
        class="VimFxReset VimFxAddShortcutLink">&#8862;</a>
  """

  return """
    <tr class="VimFxReset">
        #{ td(hints) }
        #{ td(add) }
        #{ td(dot) }
        #{ td(cb) }
        #{ td(a) }
    </tr>
  """

table = (commands) ->
  """
  <table class="VimFxReset">
    #{ (tr(cmd) for cmd in commands).join('') }
  </table>
  """

section = (title, commands) ->
  """
  <div class="VimFxReset VimFxSectionTitle">#{ title }</div>
  #{ table(commands) }
  """

helpDialogHtml = (commands) ->
  return """
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
        #{ section(_('help_section_urls'),    commands.filter((a) -> a.group == 'urls')) }
        #{ section(_('help_section_nav'),     commands.filter((a) -> a.group == 'nav')) }
      </div>
      <div class="VimFxReset VimFxColumn">
        #{ section(_('help_section_tabs'),    commands.filter((a) -> a.group == 'tabs')) }
        #{ section(_('help_section_browse'),  commands.filter((a) -> a.group == 'browse')) }
        #{ section(_('help_section_misc'),    commands.filter((a) -> a.group == 'misc')) }
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
  """

exports.injectHelp = injectHelp
exports.removeHelp = removeHelp
