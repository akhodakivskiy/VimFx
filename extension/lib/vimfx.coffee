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

# This file defines a top-level object to hold global state for VimFx. It keeps
# track of all `Vim` instances (vim.coffee), all options and all keyboard
# shortcuts. It can consume key presses according to its commands, and return
# the commands for UI presentation. There is only one `VimFx` instance.

notation = require('vim-like-key-notation')
prefs    = require('./prefs')
utils    = require('./utils')
Vim      = require('./vim')

DIGIT = /^\d$/

class VimFx extends utils.EventEmitter
  constructor: (@modes, @options) ->
    super()
    @vims = new WeakMap()
    @lastClosedVim = null
    @createKeyTrees()
    @reset()
    @on('modeChange', ({mode}) => @reset(mode))

  SPECIAL_KEYS: ['<force>', '<late>']

  addVim: (browser) ->
    @vims.set(browser, new Vim(browser, this))

  # NOTE: This method is often called in event handlers. Many events may fire
  # before a `vim` object has been created for the current tab yet (such as when
  # the browser is starting up). Therefore always check if anything was
  # returned, such as:
  #
  #     return unless vim = @vimfx.getCurrentVim(@window)
  getCurrentVim: (window) -> @vims.get(window.gBrowser.selectedBrowser)

  reset: (mode = null) ->
    # Modes without commands are returned by neither `.getGroupedCommands()` nor
    # `createKeyTrees`. Fall back to an empty tree.
    @currentKeyTree = @keyTrees[mode] ? {}
    @lastInputTime = 0
    @count = ''

  createKeyTrees: ->
    {@keyTrees, @errors} = createKeyTrees(@getGroupedCommands(), @SPECIAL_KEYS)

  stringifyKeyEvent: (event) ->
    return notation.stringify(event, {
      ignoreCtrlAlt: @options.ignore_ctrl_alt
      ignoreKeyboardLayout: @options.ignore_keyboard_layout
      translations: @options.translations
    })

  consumeKeyEvent: (event, vim, focusType) ->
    {mode} = vim
    return unless keyStr = @stringifyKeyEvent(event)

    now = Date.now()
    @reset(mode) if now - @lastInputTime >= @options.timeout
    @lastInputTime = now

    toplevel = (@currentKeyTree == @keyTrees[mode])

    if toplevel and @options.keyValidator
      unless @options.keyValidator(keyStr, mode)
        @reset(mode)
        return

    type = 'none'
    command = null
    specialKeys = {}

    switch
      when keyStr of @currentKeyTree and
           not (toplevel and keyStr == '0' and @count != '')
        next = @currentKeyTree[keyStr]
        if next instanceof Leaf
          type = 'full'
          {command, specialKeys} = next
        else
          @currentKeyTree = next
          type = 'partial'

      when toplevel and DIGIT.test(keyStr) and
           not (keyStr == '0' and @count == '')
        @count += keyStr
        type = 'count'

      else
        @reset(mode)

    count = if @count == '' then undefined else Number(@count)
    focus = @adjustFocusType(event, vim, focusType, keyStr)
    unmodifiedKey = notation.parse(keyStr).key
    @reset(mode) if type == 'full'
    return {
      type, focus, command, count, specialKeys, keyStr, unmodifiedKey, toplevel
      discard: @reset.bind(this, mode)
    }

  adjustFocusType: (event, vim, focusType, keyStr) ->
    # Frame scripts and the tests don’t pass in `originalTarget`.
    document = event.originalTarget?.ownerDocument
    if focusType == null and document and
       # TODO: Remove when Tab Groups have been removed.
       (vim.window.TabView?.isVisible() or
        document.fullscreenElement or document.mozFullScreenElement)
      return 'other'

    keys = @options["#{focusType}_element_keys"]
    return null if keys and keyStr not in keys

    return focusType

  getGroupedCommands: (options = {}) ->
    modes = {}
    for modeName, mode of @modes
      if options.enabledOnly
        usedSequences = getUsedSequences(@keyTrees[modeName])
      for commandName, command of mode.commands
        enabledSequences = null
        if options.enabledOnly
          enabledSequences = utils.removeDuplicates(
            command._sequences.filter((sequence) ->
              return (usedSequences[sequence] == command.pref)
            )
          )
          continue if enabledSequences.length == 0
        categories = modes[modeName] ?= {}
        category = categories[command.category] ?= []
        category.push(
          {command, enabledSequences, order: command.order, name: commandName}
        )

    modesSorted = []
    for modeName, categories of modes
      categoriesSorted = []
      for categoryName, commands of categories
        category = @options.categories[categoryName]
        categoriesSorted.push({
          name:     category.name()
          _name:    categoryName
          order:    category.order
          commands: commands.sort(byOrder)
        })
      mode = @modes[modeName]
      modesSorted.push({
        name:       mode.name()
        _name:      modeName
        order:      mode.order
        categories: categoriesSorted.sort(byOrder)
      })
    return modesSorted.sort(byOrder)

byOrder = (a, b) -> a.order - b.order

class Leaf
  constructor: (@command, @originalSequence, @specialKeys) ->

createKeyTrees = (groupedCommands, specialKeyStrings) ->
  keyTrees = {}
  errors = {}

  pushError = (error, command) ->
    (errors[command.pref] ?= []).push(error)

  pushOverrideErrors = (command, originalSequence, tree) ->
    {command: overridingCommand} = getFirstLeaf(tree)
    error =
      id:      'overridden_by'
      subject: overridingCommand.description()
      context: originalSequence
    pushError(error, command)

  pushSpecialKeyError = (command, originalSequence, key) ->
    error =
      id: 'illegal_special_key'
      subject: key
      context: originalSequence
    pushError(error, command)

  for mode in groupedCommands
    keyTrees[mode._name] = {}
    for category in mode.categories then for {command} in category.commands
      {shortcuts, errors: parseErrors} = parseShortcutPref(command.pref)
      pushError(error, command) for error in parseErrors
      command._sequences = []

      for shortcut in shortcuts
        [prefixKeys..., lastKey] = shortcut.normalized
        tree = keyTrees[mode._name]
        command._sequences.push(shortcut.original)
        seenNonSpecialKey = false
        specialKeys = {}

        errored = false
        for prefixKey, index in prefixKeys
          if prefixKey in specialKeyStrings
            if seenNonSpecialKey
              pushSpecialKeyError(command, shortcut.original, prefixKey)
              errored = true
              break
            else
              specialKeys[prefixKey] = true
              continue
          else
            seenNonSpecialKey = true

          if prefixKey of tree
            next = tree[prefixKey]
            if next instanceof Leaf
              pushOverrideErrors(command, shortcut.original, next)
              errored = true
              break
            else
              tree = next
          else
            tree = tree[prefixKey] = {}
        continue if errored

        if lastKey in specialKeyStrings
          subject = if seenNonSpecialKey then lastKey else shortcut.original
          pushSpecialKeyError(command, shortcut.original, subject)
          continue
        if lastKey of tree
          pushOverrideErrors(command, shortcut.original, tree[lastKey])
          continue
        tree[lastKey] = new Leaf(command, shortcut.original, specialKeys)

  return {keyTrees, errors}

parseShortcutPref = (pref) ->
  shortcuts = []
  errors    = []

  # The shorcut prefs are read from root in order to support other extensions to
  # extend VimFx with custom commands.
  prefValue = prefs.root.get(pref).trim()

  unless prefValue == ''
    for sequence in prefValue.split(/\s+/)
      shortcut = []
      errored  = false
      for key in notation.parseSequence(sequence)
        try
          shortcut.push(notation.normalize(key))
        catch error
          throw error unless error.id?
          errors.push(error)
          errored = true
          break
      shortcuts.push({normalized: shortcut, original: sequence}) unless errored

  return {shortcuts, errors}

getFirstLeaf = (node) ->
  if node instanceof Leaf
    return node
  for key, value of node
    return getFirstLeaf(value)

getLeaves = (node) ->
  if node instanceof Leaf
    return [node]
  leaves = []
  for key, value of node
    leaves.push(getLeaves(value)...)
  return leaves

getUsedSequences = (tree) ->
  usedSequences = {}
  for leaf in getLeaves(tree)
    usedSequences[leaf.originalSequence] = leaf.command.pref
  return usedSequences

module.exports = VimFx
