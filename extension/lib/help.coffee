###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014.
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

notation = require('vim-like-key-notation')
legacy   = require('./legacy')
utils    = require('./utils')
prefs    = require('./prefs')
_        = require('./l10n')

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

XULDocument  = Ci.nsIDOMXULDocument

CONTAINER_ID = 'VimFxHelpDialogContainer'

# coffeelint: disable=max_line_length

removeHelp = (document) ->
  document.getElementById(CONTAINER_ID)?.remove()

injectHelp = (document, modes) ->
  if document.documentElement
    removeHelp(document)

    type = if document instanceof XULDocument then 'box' else 'div'
    container = utils.createElement(document, type, {id: CONTAINER_ID})

    modeCommands = {}
    for modeName of modes
      cmds = modes[modeName].commands
      modeCommands[modeName] =
        if Array.isArray(cmds)
          cmds
        else
          (cmds[commandName] for commandName of cmds)

    container.appendChild(utils.parseHTML(document, helpDialogHtml(modeCommands)))
    for element in container.getElementsByTagName('*')
      element.classList.add('VimFxReset')

    document.documentElement.appendChild(container)

    for element in container.querySelectorAll('[data-commands]')
      elementCommands = modeCommands[element.dataset.commands]
      element.addEventListener('click',
        removeHandler.bind(undefined, document, elementCommands), false)
      element.addEventListener('click',
        addHandler.bind(undefined, document, elementCommands), false)

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        removeHelp(document)
      button.addEventListener('click', clickHandler, false)

promptService = Cc['@mozilla.org/embedcomp/prompt-service;1']
  .getService(Ci.nsIPromptService)

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
      cmd.keys(cmd.keys().filter((a) -> utils.normalizedKey(a) != key))
      event.target.remove()

addHandler = (document, commands, event) ->
  return unless event.target.classList.contains('VimFxAddShortcutLink')
  event.preventDefault()
  event.stopPropagation()
  name = event.target.getAttribute('data-command')
  if cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    errorText = ''
    loop
      title = _('help_add_shortcut_title')
      text = errorText + _('help_add_shortcut_text')
      value = {value: null}
      check = {value: null}
      if promptService.prompt(document.defaultView, title, text, value, null, check)
        input = value.value.trim()
        return if input.length == 0
        key = notation.parseSequence(input)
        try
          if name.startsWith('mode_') and key.length > 1
            throw {id: 'single_keystrokes_only'}
          normalizedKey = utils.normalizedKey(key)
        catch {id, context, subject}
          if /^\s$/.test(subject) then id = 'invalid_whitespace'
          errorText = _("error_#{ id }", context ? subject, subject) + '\n'
          continue
        conflicts = getConflicts(commands, normalizedKey)
        if conflicts.length == 0 or overwriteCmd(document, conflicts, key)
          cmd.keys(cmd.keys().concat([key]))
          for div in document.getElementsByClassName('VimFxKeySequence')
            if div.getAttribute('data-command') == cmd.name
              div.insertAdjacentHTML('beforeend', hint(cmd, key))
      break
  return

getConflicts = (commands, value) ->
  conflicts = []
  for command in commands
    conflictingKeys = []
    for key in command.keys()
      normalizedKey = utils.normalizedKey(key)
      shortest = Math.min(value.length, normalizedKey.length)
      if value[...shortest] == normalizedKey[...shortest]
        conflictingKeys.push(key)
    if conflictingKeys.length > 0
      conflicts.push({command, conflictingKeys})
  return conflicts

overwriteCmd = (document, conflicts, key) ->
  title = _('help_add_shortcut_title')
  conflictSummary = conflicts.map((conflict) ->
    conflictingKeys = conflict.conflictingKeys
      .map((key) -> key.join('')).join('  ')
    return "#{ conflict.command.help() }:  #{ conflictingKeys }"
  ).join('\n')
  text = """
    #{ _('help_add_shortcut_text_overwrite', key.join('')) }

    #{ conflictSummary }
  """
  if promptService.confirm(document.defaultView, title, text)
    for { command, conflictingKeys } in conflicts
      normalizedKeys = conflictingKeys.map((key) -> utils.normalizedKey(key))
      command.keys(command.keys().filter((key) ->
        return utils.normalizedKey(key) not in normalizedKeys
      ))
      for key in normalizedKeys
        document.querySelector("a[data-key='#{ key }']").remove()
    return true
  else
    return false

td = (text, klass = '') ->
  """<td class="#{ klass }">#{ text }</td>"""

hint = (cmd, key) ->
  normalizedKey = utils.escapeHTML(utils.normalizedKey(key))
  displayKey = utils.escapeHTML(key.join(''))
  """<a href="#" class="VimFxReset VimFxKeyLink" title="#{ _('help_remove_shortcut') }" \
          data-command="#{ cmd.name }" data-key="#{ normalizedKey }">#{ displayKey }</a>"""

tr = (cmd) ->
  hints = """
    <div class="VimFxKeySequence" data-command="#{ cmd.name }">
      #{ (hint(cmd, key) for key in cmd.keys()).join('\n') }
    </div>
  """
  dot = '<span class="VimFxDot">&#8729;</span>'
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

table = (commands, modeName) ->
  """
  <table data-commands="#{modeName}">
    #{ (tr(cmd) for cmd in commands).join('') }
  </table>
  """

section = (title, commands, modeName = 'normal') ->
  """
  <div class="VimFxSectionTitle">#{ title }</div>
  #{ table(commands, modeName) }
  """

helpDialogHtml = (modeCommands) ->
  commands = modeCommands['normal']
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
        #{ section(_('category.location'),  commands.filter((a) -> a.group == 'location')) }
        #{ section(_('category.scrolling'), commands.filter((a) -> a.group == 'scrolling')) }
        #{ section(_('category.find'),      commands.filter((a) -> a.group == 'find')) }
        #{ section(_('category.misc'),      commands.filter((a) -> a.group == 'misc')) }
      </div>
      <div class="VimFxColumn">
        #{ section(_('category.tabs'),      commands.filter((a) -> a.group == 'tabs')) }
        #{ section(_('category.browsing'),  commands.filter((a) -> a.group == 'browsing')) }
        #{ section(_('mode.hints'),         modeCommands['hints'],  'hints') }
        #{ section(_('mode.insert'),        modeCommands['insert'], 'insert') }
        #{ section(_('mode.find'),          modeCommands['find'],   'find') }
      </div>
      <div class="VimFxClearFix"></div>
    </div>

    <div class="VimFxFooter">
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
