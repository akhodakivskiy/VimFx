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

    type = if document instanceof XULDocument then 'box' else 'div'
    container = utils.createElement(document, type, {id: CONTAINER_ID})

    container.appendChild(utils.parseHTML(document, helpDialogHtml(commands)))
    for element in container.getElementsByTagName('*')
      element.classList.add('VimFxReset')

    document.documentElement.appendChild(container)

    container.addEventListener('click', removeHandler.bind(undefined, document, commands), false)
    container.addEventListener('click', addHandler.bind(undefined, document, commands), false)

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        removeHelp(document)
      button.addEventListener('click', clickHandler, false)

promptService = Cc["@mozilla.org/embedcomp/prompt-service;1"].getService(Ci.nsIPromptService)
removeHandler = (document, commands, event) ->
  return unless event.target.classList.contains('VimFxKeyLink')
  event.preventDefault()
  event.stopPropagation()
  key = event.target.getAttribute('data-key')
  name = event.target.getAttribute('data-command')
  if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    title = _('help_remove_shortcut_title')
    text = _('help_remove_shortcut_text')
    if promptService.confirm(document.defaultView, title, text)
      cmd.keys(cmd.keys().filter((a) -> a != key))
      event.target.remove()

addHandler = (document, commands, event) ->
  return unless event.target.classList.contains('VimFxAddShortcutLink')
  event.preventDefault()
  event.stopPropagation()
  name = event.target.getAttribute('data-command')
  if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    title = _('help_add_shortcut_title')
    text = _('help_add_shortcut_text')
    value = { value: null }
    check = { value: null }
    if promptService.prompt(document.defaultView, title, text, value, null, check)
      return if value.value.length == 0
      conflicts = getConflicts(commands, value.value)
      if conflicts.length == 0 or overwriteCmd(document, conflicts, value.value)
        cmd.keys(cmd.keys().concat(value.value))
        for div in document.getElementsByClassName('VimFxKeySequence')
          if div.getAttribute('data-command') == cmd.name
            div.insertAdjacentHTML('beforeend', hint(cmd, value.value))
  return

getConflicts = (commands, value) ->
  conflicts = []
  for command in commands
    conflictingKeys = []
    for key in command.keys()
      shortest = Math.min(value.length, key.length)
      if "#{value},"[..shortest] == "#{key},"[..shortest]
        conflictingKeys.push(key)
    if conflictingKeys.length > 0
      conflicts.push({ command, conflictingKeys })
  return conflicts

overwriteCmd = (document, conflicts, key) ->
  title = _('help_add_shortcut_title')
  conflictSummary = conflicts.map((conflict) ->
    return "#{ conflict.command.help() }:  #{ conflict.conflictingKeys.join('  ') }"
  ).join("\n")
  text = """
    #{ _('help_add_shortcut_text_overwrite', null, key) }

    #{ conflictSummary }
  """
  if promptService.confirm(document.defaultView, title, text)
    for { command, conflictingKeys } in conflicts
      command.keys(command.keys().filter((key) -> key not in conflictingKeys))
      for key in conflictingKeys
        document.querySelector("a[data-key='#{key}']").remove()
    return true
  else
    return false

td = (text, klass='') ->
  """<td class="#{ klass }">#{ text }</td>"""

hint = (cmd, key) ->
  keyDisplay = key.replace(/,/g, '')
  """<a href="#" class="VimFxReset VimFxKeyLink" title="#{ _('help_remove_shortcut') }"
          data-command="#{ cmd.name }" data-key="#{ key }">#{ keyDisplay }</a>"""

tr = (cmd) ->
  hints = """
    <div class="VimFxKeySequence" data-command="#{ cmd.name }">
      #{ (hint(cmd, key) for key in cmd.keys()).join('\n') }
    </div>
  """
  dot = """<span class="VimFxDot">&#8729;</span>"""
  a = """#{ cmd.help() }"""
  add = """
    <a href="#" data-command="#{ cmd.name }"
        class="VimFxAddShortcutLink" title="#{ _('help_add_shortcut') }">&#8862;</a>
  """

  return """
    <tr>
        #{ td(hints) }
        #{ td(add) }
        #{ td(dot) }
        #{ td(a) }
    </tr>
  """

table = (commands) ->
  """
  <table>
    #{ (tr(cmd) for cmd in commands).join('') }
  </table>
  """

section = (title, commands) ->
  """
  <div class="VimFxSectionTitle">#{ title }</div>
  #{ table(commands) }
  """

helpDialogHtml = (commands) ->
  return """
  <div id="VimFxHelpDialog">
    <div class="VimFxHeader">
      <div class="VimFxTitle">
        <span class="VimFxTitleVim">Vim</span><span class="VimFxTitleFx">Fx</span>
        <span>#{ _('help_title') }</span>
      </div>
      <span class="VimFxVersion">#{ _('help_version') } #{ utils.getVersion() }</span>
      <a class="VimFxClose" id="VimFxClose" href="#">&#10006;</a>
      <div class="VimFxClearFix"></div>
      <p>Did you know that you can add/remove shortucts in this dialog?</p>
      <div class="VimFxClearFix"></div>
      <p>Click the shortcut to remove it, and click &#8862; to add new shortcut!</p>
    </div>

    <div class="VimFxBody">
      <div class="VimFxColumn">
        #{ section(_('help_section_urls'),    commands.filter((a) -> a.group == 'urls')) }
        #{ section(_('help_section_nav'),     commands.filter((a) -> a.group == 'nav')) }
      </div>
      <div class="VimFxColumn">
        #{ section(_('help_section_tabs'),    commands.filter((a) -> a.group == 'tabs')) }
        #{ section(_('help_section_browse'),  commands.filter((a) -> a.group == 'browse')) }
        #{ section(_('help_section_misc'),    commands.filter((a) -> a.group == 'misc')) }
      </div>
      <div class="VimFxClearFix"></div>
    </div>

    <div class="VimFxFooter">
      <p>#{ _('help_overlapping_hints') }</p>
      <p>
        #{ _('help_found_bug') }
        <a target="_blank" href="https://github.com/akhodakivskiy/VimFx/issues">
          #{ _('help_report_bug') }
        </a>
      </p>
      <p>
        #{ _('help_enjoying') }
        <a target="_blank" href="https://addons.mozilla.org/en-US/firefox/addon/vimfx/">
          #{ _('help_feedback') }
        </a>
      </p>
    </div>
  </div>
  """

exports.injectHelp = injectHelp
exports.removeHelp = removeHelp
