utils        = require 'utils'
prefs        = require 'prefs'
{ _ }        = require 'l10n'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

XULDocument  = Ci.nsIDOMXULDocument

CONTAINER_ID = 'VimFxHelpDialogContainer'

removeHelp = (document) ->
  document.getElementById(CONTAINER_ID)?.remove()

injectHelp = (document, commands) ->
  if document.documentElement
    removeHelp(document)

    if document instanceof XULDocument
      container = document.createElement('box')
      # The `.VimFxReset` class is not needed in XUL documents. Instead it actullay causes layout
      # problems there!
    else
      container = document.createElement('div')
      container.className = 'VimFxReset'
    container.id = CONTAINER_ID

    container.appendChild(utils.parseHTML(document, helpDialogHtml(commands)))

    document.documentElement.appendChild(container)

    installHandlers(document, commands)

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        removeHelp(document)
      button.addEventListener('click', clickHandler, false)

installHandlers = (document, commands) ->
  promptService = Cc["@mozilla.org/embedcomp/prompt-service;1"].getService(Ci.nsIPromptService)

  changeHandler = (event) ->
    name = event.target.getAttribute('data-name')
    cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    cmd.enabled(event.target.checked)

  for cb in document.getElementsByClassName('VimFxKeyCheckbox')
    cb.addEventListener('change', changeHandler)

  removeHandler = (event) ->
    event.preventDefault()
    event.stopPropagation()
    key = event.target.getAttribute('data-key')
    name = event.target.getAttribute('data-command')
    if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
      title = _('help_remove_shortcut_title')
      text = _('help_remove_shortcut_text')
      if promptService.confirm(document.defaultView, title, text)
        cmd.keys(cmd.keys().filter((a) -> a != key))
        event.target.parentNode.removeChild(event.target)

  for a in document.getElementsByClassName('VimFxKeyLink')
    a.addEventListener('click', removeHandler)

  addHandler = (event) ->
    event.preventDefault()
    event.stopPropagation()
    name = event.target.getAttribute('data-command')
    if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
      title = _('help_add_shortcut_title')
      text = _('help_add_shortcut_text')
      value = { value: null }
      check = { value: null }
      if promptService.prompt(document.defaultView, title, text, value, null, check)
        conflict_cmd = commands.filter((c) => c.keys().indexOf(value.value) != -1)
        if conflict_cmd.length < 1 || overwriteCmd(conflict_cmd[0], value.value)
          cmd.keys(cmd.keys().concat(value.value))
          for div in document.getElementsByClassName('VimFxKeySequence')
            if div.getAttribute('data-command') == cmd.name
              node = utils.parseHTML(document, hint(cmd, value.value))
              node.querySelector('a').addEventListener('click', removeHandler)
              div.appendChild(node)

  overwriteCmd = (cmd, key) ->
    title = _('help_add_shortcut_title')
    text = _('help_add_shortcut_text_overwrite', null, key, cmd.help())
    if promptService.confirm(document.defaultView, title, text)
      cmd.keys(cmd.keys().filter((a) -> a != key))
      dom = document.querySelectorAll("a[data-key='#{key}']")
      dom[0].parentNode.removeChild(dom[0]) if dom.length > 0
      return true
    else
      return false

  for a in document.getElementsByClassName('VimFxAddShortcutLink')
    a.addEventListener('click', addHandler, false)

td = (text, klass='') ->
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

hint = (cmd, key) ->
  keyDisplay = key.replace(/,/g, '')
  """<a href="#" class="VimFxReset VimFxKeyLink" title="#{ _('help_remove_shortcut') }"
          data-command="#{ cmd.name }" data-key="#{ key }">#{ keyDisplay }</a>"""

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
        class="VimFxReset VimFxAddShortcutLink" title="#{ _('help_add_shortcut') }">&#8862;</a>
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
        <span class="VimFxReset">#{ _('help_title') }</span>
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
      <p class="VimFxReset">#{ _('help_overlapping_hints') }</p>
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
  """

exports.injectHelp = injectHelp
exports.removeHelp = removeHelp
