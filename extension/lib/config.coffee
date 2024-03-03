# This file loads the user config file: config.js and frame.js.

createConfigAPI = require('./api')
messageManager = require('./message-manager')
utils = require('./utils')
prefs = require('./prefs')

{FileUtils} =
  ChromeUtils.importESModule('resource://gre/modules/FileUtils.sys.mjs')

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

sandboxPreventsAccess = (dir) ->
  expandedDir = utils.expandPath(dir)

  prefix = 'security.sandbox.content'
  if prefs.root.get("#{prefix}.level") <= 2
    return false

  if Services.appinfo.OS == 'Darwin'
    whitelisted = [
      prefs.root.get("#{prefix}.mac.testing_read_path1"),
      prefs.root.get("#{prefix}.mac.testing_read_path2")
    ]
  else
    whitelisted = prefs.root.get("#{prefix}.read_path_whitelist").split(',')

  return not whitelisted.some((e) -> e.startsWith(expandedDir))

loadFile = (dir, file, scope) ->
  expandedPath = new FileUtils.File(utils.expandPath(dir))
  dirUri = Services.io.newFileURI(expandedPath).spec
  expandedPath.append(file)
  uri = Services.io.newFileURI(expandedPath).spec
  try
    Services.scriptloader.loadSubScriptWithOptions(uri, {
      target: Object.assign({
        __dirname: dirUri,
        Services: Services
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
       sandboxPreventsAccess(dir)
      # coffeelint: disable=max_line_length
      docs = "#{HOMEPAGE}/blob/master/documentation/config-file.md#on-process-sandboxing"
      # coffeelint: enable=max_line_length
      console.error("VimFx: Error loading #{file} likely due to e10s sandbox")
      console.info("Please consult VimFx' documentation: {docs}")
    else
      console.error("VimFx: Error loading #{file}", uri, error)
    return error

module.exports = {
  load
  loadFile
}
