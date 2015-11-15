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

# This file provides an API a bit more easy to use than the very low-level
# Firefox message manager APIs. “Message Management” is all about sending
# messages between the main process and frame scripts. There is one frame script
# per tab, and only them can access web page content.

namespace = (name) -> "VimFx:#{name}"

defaultMM =
  if IS_FRAME_SCRIPT
    FRAME_SCRIPT_ENVIRONMENT
  else
    Cc['@mozilla.org/globalmessagemanager;1']
      .getService(Ci.nsIMessageListenerManager)

load = (name, messageManager = defaultMM) ->
  # Randomize URI to work around bug 1051238.
  url = "chrome://vimfx/content/#{name}.js?#{Math.random()}"
  messageManager.loadFrameScript(url, true)
  module.onShutdown(->
    messageManager.removeDelayedFrameScript(url)
  )

listen = (name, listener, messageManager = defaultMM) ->
  namespacedName = namespace(name)
  fn = invokeListener.bind(null, listener)
  messageManager.addMessageListener(namespacedName, fn)
  module.onShutdown(->
    messageManager.removeMessageListener(namespacedName, fn)
  )

listenOnce = (name, listener, messageManager = defaultMM) ->
  namespacedName = namespace(name)
  fn = (data) ->
    messageManager.removeMessageListener(namespacedName, fn)
    invokeListener(listener, data)
  messageManager.addMessageListener(namespacedName, fn)

callbackCounter = 0
send = (name, data = null, messageManager = defaultMM, callback = null) ->
  if typeof messageManager == 'function'
    callback = messageManager
    messageManager = defaultMM

  callbackName = null
  if callback
    callbackName = "#{name}:callback:#{callbackCounter}"
    callbackCounter++
    listenOnce(callbackName, callback, messageManager)

  namespacedName = namespace(name)
  wrappedData = {data, callback: callbackName}
  if messageManager.broadcastAsyncMessage
    messageManager.broadcastAsyncMessage(namespacedName, wrappedData)
  else
    messageManager.sendAsyncMessage(namespacedName, wrappedData)

# Unwraps the data from `send` and invokes `listener` with it.
invokeListener = (listener, {name, data: {data, callback} = {}, target}) ->
  listener(data, {name, target, callback})

# Note: This is a synchronous call. It should only be used when absolutely
# needed, such as in an event listener which needs to suppress the event based
# on the return value.
get = (name, data) ->
  [result] = defaultMM.sendSyncMessage(namespace(name), {data})
  return result

module.exports = {
  load
  listen
  listenOnce
  send
  get
}
