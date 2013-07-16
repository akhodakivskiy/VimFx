utils = require 'utils'
prefs = require 'prefs'

CONTAINER_ID = 'VimFxHelpDialogContainer'

removeHelp = (document) ->
  if div = document.getElementById(CONTAINER_ID)
    div.parentNode.removeChild(div)

injectHelp = (document, commandsHelp) ->
  if document.documentElement
    if div = document.getElementById(CONTAINER_ID)
      div.parentNode.removeChild(div)
    div = document.createElement 'div'
    div.id = CONTAINER_ID
    div.className = 'VimFxReset'

    div.appendChild(utils.parseHTML(document, helpDialogHtml(commandsHelp)))

    document.documentElement.appendChild(div)

    installCheckboxHandlers(document)

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        removeHelp(document)
      button.addEventListener('click', clickHandler, false)

installCheckboxHandlers = (document) ->
  cbs = document.getElementsByClassName('VimFxKeyCheckbox')
  for cb in cbs
    cb.addEventListener 'change', (event)->
      key = event.target.getAttribute('data-key')

      # Checkbox if checked => command is in use
      if event.target.checked
        prefs.enableCommand(key)
      else
        prefs.disableCommand(key)

td = (text, klass='') ->
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

tr = (key, text) ->
  disabled = prefs.isCommandDisabled(key)
  checked = if disabled then null else 'checked'
  key = """
    #{ key.replace(/,/g, '').replace('|', ', ') }
    <span class="VimFxReset VimFxDot">&#8729;</span>
    <input type="checkbox" class="VimFxReset VimFxKeyCheckbox" data-key="#{ key }" #{ checked }></input>
  """

  return """<tr class="VimFxReset">#{ td(key, 'VimFxSequence') }#{ td(text) }</tr>"""

table = (commands) ->
  """
  <table class="VimFxReset">
    #{ (tr(cmd, text) for cmd, text of commands).join('') }
  </table>
  """

section = (title, commands) ->
  """
  <div class="VimFxReset VimFxSectionTitle">#{ title }</div>
  #{ table(commands) }
  """

helpDialogHtml = (help) ->
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
        #{ section(_('help_section_urls'),    help['urls']) }
        #{ section(_('help_section_nav'),     help['nav']) }
      </div>
      <div class="VimFxReset VimFxColumn">
        #{ section(_('help_section_tabs'),    help['tabs']) }
        #{ section(_('help_section_browse'),  help['browse']) }
        #{ section(_('help_section_misc'),    help['misc']) }
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
