###
# Copyright Simon Lydell 2015, 2016.
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

namespace = (name, prefix) -> "#{ADDON_PATH}/#{BUILD_TIME}/#{prefix}#{name}"

defaultMessageManager =
  if IS_FRAME_SCRIPT
    FRAME_SCRIPT_ENVIRONMENT
  else
    Cc['@mozilla.org/globalmessagemanager;1']
      .getService(Ci.nsIMessageListenerManager)

defaultOptions = {
  messageManager: defaultMessageManager
  onShutdown: module.onShutdown
  prefix: ''
}

load = (uri, options = {}) ->
  args = Object.assign({}, defaultOptions, options)
  # Randomize URI to work around bug 1051238.
  args.messageManager.loadFrameScript("#{uri}?#{Math.random()}", true)
  args.onShutdown(->
    args.messageManager.removeDelayedFrameScript(uri)
  )

listen = (name, listener, options = {}) ->
  args = Object.assign({}, defaultOptions, options)
  namespacedName = namespace(name, args.prefix)
  fn = (data) -> invokeListener?(listener, args, data)
  args.messageManager.addMessageListener(namespacedName, fn)
  args.onShutdown(->
    args.messageManager.removeMessageListener(namespacedName, fn)
  )

listenOnce = (name, listener, options = {}) ->
  args = Object.assign({}, defaultOptions, options)
  namespacedName = namespace(name, args.prefix)
  fn = (data) ->
    args.messageManager.removeMessageListener(namespacedName, fn)
    return invokeListener?(listener, args, data)
  args.messageManager.addMessageListener(namespacedName, fn)

callbackCounter = 0
send = (name, data = null, callback = null, options = {}) ->
  args = Object.assign({}, defaultOptions, options)

  callbackName = null
  if callback
    callbackName = "#{name}:callback:#{callbackCounter}"
    callbackCounter += 1
    listenOnce(callbackName, callback, args)

  namespacedName = namespace(name, args.prefix)
  wrappedData = {data, callbackName}

  # Message Manager methods may be missing on shutdown.
  if args.messageManager.broadcastAsyncMessage
    args.messageManager.broadcastAsyncMessage?(namespacedName, wrappedData)
  else
    args.messageManager.sendAsyncMessage?(namespacedName, wrappedData)

# Unwraps the data from `send` and invokes `listener` with it.
invokeListener = (listener, args, {data: {data, callbackName} = {}, target}) ->
  callback =
    if callbackName
      (data = null) ->
        send(callbackName, data, null, Object.assign({}, args, {
          messageManager: target.messageManager ? target
        }))
    else
      null
  return listener(data, callback, target)

# Note: This is a synchronous call. It should only be used when absolutely
# needed, such as in an event listener which needs to suppress the event based
# on the return value.
get = (name, data) ->
  namespacedName = namespace(name, defaultOptions.prefix)
  [result] = defaultMessageManager.sendSyncMessage(namespacedName, {data})
  return result

module.exports = {
  load
  listen
  listenOnce
  send
  get
}
