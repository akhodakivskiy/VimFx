# This file loads the user config file: config.js and frame.js.

createConfigAPI = require('./api')
messageManager = require('./message-manager')
utils = require('./utils')

{OS} = Components.utils.import('resource://gre/modules/osfile.jsm', {})

load = (vimfx, options = null, callback = ->) ->
  configDir = vimfx.options.config_file_directory

  unless configDir
    callback(null)
    return

  scope = {vimfx: createConfigAPI(vimfx, options)}

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

  messageManager.send('loadConfig', null, callback)

loadFile = (dir, file, scope) ->
  expandedDir = utils.expandPath(dir)
  uri = OS.Path.toFileURI(OS.Path.join(expandedDir, file))
  try
    Services.scriptloader.loadSubScriptWithOptions(uri, {
      target: Object.assign({
        __dirname: OS.Path.toFileURI(expandedDir)
      }, scope)
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
