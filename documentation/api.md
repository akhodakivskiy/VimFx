<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# API

This file documents VimFx’s [config file] API.

Both `config.js` and `frame.js` have access to a variable called `vimfx`. Note
that while the variables have the same name, they are different and provide
different API methods.


## `config.js` API

In `config.js`, the following API is available as the variable `vimfx`.

### `vimfx.get(...)`, `vimfx.getDefault(...)` and `vimfx.set(...)`

Gets or sets the (default) value of a VimFx option.

You can see all options in [defaults.coffee], or by opening [about:config] and
filtering by `extensions.vimfx`. Note that you can also access the [special
options], which may not be accessed in [about:config], using `vimfx.get(...)`
and `vimfx.set(...)`—in fact, this is the _only_ way of accessing those options.

#### `vimfx.get(option)`

Gets the value of the VimFx option `option`.

```js
// Get the value of the Hint characters option:
vimfx.get('hints.chars')
// Get all keyboard shortcuts (as a string) for the `f` command:
vimfx.get('mode.normal.follow')
```

#### `vimfx.getDefault(option)`

Gets the default value of the VimFx option `option`.

Useful when you wish to extend a default, rather than replacing it. See below.

#### `vimfx.set(option, value)`

Sets the value of the VimFx option `option` to `value`.

```js
// Set the value of the Hint characters option:
vimfx.set('hints.chars', 'abcdefghijklmnopqrstuvwxyz')
// Add yet a keyboard shortcut for the `f` command:
vimfx.set('mode.normal.follow', vimfx.getDefault('mode.normal.follow') + '  ee')
```

When extending an option (as in the second example above), be sure to use
`vimfx.getDefault` rather than `vimfx.get`. Otherwise you get a multiplying
effect. In the above example, after starting Firefox a few times the option
would be `f  e  e  e  e`. Also, if you find that example very verbose: Remember
that you’re using a programming language! Write a small helper function that
suits your needs.

Note: If you produce conflicting keyboard shortcuts, the order of your code does
not matter. The command that comes first in VimFx’s options page in the Add-ons
Manager (and in the Keyboard Shortcuts help dialog) gets the shortcut; the other
one(s) do(es) not. See the notes about order in [mode object], [category object]
and [command object] for more information about order.

```js
// Even though we set the shortcut for focusing the search bar last, the command
// for focusing the location bar “wins”, because it comes first in VimFx’s
// options page in the Add-ons Manager.
vimfx.set('mode.normal.focus_location_bar', 'ö')
vimfx.set('mode.normal.focus_search_bar', 'ö')

// Swapping their orders also swaps the “winner”.
let {commands} = vimfx.modes.normal
;[commands.focus_location_bar.order, commands.focus_search_bar.order] =
  [commands.focus_search_bar.order, commands.focus_location_bar.order]
```

### `vimfx.addCommand(options, fn)`

Creates a new command.

`options`:

- name: `String`. The name used when accessing the command via
  `vimfx.modes[options.mode].commands[options.name]`. It is also used for the
  option name (preference key) used to store the shortcuts for the command:
  `` `custom.mode.${options.mode}.${options.name}` ``.
- description: `String`. Shown in the Keyboard Shortcuts help dialog and VimFx’s
  options page in the Add-ons Manager.
- mode: `String`. Defaults to `'normal'`. The mode to add the command to. The
  value has to be one of the keys of [`vimfx.modes`].
- category: `String`. Defaults to `'misc'` for Normal mode and `''`
  (uncategorized) otherwise. The category to add the command to. The
  value has to be one of the keys of [`vimfx.get('categories')`][categories].
- order: `Number`. Defaults to putting the command at the end of the category.
  The first of the default commands has the order `100` and then they increase
  by `100` per command. This allows to put new commands between two already
  existing ones.

`fn` is called when the command is activated. See the [onInput] documentation
below for more information.

<strong id="custom-command-shortcuts">Note</strong> that you have to give the
new command a shortcut in VimFx’s options page in the Add-ons Manager or set
one using `vimfx.set(...)` to able to use the new command.

```js
vimfx.addCommand({
  name: 'hello',
  description: 'Log Hello World',
}, () => {
  console.log('Hello World!')
})
// Optional:
vimfx.set('custom.mode.normal.hello', 'gö')
```

### `vimfx.addOptionOverrides(...)` and `vimfx.addKeyOverrides(...)`

These methods take any number of arguments. Each argument is a rule. The rules
are added in order. The methods may be run multiple times.

A rule is an `Array` of length 2:

1. The first item is a function that returns `true` if the rule should be
   applied and `false` if not. This is called the matching function. The
   matching function receives a [location object] as its only argument.
2. The second item is the value that should be used if the rule is applied. This
   is called the override.

The rules are tried in the same order they were added. When a matching rule is
found it is applied. No more rules will be applied.

#### `vimfx.addOptionOverrides(...rules)`

The rules are matched any time the value of a VimFx option is needed.

The override is an object whose keys are VimFx option names and whose values
override the option in question. The values should be formatted as in an
[options object].

```js
vimfx.addOptionOverrides(
  [ ({hostname, pathname, hash}) =>
    `${hostname}${pathname}${hash}` === 'google.com/',
    {prevent_autofocus: false}
  ]
)

vimfx.addOptionOverrides(
  [ ({hostname}) => hostname === 'imgur.com',
    {
      pattern_attrs: ['class'],
      pattern_selector: 'div.next-prev .btn',
      prev_patterns: [/\bnavPrev\b/],
      next_patterns: [/\bnavNext\b/],
    }
  ]
)
```

#### `vimfx.addKeyOverrides(...rules)`

The rules are matched any time you press a key that is not part of the tail of a
multi-key Normal mode shortcut.

The override is an array of keys which should not activate VimFx commands but be
sent to the page.

This allows to disable commands on specific sites. To _add_ commands on specific
sites, add them globally and then disable them on all _other_ sites.

```js
vimfx.addKeyOverrides(
  [ location => location.hostname === 'facebook.com',
    ['j', 'k']
  ]
)
```

### `vimfx.send(vim, message, data = null, callback = null)`

Send `message` (a string) to the instance of `frame.js` in the tab managed by
[`vim`][vim object], and pass it `data`. `frame.js` uses its
[`vimfx.listen(...)`] method to listen for (and optionally respond to)
`message`.

If provided, `callback` must be a function. That function will receive a single
argument: The data that `frame.js` responds with.

Here is an example:

```js
// config.js
// You get a `vim` instance by using `vimfx.addCommand(...)` or `vimfx.on(...)`.
vimfx.send(vim, 'getSelection', {example: 5}, selection => {
  console.log('Currently selected text:', selection)
})
```

```js
// frame.js
vimfx.listen('getSelection', ({example}, callback) => {
  console.log('`example` should be 5:', example)
  // `content` is basically the same as the `window` of the page.
  let selection = content.getSelection().toString()
  callback(selection)
})
```

What if you want to do it the other way around: Send a message _from_ `frame.js`
and listen for it in `config.js`? That’s not the common use case, so VimFx does
not provide convenience functions for it. `vimfx.send(...)`, and
`vimfx.listen(...)` in `frame.js`, are just light wrappers around the standard
Firefox [Message Manager] to make it easier to create custom commands that ask
`frame.js` for information about the current web page (as in the above example).
If you want to send messages any other way, you’ll need to use the Message
Manager directly. See [the `shutdown` event] for an example.

(While it would have made sense to provide `vim.send(message, data, callback)`
instead of `vimfx.send(vim, message, data, callback)`, the latter was chosen for
symmetry between `config.js` and `frame.js`. Use `vimfx.send()` to send
messages, and `vimfx.listen()` to listen for them.)

### `vimfx.on(eventName, listener)` and `vimfx.off(eventName, listener)`

After calling `vimfx.on(eventName, listener)`, `listener(data)` will be called
when `eventName` is fired, where `data` is an object. Which properties `data`
has is specific to each event.

You may use `vimfx.off(eventName, listener)` if you’d like to remove your
added listener for some reason.

While [`vimfx.send(...)`] and [`vimfx.listen(...)`] are all about passing
messages between `config.js` and `frame.js`, `vimfx.on(...)` is all about doing
something whenever VimFx emits internal events.

#### The `locationChange` event

Occurs when opening a new tab, navigating to a new URL or refreshing the page,
causing a full page load.

`data`:

- vim: The current [vim object].
- location: A [location object].

This event can be used to enter a different mode by default on some pages (which
can be used to replace the blacklist option).

```js
vimfx.on('locationChange', ({vim, location}) => {
  if (location.hostname === 'example.com') {
    vimfx.modes.normal.commands.enter_mode_ignore.run({vim, blacklist: true})
  }
})
```

#### The `notification` and `hideNotification` events

The `notification` event occurs when `vim.notify(message)` is called, and means
that `message` should be displayed to the user.

The `hideNotification` event occurs when the `vim.hideNotification()` is called,
and means that the current notification is requested to be hidden.

`data`:

- vim: The current [vim object].
- message: The message that should be notified. Only for the `notification`
  event.

Both of these events are emitted even if the [`notifications_enabled`] option is
disabled, allowing you to display notifications in any way you want.

#### The `modeChange` event

Occurs whenever the current mode in any tab changes. The initial entering of the
default mode in new tabs also counts as a mode change.

`data`:

- vim: The current [vim object].

```js
vimfx.on('modeChange', ({vim}) => {
  let mode = vimfx.modes[vim.mode].name
  vim.notify(`Entering mode: ${mode}`)
})
```

#### The `TabSelect` event

Occurs whenever any tab in any window is selected. This is also fired when
Firefox starts for the currently selected tab.

`data`:

- event: The `event` object passed to the standard Firefox [TabSelect] event.

#### The `modeDisplayChange` event

This is basically a combination of the `modeChange` and the `TabSelect` events.
The event is useful for knowing when to update UI showing the current mode.

`data`:

- vim: The current [vim object].

(VimFx itself uses this event to update the toolbar [button], by setting
`#main-window[vimfx-mode]` to the current mode. You may use this with custom
[styling].)

#### The `focusTypeChange` event

Occurs when focusing or blurring any element. See also the [`blur_timeout`]
option.

`data`:

- vim: The current [vim object].

`data.vim.focusType` has been updated just before this event fires.

(VimFx itself uses this event to update the toolbar [button], by setting
`#main-window[vimfx-focus-type]` to the current focus type. You may use this
with custom [styling].)

#### The `shutdown` event

Occurs when:

- VimFx shuts down: When Firefox shuts down, when VimFx is disabled or when
  VimFx is updated.
- When the config file is reloaded using the `gC` command.

`data`: No data at all is passed.

If you care about that things you do in `config.js` and `frame.js` are undone
when any of the above happens, read on.

If all you do is using the methods of the `vimfx` object, you shouldn’t need to
care about this event.

The following methods don’t need any undoing:

- `vimfx.get(...)`
- `vimfx.getDefault(...)`
- `vimfx.send(...)`
- `vimfx.off(...)`

The following methods are automatically undone when the `shutdown` event fires.
This means that if you, for example, add a custom command in `config.js` but
then remove it from `config.js` and hit `gC`, the custom command will be gone in
VimFx.

- `vimfx.set(...)`
- `vimfx.addCommand(...)`
- `vimfx.addOptionOverrides(...)`
- `vimfx.addKeyOverrides(...)`
- `vimfx.on(...)`

The following require manual undoing:

- `vimfx.mode`. Any changes you do here must be manually undone.

If you add event listeners in `frame.js`, here’s an example of how to remove
them on `shutdown`:

```js
// config.js
vimfx.on('shutdown', () => {
  Components.classes['@mozilla.org/globalmessagemanager;1']
    .getService(Components.interfaces.nsIMessageListenerManager)
    // Send this message to _all_ frame scripts.
    .broadcastAsyncMessage('VimFx-config:shutdown')
})
```

```js
// frame.js
let listeners = []
function listen(eventName, listener) {
  addEventListener(eventName, listener, true)
  listeners.push([eventName, listener])
}

listen('focus', event => {
  console.log('focused element', event.target)
})

addMessageListener('VimFx-config:shutdown', () => {
  listeners.forEach(([eventName, listener]) => {
    removeMessageListener(eventName, listener, true)
  })
})
```

### `vimfx.modes`

An object whose keys are mode names and whose values are [mode object]s.

This is a very low-level part of the API. It allows to:

- Access all commands and run them. This is the most common thing that a config
  file user needs it for.

  ```js
    let {commands} = vimfx.modes.normal
    // Inside a custom command:
    commands.tab_new.run(args)
  ```

- Adding new commands. It is recommended to use the `vimfx.addCommand(...)`
  helper instead. It’s easier.

  ```js
  vimfx.modes.normal.commands.new_command = {
    pref: 'extensions.my_extension.mode.normal.new_command',
    category: 'misc',
    order: 10000,
    description: translate('mode.normal.new_command'),
    run: args => console.log('New command! args:', args)
  }
  ```

- Adding new modes. This is the most advanced customization you can do to VimFx.
  Expect having to read VimFx’s source code to figure it all out.

  ```js
  vimfx.modes.new_mode = {
    name: translate('mode.new_mode'),
    order: 10000,
    commands: {},
    onEnter(args) {},
    onLeave(args) {},
    onInput(args, match) {
      switch (match.type) {
        case 'full':
          match.command.run(args)
          return true
        case 'partial':
        case 'count':
          return true
      }
      return false
    },
  }
  ```

Have a look at [modes.coffee] and [commands.coffee] for more information.

### `vimfx.get('categories')`

An object whose keys are category names and whose values are [category object]s.

```js
let categories = vimfx.get('categories')

// Add a new category.
categories.custom = {
  name: 'Custom commands',
  order: 10000,
}

// Swap the order of the Location and Tabs categories.
;[commands.focus_location_bar.order, categories.tabs.order] =
  [categories.tabs.order, commands.focus_location_bar.order]
```

### Custom hint commands

Apart from the standard hint commands, you can create your own.

You may run any VimFx command by using the following pattern:

```js
// config.js
vimfx.addCommand({
  name: 'run_other_command_example',
  description: 'Run other command example',
}, (args) => {
  // Replace 'follow' with any command name here:
  vimfx.modes.normal.commands.follow.run(args)
})
```

All hint commands (except `eb`) also support `args.callbackOverride`:

```js
// config.js
vimfx.addCommand({
  name: 'custom_hint_command_example',
  description: 'Custom hint command example',
}, (args) => {
  vimfx.modes.normal.commands.follow.run(Object.assign({}, args, {
    callbackOverride({type, href, id, timesLeft}) {
      console.log('Marker data:', {type, href, id, timesLeft})
      return (timesLeft > 1)
    },
  }))
})
```

This lets you piggy-back on one of the existing hint commands by getting the
same hints on screen as that command, but then doing something different with
the matched hint marker.

`callbackOverride` is called with an object with the following properties:

- type: `String`. The type of the element of the matched hint marker. See
  [`vimfx.setHintMatcher(...)`] for all possible values.

- href: `String` or `null`. If `type` is `'link'`, then this is the `href`
  attribute of the element of the matched hint marker.

- id: An id that you can pass to [`vimfx.getMarkerElement(...)`] to get the
  element of the matched hint marker.

- timesLeft: `Number`. Calling a hint command with a count means that you want
  to run it _count_ times in a row. This number tells how many times there are
  left to run. If you don’t provide a count, the number is `1`.

`callbackOverride` should return `true` if you want the hint markers to
re-appear on screen after you’ve matched one of them (as in the `af` command),
and `false` if you wish to exit Hints mode. If your command ignores counts,
simply always return `false`. Otherwise you most likely want to return
`timesLeft > 1`.

Here’s an example which adds a silly command for marking links with
color—`http://` links with red and all other links with green.

```js
// config.js
let {commands} = vimfx.modes.normal

vimfx.addCommand({
  name: 'mark_link',
  category: 'browsing',
  description: 'Mark link with red or green',
}, (args) => {
  let {vim} = args
  commands.follow_in_tab.run(Object.assign({}, args, {
    callbackOverride({type, href, id, timesLeft}) {
      if (href) {
        let color = href.startsWith('http://') ? 'red' : 'green'
        vimfx.send(vim, 'highlight_marker_element', {id, color})
      }
      return false
    },
  }))
})
```

```js
// frame.js
vimfx.listen('highlight_marker_element', ({id, color}) => {
  let element = vimfx.getMarkerElement(id)
  if (element) {
    element.style.backgroundColor = color
  }
})
```

### Mode object

A mode is an object with the following properties:

- name: `String`. A human readable name of the mode used in the Keyboard
  Shortcuts help dialog and VimFx’s options page in the Add-ons Manager. Config
  file users adding custom modes could simply use a hard-coded string; extension
  authors are encouraged to look up the name from a locale file.
- order: `Number`. The first of the default modes has the order `100` and then
  they increase by `100` per mode. This allows to put new modes between two
  already existing ones.
- commands: `Object`. The keys are command names and the values are [command
  object]s.
- onEnter(data, ...args): `Function`. Called when the mode is entered.
- onLeave(data): `Function`. Called when the mode is left.
- onInput(data, match): `Function`. Called when a key is pressed.

#### onEnter, onLeave and onInput

These methods are called with an object (called `data` above) with the following
properties:

- vim: The current [vim object].
- storage: An object unique to the current [vim object] and to the current mode.
  Allows to share things between commands of the same mode by getting and
  setting keys on it.

##### onEnter

This method is called with an object as mentioned above, and after that there
may be any number of arguments that the mode is free to do whatever it wants
with.

##### onInput

The object passed to this method (see above) also has the following properties:

- event: `Event`. The keydown event object.
- count: `Number`. The count for the command. `undefined` if no count. (This is
  simply a copy of `match.count`. `match` is defined below.)

The above object should be passed to commands when running them. The mode is
free to do whatever it wants with the return value (if any) of the commands it
runs.

It also receives a [match object] as the second argument.

`onInput` should return `true` if the current keypress should not be passed on
to the browser and web pages, and `false` otherwise.

### Category object

A category is an object with the following properties:

- name: `String`. A human readable name of the category used in the Keyboard
  Shortcuts help dialog and VimFx’s options page in the Add-ons Manager. Config
  file users adding custom categories could simply a use hard-coded string;
  extension authors are encouraged to look up the name from a locale file.
- order: `Number`. The first of the default categories is the “uncategorized”
  category. It has the order `100` and then they increase by `100` per category.
  This allows to put new categories between two already existing ones.

### Command object

A command is an object with the following properties:

- pref: `String`. The option name (preference key) used to store the shortcuts
  for the command.
- run(args): `Function`. Called when the command is activated.
- description: `String`. A description of the command, shown in the Keyboard
  Shortcuts help dialog and VimFx’s options page in the Add-ons Manager. Config
  file users adding custom commands could simply use a hard-coded string;
  extension authors are encouraged to look up the name from a locale file.
- category: `String`. The category to add the command to. The value has to be
  one of the keys of [`vimfx.get('categories')`][categories].
- order: `Number`. The first of the default commands has the order `100` and
  then they increase by `100` per command. This allows to put new commands
  between two already existing ones.

### Match object

A `match` object has the following properties:

- type: `String`. It has one of the following values:

  - `'full'`: The current keypress, together with previous keypresses, fully
    matches a command shortcut.
  - `'partial'`: The current keypress, together with previous keypresses,
    partially matches a command shortcut.
  - `'count'`: The current keypress is not part of a command shortcut, but is a
    digit and contributes to the count of a future matched command.
  - `'none'`: The current keypress is not part of a command shortcut and does
    not contribute to a count.

- likelyConflict: `Boolean`. This is `true` if the current keypress is likely to
  cause conflicts with default Firefox behavior of that key, and `false`
  otherwise. A mode might not want to run commands and suppress the event if
  this value is `true`. VimFx uses the current keypress and `vim.focusType` of
  the current [vim object] to decide if the current keypress is a likely
  conflict:

  1. If the key is part of the tail of a shortcut, it is never a conflict.
  2. If `vim.focusType` is `'activatable'` or `'adjustable'` and the key is
     present in [`activatable_element_keys`] or [`adjustable_element_keys`]
     (respectively), then it is a likely conflict.
  3. Finally, unless `vim.focusType` is `'none'`, then it is a likely conflict.
     This most commonly means that a text input is focused.

  Note that any VimFx shortcut starting with a keypress involving a modifier is
  _very_ likely to conflict with either a Firefox default shortcut or a shortcut
  from some other add-on. This is _not_ attempted to be detected in any way.
  Instead, VimFx uses no modifiers in any default Normal mode shortcuts, leaving
  it up to you to choose modifier-shortcuts that work out for you if you want
  such shortcuts. In other words, for modifier-shortcuts the point of VimFx _is_
  to conflict (overriding default shortcuts).

- command: `null` unless `type` is `'full'`. Then it is the matched command (a
  [command object]).

  The matched command should usually be run at this point. It is suitable to
  pass on the object passed to [onInput] to the command. Some modes might choose
  to add extra properties to the object first. (That is favored over passing
  several arguments, since it makes it easier for the command to in turn pass
  the same data it got on to another command, if needed.)

  Usually the return value of the command isn’t used, but that’s up to the mode.

- count: `Number`. The count for the command. `undefined` if no count.

- specialKeys: `Object`. The keys may be any of the following:

  - `<force>`
  - `<late>`

  If a key exists, its value is always `true`. The keys that exist indicate the
  [special keys] for the sequence used for the matched command (if any).

- keyStr: `String`. The current keypress represented as a string.

- unmodifiedKey: `String`. `keyStr` without modifiers.

- rawKey: `String`. Unchanged [`event.key`].

- rawCode: `String`. Unchanged [`event.code`].

- toplevel: `Boolean`. Whether or not the match was a toplevel match in the
  shortcut key tree. This is `true` unless the match is part of the tail of a
  multi-key shortcut.

- discard(): `Function`. Discards keys pressed so far: If `type` is `'partial'`
  or `'count'`. For example, if you have typed `12g`, run `match.discard()` and
  then press `$`, the `$` command will be run instead of `12g$`.

### Vim object

There is one `vim` object per tab.

A `vim` object has the following properties:

- window: [`Window`]. The current Firefox window object. Most commands
  interacting with Firefox’s UI use this.

- browser: [`Browser`]. The `browser` that this vim object handles.

- options: `Object`. Provides access to all of VimFx’s options. It is an
  [options object].

- mode: `String`. The current mode name.

- focusType: `String`. The type of currently focused element. VimFx decides the
  type based on how it responds to keystorkes. It has one of the following
  values:

  - `'ignore'`: Some kind of Vim-style editor. VimFx automatically
    enters Ignore mode when this focus type is encountered.
  - `'editable'`: Some kind of text input, a `<select>` element or a
    “contenteditable” element.
  - `'activatable'`: An “activatable” element (link or button).
    (See also the [`activatable_element_keys`] option.)
  - `'adjustable'`: An “adjustable” element (form control or video
    player). (See also the [`adjustable_element_keys`] option.)
  - `'findbar'`: The findbar text input is focused.
  - `'none'`: The currently focused element does not appear to respond to
    keystrokes in any special way.

  [The `focusTypeChange` event] is fired whenever `focusType` is updated.

  `match.likelyConflict` of [match object]s depend on `focusType`.

- isUIEvent(event): `Function`. Returns `true` if `event` occurred in the
  browser UI, and `false` otherwise (if it occurred in web page content).

- notify(message): `Function`. Display a notification with the text `message`.

- hideNotification(): `Function`. Hide the current notification (if any).

- markPageInteraction(value=true): `Function`. When `value` is `true` (as it is
  by default when the argument is omitted), marks that the user has interacted
  with the page. After that [autofocus prevention] is not done anymore. Commands
  interacting with web page content might want to do this. If `value` is
  `false`, the state is reset and autofocus prevention _will_ be done again.

**Warning:** There are also properties starting with an underscore on `vim`
objects. They are private, and not supposed to be used outside of VimFx’s own
source code. They may change at any time.

### Options object

An `options` object provides access to all of VimFx’s options. It is an object
whose keys are VimFx option names.

Note that the values are not just simply `vimfx.get(option)` for the `option` in
question; they are _parsed_ (`parse(vimfx.get(option))`):

- Space-separated options are parsed into arrays of strings. For example,
  `pattern_attrs: ['class']`.

- `blacklist`, `prev_patterns` and `next_patterns` are parsed into arrays of
  regular expressions. For example, `prev_patterns: [/\bnavPrev\b/]`.

(See [parse-prefs.coffee] for all details.)

Any [option overrides] are automatically taken into account when getting an
option value.

The [special options] are also available on this object.


### Location object

A location object is very similar to [`window.location`] in web pages.
Technically, it is a [`URL`] instance. You can experiment with the current
location object by opening the [web console] and entering `location`.


## `frame.js` API

In `frame.js`, the following API is available as the variable `vimfx`.

### `vimfx.listen(message, listener)`

Listen for `message` (a string) from `config.js`. `listener` will be called with
the data sent from `config.js` (if any), and optionally a callback function if
`config.js` wants you to respond. If so, call the callback function, optionally
with some data to send back to `config.js.` `config.js` uses its
[`vimfx.send(...)`] method to send  `message` (and optionally some data along
with it).

See the [`vimfx.send(...)`] method in `config.js` for more information and
examples.

### `vimfx.setHintMatcher(hintMatcher)`

`hintMatcher` is a function that lets you customize which elements do and don’t
get hints. It might help to read about [the hint commands] first.

If you call `vimfx.setHintMatcher(hintMatcher)` more than once, only the
`hintMatcher` provided the last time will be used.

```js
vimfx.setHintMatcher((id, element, type) => {
  // Inspect `element` and return a different `type` if needed.
  return type
})
```

The arguments passed to the `hintMatcher` function are:

- id: `String`. A string identifying which command is used:

  - `'normal'`: `f` or `af`.
  - `'tab'`: `F`, `et`, `ew` or `ep`.
  - `'copy'`: `yf`.
  - `'focus'`: `ef`.
  - `'context'`: `ec`.
  - `'select'`: `v`, `av` or `yv`.

- element: `Element`. One out of all elements currently inside the viewport.

- type: `String` or `null`. If a string, it means that `element` should get a
  hint. If `null`, it won’t. See the available strings below. When a marker
  is matched, `type` decides what happens to `element`.

  This parameter tells how VimFx has matched `element`. You have the opportunity
  to change that.

The available type strings depend on `id`:

- normal:

  - link: A “proper” link (not used as a button with the help of JavaScript),
    with an `href` attribute.
  - text: An element that can you can type in, such as text inputs.
  - clickable: Some clickable element not falling into another category.
  - clickable-special: Like “clickable,” but uses a different technique to
    simulate a click on the element. If “clickable” doesn’t work, try this one.
  - scrollable: A scrollable element.

- tab:

  - link: Like “link” when `id` is “normal” (see above).

- copy:

  - link: Like “link” when `id` is “normal” (see above).
  - text: Like “text” when `id` is “normal” (see above), except that in this
    case “contenteditable” elements are not included.
  - contenteditable: Elements with “contenteditable” turned on.

- focus:

  - focusable: Any focusable element not falling into another category.
  - scrollable: Like “scrollable” when `id` is “normal” (see above).

- context:

  - context: An element that can have a context menu opened.

- select:

  - selectable: An element with selectable text (but not text inputs).

The function must return `null` or a string like the `type` parameter.

### `vimfx.getMarkerElement(id)`

Takes an id that has been given to you when creating [custom hint commands] and
returns the DOM element associated with that id. If no element can be found,
`null` is returned.


## Stability

The API is currently **experimental** and therefore **unstable.** Things might
break with new VimFx versions. However, no breaking changes are planned, and
will be avoided if feasible.

As soon as VimFx 1.0.0 (which does not seem to be too far away) is released
backwards compatibility will be a priority and won’t be broken until VimFx
2.0.0.

[option overrides]: #vimfxaddoptionoverridesrules
[`vimfx.send(...)`]: #vimfxsendvim-message-data--null-callback--null
[`vimfx.listen(...)`]: #vimfxlistenmessage-listener
[categories]: #vimfxgetcategories
[custom hint commands]: #custom-hints-commands
[`vimfx.modes`]: #vimfxmodes
[onInput]: #oninput
[mode object]: #mode-object
[category object]: #category-object
[command object]: #command-object
[match object]: #match-object
[vim object]: #vim-object
[options object]: #options-object
[location object]: #location-object
[The `focusTypeChange` event]: #the-focustypechange-event
[the `shutdown` event]: #the-shutdown-event
[`vimfx.setHintMatcher(...)`]: #vimfxsethintmatcherhintmatcher
[`vimfx.getMarkerElement(...)`]: #vimfxgetmarkerelementid

[blacklisted]: options.md#blacklist
[special options]: options.md#special-options
[config file]: config-file.md
[bootstrap.js]: config-file.md#bootstrapjs
[autofocus prevention]: options.md#prevent-autofocus
[`activatable_element_keys`]: options.md#activatable_element_keys
[`adjustable_element_keys`]: options.md#adjustable_element_keys
[`blur_timeout`]: options.md#blur_timeout
[`notifications_enabled`]: options.md#notifications_enabled

[button]: button.md
[the hint commands]: commands.md#the-hint-commands--hints-mode
[special keys]: shortcuts.md#special-keys
[styling]: styling.md

[defaults.coffee]: ../extension/lib/defaults.coffee
[parse-prefs.coffee]: ../extension/lib/parse-prefs.coffee
[modes.coffee]: ../extension/lib/modes.coffee
[commands.coffee]: ../extension/lib/commands.coffee
[vim.coffee]: ../extension/lib/vim.coffee

[`event.key`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key
[`event.code`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code
[`Window`]: https://developer.mozilla.org/en-US/docs/Web/API/Window
[`Browser`]: https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XUL/browser
[`window.location`]: https://developer.mozilla.org/en-US/docs/Web/API/Location
[`URL`]: https://developer.mozilla.org/en-US/docs/Web/API/URL
[Message Manager]: https://developer.mozilla.org/en-US/Firefox/Multiprocess_Firefox/Message_Manager
[TabSelect]: https://developer.mozilla.org/en-US/docs/Web/Events/TabSelect
[web console]: https://developer.mozilla.org/en-US/docs/Tools/Web_Console
[about:config]: http://kb.mozillazine.org/About:config
