# This file loads the user config file: config.js and frame.js.

createConfigAPI = require('./api')
messageManager = require('./message-manager')
utils = require('./utils')
prefs = require('./prefs')

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

checkSandbox = (expandedDir) ->
  prefix = 'security.sandbox.content'
  if prefs.root.get("#{prefix}.level") > 2
    return true

  if Services.appinfo.OS == 'Darwin'
    whitelisted = [
      prefs.root.get("#{prefix}.mac.testing_read_path1"),
      prefs.root.get("#{prefix}.mac.testing_read_path2")
    ]
  else
    whitelisted = prefs.root.get("#{prefix}.read_path_whitelist").split(',')
  return not whitelisted.some((e) -> e.startsWith(expandedDir))

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
    # in e10s Firefox / Firefox Quantum the content process sandbox might
    # prevent us from accessing frame.js. The error message is incomprehensible
    # without explanation.
    if typeof error == 'string' and
       error.startsWith('Error opening input stream (invalid filename?)') and
       checkSandbox(expandedDir)
      console.error("VimFx: Error loading #{file} likely due to e10s sandbox")
      console.info("Please consult VimFx' documentation on config files.")
    else
      console.error("VimFx: Error loading #{file}", uri, error)
    return error

module.exports = {
  load
  loadFile
}
