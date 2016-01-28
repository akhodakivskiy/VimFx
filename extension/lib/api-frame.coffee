###
# Copyright Simon Lydell 2016.
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

# This file defines VimFx’s config file API, for the frame script.

messageManager = require('./message-manager')

createConfigAPI = (vim, onShutdown = module.onShutdown) ->
  listen: (message, listener) ->
    unless typeof message == 'string'
      throw new Error("VimFx: The first argument must be a message string.
                       Got: #{message}")
    unless typeof listener == 'function'
      throw new Error("VimFx: The second argument must be a listener function.
                       Got: #{listener}")
    messageManager.listen(message, listener, {
      prefix: 'config:'
      onShutdown
    })

  setHintMatcher: (hintMatcher) ->
    unless typeof hintMatcher == 'function'
      throw new Error("VimFx: A hint matcher must be a function.
                       Got: #{hintMatcher}")
    vim.hintMatcher = hintMatcher
    onShutdown(-> vim.hintMatcher = null)

module.exports = createConfigAPI
