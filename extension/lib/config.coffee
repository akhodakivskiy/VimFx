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

# This file loads the user config file: config.js and frame.js.

createConfigAPI = require('./api')
messageManager = require('./message-manager')

load = (vimfx, callback = ->) ->
  configDir = vimfx.options.config_file_directory

  unless configDir
    callback(null)
    return

  scope = {vimfx: createConfigAPI(vimfx)}

  # Calling `vimfx.createKeyTrees()` after each `vimfx.set()` that modifies a
  # shortcut is absolutely redundant and may make Firefox start slower. Do it
  # once instead.
  vimfx.skipCreateKeyTrees = true
  error = loadFile(configDir, 'config.js', scope)
  vimfx.skipCreateKeyTrees = false
  vimfx.createKeyTrees()

  if error
    callback(false)
    return

  messageManager.send('loadConfig', configDir, callback)

loadFile = (dir, file, scope) ->
  uri = "#{dir}/#{file}"
  try
    Services.scriptloader.loadSubScriptWithOptions(uri, {
      target: scope
      charset: 'UTF-8'
      ignoreCache: true
    })
    return null
  catch error
    console.error("VimFx: Error loading #{file}", uri, error)
    return error

module.exports = {
  load
  loadFile
}
