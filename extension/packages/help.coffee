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
  """<td class="VimFxReset #{ klass }">#{ text }</td>"""

tr = (key, text) ->
  key = """#{ key } <span class="VimFxReset VimFxDot">&#8729;"""
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


  html = null
  if html == null
    html = """

<div id="VimFxHelpDialog" class="VimFxReset">
  <div class="VimFxReset VimFxHeader">
    <div class="VimFxReset VimFxTitle">
      <span class="VimFxReset VimFxTitleVim">Vim</span><span class="VimFxReset VimFxTitleFx">Fx</span>
      <span class="VimFxReset">Help</span>
    </div>
    <span class="VimFxReset VimFxVersion">Version #{ utils.getVersion() }</span>
    <a class="VimFxReset VimFxClose" id="VimFxClose" href="#">&#10006;</a>
    <div class="VimFxReset VimFxClearFix"></div>
  </div>

  <div class="VimFxReset VimFxBody">
    <div class="VimFxReset VimFxColumn">
      #{ section('Dealing with URLs', help['urls']) }
      #{ section('Navigating the page', help['nav']) }
    </div>
    <div class="VimFxReset VimFxColumn">
      #{ section('Working with Tabs', help['tabs']) }
      #{ section('Browsing', help['browse']) }
      #{ section('Misc', help['misc']) }
    </div>
    <div class="VimFxReset VimFxClearFix"></div>
  </div>

  <div class="VimFxReset VimFxFooter">
    <div class="VimFxReset VimFxSocial">
      <p class="VimFxReset">
        Found a bug? 
        <a class="VimFxReset" target="_blank" href="https://github.com/akhodakivskiy/VimFx/issues">
          Report it Here!
        </a>
      </p>
      <p class="VimFxReset">
        Enjoying VimFx? 
        <a class="VimFxReset" target="_blank" href="https://addons.mozilla.org/en-US/firefox/addon/vimfx/">
          Leave us Feedback!
        </a>
      </p>
    </div>
  </div>
</div>

"""
  return html

exports.showHelp = showHelp
exports.hideHelp = hideHelp
