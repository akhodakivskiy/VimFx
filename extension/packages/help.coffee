utils = require 'utils'
prefs = require 'prefs'
{ _ } = require 'l10n'

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
  changeHandler = (event) ->
    name = event.target.getAttribute('data-name')
    cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    cmd.enabled(event.target.checked)

  for cb in document.getElementsByClassName('VimFxKeyCheckbox')
    cb.addEventListener('change', changeHandler, false)

  clickHandler = (event) ->
    event.preventDefault()
    event.stopPropagation()
    name = event.target.getAttribute('data-name')
    cmd = commands.reduce(((m, v) -> if (v.name == name) then v else m), null)
    console.log cmd.name

  for a in document.getElementsByClassName('VimFxKeyLink')
    a.addEventListener('click', clickHandler, false)


td = (text, klass='') ->
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

hint = (cmd, key) ->
  keyDisplay = key.replace(/,/g, '')
  """
  <a href="#" class="VimFxReset VimFxKeyLink" data-command="#{ cmd.name }" data-key="#{ key }">#{ keyDisplay }</a>
  """

tr = (cmd) ->
  checked = if cmd.enabled() then 'checked' else null
  keyData = cmd.defaultKeys.join('|')
  hints = (hint(cmd, key) for key in cmd.keys).join('')
  key = """
    #{ hints }
    <span class="VimFxReset VimFxDot">&#8729;</span>
    <input type="checkbox" class="VimFxReset VimFxKeyCheckbox" data-name="#{ cmd.name }" #{ checked }></input>
  """

  return """<tr class="VimFxReset">#{ td(key, 'VimFxSequence') }#{ td(cmd.help()) }</tr>"""

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
