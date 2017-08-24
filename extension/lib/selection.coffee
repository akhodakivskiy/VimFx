# This file helps dealing with text selection: Querying it, modifying it and
# moving its caret.

FORWARD = true
BACKWARD = false

class SelectionManager
  constructor: (@window) ->
    @selection = @window.getSelection()
    @nsISelectionController = @window
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIWebNavigation)
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsISelectionDisplay)
      .QueryInterface(Ci.nsISelectionController)

  @FORWARD = FORWARD
  @BACKWARD = BACKWARD

  enableCaret: ->
    @nsISelectionController.setCaretEnabled(true)
    @nsISelectionController.setCaretReadOnly(false)
    @nsISelectionController.setCaretVisibilityDuringSelection(true)

  collapse: ->
    return if @selection.isCollapsed
    direction = @getDirection()
    if direction == FORWARD
      @selection.collapseToEnd()
    else
      @selection.collapseToStart()

  moveCaretThrowing: (method, direction, select = true) ->
    @nsISelectionController[method](direction, select)

  moveCaret: (args...) ->
    try
      @moveCaretThrowing(args...)
    catch error
      return error
    return null

  # The simplest way to measure selection length is
  # `selection.toString().length`. However, `selection.toString()` collapses
  # whitespace even in `<pre>` elements, so it is sadly not reliable. Instead we
  # have to measure client rects.
  getSelectionLength: ->
    width = 0
    numRects = 0
    for index in [0...@selection.rangeCount] by 1
      for rect in @selection.getRangeAt(index).getClientRects()
        width += rect.width
        numRects += 1
    return [width, numRects]

  getDirection: (directionIfCollapsed = FORWARD) ->
    # The “test for newlines” trick used in `@reverseDirection` should _not_ be
    # used here. If it were, selecting the newline(s) between two paragraphs and
    # then `@collapse()`ing that selection might move the caret.
    return directionIfCollapsed if @selection.isCollapsed

    # Creating backwards ranges is not supported. When trying to do so,
    # `range.toString()` returns the empty string.
    range = @window.document.createRange()
    range.setStart(@selection.anchorNode, @selection.anchorOffset)
    range.setEnd(@selection.focusNode, @selection.focusOffset)
    return range.toString() != ''

  reverseDirection: ->
    # If the caret is at the end of a paragraph, or at the start of the
    # paragraph, and the newline(s) between those paragraphs happen to be
    # selected, it _looks_ as if `selection.isCollapsed` should be `true`, but
    # it isn't because of said (virtual) newline characters. If so, the below
    # algorithm might move the caret from the start of a paragraph to the end of
    # the previous paragraph, etc. So don’t do anything if the selection is
    # empty or newlines only.
    return if /^\n*$/.test(@selection.toString())

    direction = @getDirection()

    range = @selection.getRangeAt(0)
    edge = if direction == FORWARD then 'start' else 'end'
    {"#{edge}Container": edgeElement, "#{edge}Offset": edgeOffset} = range
    range.collapse(not direction)
    @selection.removeAllRanges()
    @selection.addRange(range)
    @selection.extend(edgeElement, edgeOffset)

    # When going from backward to forward the caret might end up at the line
    # _after_ the selection if the selection ends at the end of a line, which
    # looks a bit odd. This adjusts that case.
    if direction == BACKWARD
      [oldWidth] = @getSelectionLength()
      @moveCaret('characterMove', BACKWARD)
      [newWidth] = @getSelectionLength()
      unless newWidth == oldWidth
        @moveCaret('characterMove', FORWARD)

  wordMoveAdjusted: (direction, select = true) ->
    selectionDirection = @getDirection(direction)

    try
      if (select and selectionDirection != direction) or
         (not select and direction == FORWARD)
        @_wordMoveAdjusted(direction)
      else
        @moveCaretThrowing('wordMove', direction, select)
    catch error
      throw error unless error.name == 'NS_ERROR_FAILURE'
      @collapse() unless select
      return error

    unless select
      # When at the very end of the document `@_wordMoveAdjusted(FORWARD)` might
      # end up moving the caret _backward!_ If so, move the caret back.
      @moveCaret('wordMove', direction) if @getDirection(direction) != direction
      @collapse()

    return null

  _wordMoveAdjusted: (direction) ->
    [oldWidth, oldNumRects] = @getSelectionLength()

    # Do the old “two steps forward and one step back” trick to avoid the
    # selection ending with whitespace. (Vice versa for backwards selections.)
    @moveCaretThrowing('wordMove', direction)
    @moveCaretThrowing('wordMove', direction)
    @moveCaretThrowing('wordMove', not direction)

    [newWidth, newNumRects] = @getSelectionLength()

    # However, in some cases the above can result in the caret not moving at
    # all. If so, go _three_ steps forward and one back. (Again, vice versa for
    # backwards selections.)
    if oldNumRects == newNumRects and oldWidth == newWidth
      @moveCaretThrowing('wordMove', direction)
      @moveCaretThrowing('wordMove', direction)
      @moveCaretThrowing('wordMove', direction)
      @moveCaretThrowing('wordMove', not direction)

    [newWidth, newNumRects] = @getSelectionLength()

    # Finally, if everything else failed to move the caret (such as when being
    # one word from the end of the document), simply move one step.
    if oldNumRects == newNumRects and oldWidth == newWidth
      @moveCaretThrowing('wordMove', direction)

module.exports = SelectionManager
