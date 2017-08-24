# This file creates VimFx’s status panel, similar to the “URL popup” shown when
# hovering or focusing links.

utils = require('./utils')

injectStatusPanel = (browser) ->
  window = browser.ownerGlobal

  statusPanel = window.document.createElement('statuspanel')
  utils.setAttributes(statusPanel, {
    inactive: 'true'
    layer: 'true'
    mirror: 'true'
  })

  window.gBrowser.getBrowserContainer(browser).appendChild(statusPanel)
  module.onShutdown(-> statusPanel.remove())

  return statusPanel

module.exports = {
  injectStatusPanel
}
