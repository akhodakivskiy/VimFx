###
# Copyright Simon Lydell 2015.
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

namespace = (name) -> "VimFx:#{ name }"

globalMM = Cc['@mozilla.org/globalmessagemanager;1']
  .getService(Ci.nsIMessageListenerManager)

getMessageManager = (obj) -> switch
  when obj == 'global'
    globalMM
  when obj.selectedBrowser # `obj == window.gBrowser`
    selectedBrowser.messageManager
  else # `obj == window`
    obj.messageManager

load = (messageManager = globalMM, name) ->
  # Randomize URI to work around bug 1051238.
  url = "chrome://vimfx/content/#{ name }.js?#{ Math.random() }"
  messageManager.loadFrameScript(url, true)
  module.onShutdown(->
    messageManager.removeDelayedFrameScript(url)
  )

listen = (messageManager = globalMM, name, listener) ->
  namespacedName = namespace(name)
  messageManager.addMessageListener(namespacedName, listener)
  module.onShutdown(->
    messageManager.removeMessageListener(namespacedName, listener)
  )

listenOnce = (messageManager = globalMM, name, listener) ->
  namespacedName = namespace(name)
  fn = (data) ->
    messageManager.removeMessageListener(namespacedName, fn)
    listener(data)
  messageManager.addMessageListener(namespacedName, fn)

send = (messageManager = globalMM, name, data = null, callback = null) ->
  namespacedName = namespace(name)
  if callback
    listenOnce(messageManager, "#{ namespacedName }:callback", callback)
  if messageManager.broadcastAsyncMessage
    messageManager.broadcastAsyncMessage(namespacedName, data)
  else
    messageManager.sendAsyncMessage(namespacedName, data)

module.exports = {
  load
  listen
  send
}
