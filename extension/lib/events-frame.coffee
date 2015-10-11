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

# This file is the equivalent to events.coffee, but for frame scripts.

messageManager = require('./message-manager')
utils          = require('./utils')

HTMLInputElement = Ci.nsIDOMHTMLInputElement

class FrameEventManager
  constructor: (@vim) ->

  listen: utils.listen.bind(null, FRAME_SCRIPT_ENVIRONMENT)

  addListeners: ->
    @listen('DOMWindowCreated', @vim.resetState.bind(@vim))

    @listen('keydown', (event) =>
      @vim.onInput(event)
    )

    @listen('overflow', (event) =>
      return unless computedStyle = @vim.content.getComputedStyle(event.target)
      return if computedStyle.getPropertyValue('overflow') == 'hidden'
      @vim.state.scrollableElements.add(event.target)
    )

    @listen('underflow', (event) =>
      @vim.state.scrollableElements.delete(event.target)
    )

    @listen('focus', (event) =>
      target = event.originalTarget

      options = @vim.options(['prevent_autofocus', 'prevent_autofocus_modes',
                              'autofocus_limit'])

      if utils.isTextInputElement(target)
        @vim.state.lastFocusedTextInput = target

      # If the user has interacted with the page and the `window` of the page
      # gets focus, it means that the user just switched back to the page from
      # another window or tab. If a text input was focused when the user focused
      # _away_ from the page Firefox blurs it and then re-focuses it when the
      # user switches back. Therefore we count this case as an interaction, so
      # the re-focus event isn’t caught as autofocus.
      if @vim.state.lastInteraction != null and target == @vim.content
        @vim.state.lastInteraction = Date.now()

      # Autofocus prevention. Strictly speaking, autofocus may only happen
      # during page load, which means that we should only prevent focus events
      # during page load. However, it is very difficult to reliably determine
      # when the page load ends. Moreover, a page may load very slowly. Then it
      # is likely that the user tries to focus something before the page has
      # loaded fully. Therefore focus events that aren’t reasonably close to a
      # user interaction (click or key press) are blurred (regardless of whether
      # the page is loaded or not -- but that isn’t so bad: if the user doesn’t
      # like autofocus, he doesn’t like any automatic focusing, right? This is
      # actually useful on devdocs.io). There is a slight risk that the user
      # presses a key just before an autofocus, causing it not to be blurred,
      # but that’s not likely. Autofocus prevention is also restricted to
      # `<input>` elements, since only such elements are commonly autofocused.
      # Many sites have buttons which inserts a `<textarea>` when clicked (which
      # might take up to a second) and then focuses the `<textarea>`. Such focus
      # events should _not_ be blurred. There are also many buttons that do the
      # same thing but insert an `<input>` element. There is sadly always a risk
      # that those events are blurred.
      focusManager = Cc['@mozilla.org/focus-manager;1']
        .getService(Ci.nsIFocusManager)
      if options.prevent_autofocus and
          @vim.mode in options.prevent_autofocus_modes and
          target instanceof HTMLInputElement and
          # Only blur programmatic events (not caused by clicks or keypresses).
          focusManager.getLastFocusMethod(null) == 0 and
          (@vim.state.lastInteraction == null or
           Date.now() - @vim.state.lastInteraction > options.autofocus_limit)
        @vim.state.lastAutofocusPrevention = Date.now()
        target.blur()
    )

    # Save the time of the last user interaction. This is used to determine
    # whether a focus event was automatic or voluntarily dispatched.
    markLastInteraction = (event) =>
      @vim.state.lastInteraction = Date.now()

    @listen('mousedown', markLastInteraction)
    @listen('mouseup',   markLastInteraction)
    messageManager.listen('keydown', markLastInteraction)

    @listen('blur', (event) =>
      # Some sites (such as icloud.com) re-focuses inputs if they are blurred,
      # causing an infinite loop autofocus prevention and re-focusing. Therefore
      # we suppress blur events that happen just after an autofocus prevention.
      if @vim.state.lastAutofocusPrevention != null and
         Date.now() - @vim.state.lastAutofocusPrevention < 1
        @vim.state.lastAutofocusPrevention = null
        utils.suppressEvent(event)
    )

    @listen('click', (event) =>
      if @vim.mode == 'hints' and event.isTrusted
        messageManager.send('enterMode', {mode: 'normal'})
    )

module.exports = FrameEventManager
