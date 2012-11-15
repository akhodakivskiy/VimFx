utils             = require 'utils'

CONTAINER_ID = 'VimFxHelpDialogContainer'

showHelp = (document, commandsHelp) ->
  if body = document.body
    if div = document.getElementById CONTAINER_ID
      div.parentNode.removeChild div
    div = document.createElement 'div'
    div.id = CONTAINER_ID 
    div.className = 'VimFxReset'

    div.innerHTML = helpDialogHtml(commandsHelp)

    body.appendChild div

    if button = document.getElementById('VimFxClose')
      clickHandler = (event) ->
        event.stopPropagation()
        event.preventDefault()
        hideHelp(document)
      button.addEventListener 'click', clickHandler, false

hideHelp = (document) ->
  if div = document.getElementById CONTAINER_ID
    div.parentNode.removeChild div

td = (text, klass='') ->
  console.log text
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

tr = (key, text) ->
  key = """#{ key } <span class="VimFxReset VimFxDot">&#8729;</span>"""
  """<tr class="VimFxReset">#{ td(key, 'VimFxSequence') }#{ td(text) }</tr>"""

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

exports.showHelp = showHelp
exports.hideHelp = hideHelp
