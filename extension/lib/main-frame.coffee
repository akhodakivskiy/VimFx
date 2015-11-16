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

# This file is the equivalent of main.coffee, but for frame scripts.

commands          = require('./commands-frame')
FrameEventManager = require('./events-frame')
messageManager    = require('./message-manager')
VimFrame          = require('./vim-frame')

module.exports = ->
  {content} = FRAME_SCRIPT_ENVIRONMENT
  vim = new VimFrame(content)

  eventManager = new FrameEventManager(vim)
  eventManager.addListeners()

  messageManager.listen('runCommand', ({name, data}, {callback}) ->
    result = commands[name](Object.assign({vim}, data))
    messageManager.send(callback, result) if callback?
  )
