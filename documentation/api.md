<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Public API

VimFx has a public API. It is intended to be used by:

- Users who prefer to configure things using text files.
- Users who would like to add custom commands.
- Users who would like to set [special options].
- Users who would like to make site-specific customizations.
- Extension authors who would like to extend VimFx.

VimFx users who use the public API should write a so-called [config file].

[special options]: options.md#special-options
[config file]: config-file.md


## Getting the API

```js
Components.utils.import('resource://gre/modules/Services.jsm')
let api_url = Services.prefs.getCharPref('extensions.VimFx.api_url')
Components.utils.import(api_url, {}).getAPI(vimfx => {

  // Do things with the `vimfx` object here.

})
```

You might also want to take a look at the [config file bootstrap.js
example][bootstrap.js].

[bootstrap.js]: config-file.md#bootstrapjs


## API

The following sub-sections assume that you store VimFx’s public API in a
variable called `vimfx`.

[defaults.coffee]: ../extension/lib/defaults.coffee

### `vimfx.get(pref)`

Gets the value of the VimFx pref `pref`.

You can see all prefs in [defaults.coffee].

```js
vimfx.get('hint_chars')
vimfx.get('modes.normal.follow')
```

### `vimfx.set(pref)`

Sets the value of the VimFx pref `pref`.

You can see all prefs in [defaults.coffee].

```js
vimfx.set('hint_chars', 'abcdefghijklmnopqrstuvwxyz')
vimfx.set('modes.normal.follow', vimfx.get('modes.normal.follow') + '  e');
```

### `vimfx.addCommand(options, fn)`

Creates a new command.

**Note:** This should only be used by users, not by extension authors who wish
to extend VimFx. They should add commands manually to `vimfx.modes` instead.

`options`:

- name: `String`. The name used when accessing the command via
  `vimfx.modes[options.mode].commands[options.name]`. It is also used for the
  pref used to store the shortcuts for the command:
  `` `custom.mode.${options.mode}.${options.name}` ``.
- description: `String`. Shown in the help dialog and VimFx’s settings page in
  the Add-ons Manager.
- mode: `String`. Defaults to `'normal'`. The mode to add the command to. The
  value has to be one of the keys of `vimfx.modes`.
- category: `String`. Defaults to `'misc'` for Normal mode and `''`
  (uncategorized) otherwise. The category to add the command to. The
  value has to be one of the keys of `vimfx.categories`.
- order: `Number`. Defaults to putting the command at the end of the category.
  The first of the default commands has the order `100` and then they increase
  by `100` per command. This allows to put new commands between two already
  existing ones.

`fn` is called when the command is activated. See the [`vimfx.modes`]
documentation below for more information.

Note that you have to give the new command a shortcut in VimFx’s settings page
in the Add-ons Manager or set one using `vimfx.set()` to able to use the new
command.

```js
vimfx.addCommand({
  name: 'hello',
  description: 'Log Hello World',
}, => {
  console.log('Hello World!')
})
```

[`vimfx.modes`]: #vimfxmodes

### `vimfx.addOptionOverrides(...rules)` and `vimfx.addKeyOverrides(...rules)`

Takes any number of arguments. Each argument is a rule. The rules are added in
order. The methods may be run multiple times.

A rule is an `Array` of length 2:

- The first item is a function that returns `true` if the rule should be applied
  and `false` if not. This is called the matching function.
- The second item is the value that should be used if the rule is applied. This
  is called the override.

The rules are tried in the same order they were added. When a matching rule is
found it is applied. No more rules will be applied.

#### `vimfx.addOptionOverrides(...rules)`

The rules are matched any time the value of a VimFx pref is needed.

The matching function receives a [`location`]-like object.

The override is an object whose keys are VimFx pref names and whose values
override the pref in question. Note that all space-separated prefs are parsed
into arrays of strings. `black_list` and `{prev,next}_patterns` are parsed into
arrays of regular expressions.

```js
vimfx.addOptionOverrides(
  [ ({hostname, pathname, hash}) =>
    `${hostname}${pathname}${hash}` === 'google.com/',
    {prevent_autofocus: false}
  ]
)
```

#### `vimfx.addKeyOverrides(...rules)`

The rules are matched any time you press a key that is not part of the tail of a
multi-key shortcut.

The matching function receives a [`location`]-like object as well as the current
mode.

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

[`location`]: https://developer.mozilla.org/en-US/docs/Web/API/Location

### `vimfx.on(eventName, listener)`

Runs `listener(data)` when `eventName` is fired.

The following events are available:

- load: Occurs when opening a new tab or navigating to a new URL. `data`:
  An object with the following properties:

  - vim: The current `vim` instance. Note: This is subject to change. See
    [vim.coffee] for now.
  - location: A [`location`]-like object.

This can be used to enter a different mode by default on some pages (which can
be used to replace the blacklist option).

```js
vimfx.on('load', ({vim, location}) => {
  if (location.hostname === 'example.com') {
    vim.enterMode('insert')
  }
})
```

### `vimfx.refresh()`

If you make changes to `vimfx.modes` directly you need to call `vimfx.refresh()`
for your changes to take effect.

### `vimfx.modes`

An object whose keys are mode names and whose values are modes.

A mode is an object with the follwing properties:

- name: `Function`. Returns a human readable name of the mode used in the help
  dialog and VimFx’s settings page in the Add-ons Manager.
- order: `Number`. The first of the default modes has the order `0` and then
  they increase by `100` per mode. This allows to put new modes between two
  already existing ones.
- commands: `Object`. The keys are command names and the values are commands.
- onEnter: `Function`. Called when the mode is entered.
- onLeave: `Function`. Called when the mode is left.
- onInput: `Function`. Called when a key is pressed.

The `on*` methods are called with an object with the following properties:

- `vim`: An object with state for the current tab. Note: This property is
  subject to change. For now, have a look at the [vim.coffee].
- `storage`: An object unique to the `vim` instance and to the current mode.
  Allows to share things between commands of the same mode.

The object passed to `onEnter` also has the following properties:

- `args`: `Array`. An array of extra arguments passed when entering the mode.

The object passed to `onInput` also has the following properties:

- `event`: The `keydown` event that activated the command. Note: This property
  is subject to change.
- `count`: `match.count`. `match` is defined below.

It also receives a `match` as the second argument. A `match` has the following
properties:

- type: `String`. It has one of the following values:

  - `'full'`: The current keypress fully matches a command shortcut.
  - `'partial'`: The current keypress partially matches a command shortcut.
  - `'count'`: The current keypress is not part of a command shortcut, but is a
    digit and contributes to the count of a future matched command.
  - `'none'`: The current keypress is not part of a command shortcut and does
    not contribute to a count.

- `command`: `null` unless `type` is `'full'`. Then it is the matched command.

  This command should usually be run at this point. It is suitable to pass on
  the object passed to `onInput` to the command. Some modes might choose to add
  extra properties to the object first. (That is favored over passing several
  arguments, since it makes it easier for the command to in turn pass the same
  data it got on to another command, if needed.)

  Usually the return value of the command isn’t used, but that’s up to the mode.

- `count`: `Number`. The count for the command. `undefined` if no count.

- `force`: `Boolean`. Indicates if the current key sequence started with
  `<force>`.

- `keyStr`: `String`. The current keypress represented as a string.

`onInput` should return `true` if the current keypress should not be passed on
to the browser and web pages, or `false` otherwise.

A command is an object with the following properties:

- pref: `String`. The pref used to store the shortcuts for the command.
- run: `Function`. Called when the command is activated.
- description: `Function`. Returns a description of the command, shown in the
  help dialog and VimFx’s settings page in the Add-ons Manager.
- category: `String`. The category to add the command to. The value has to be
  one of the keys of `vimfx.categories`.
- order: `Number`. The first of the default commands has the order `100` and
  then they increase by `100` per command. This allows to put new commands
  between two already existing ones.

This allows to access all commands and run them, add new commands manually and
add new modes.

```js
let {commands} = vimfx.modes.normal
// Inside a custom command:
commands.tab_new.run(args)

// Add a new command manually:
vimfx.modes.normal.commands.new_command = {
  pref: 'extensions.my_extension.mode.normal.new_command',
  category: 'misc',
  order: 10000,
  description: () => translate('mode.normal.new_command'),
  run: args => console.log('New command! args:', args)
}

// Add a new mode:
vimfx.modes.new_mode = {
  name: () => translate('mode.new_mode'),
  order: 10000,
  commands: {},
  onEnter(args) {},
  onLeave(args) {},
  onInput(args, match) {
    if (match.type === 'full') {
      match.command.run(args)
    }
    return (match.type !== 'none')
  },
}

vimfx.refresh()
```

Have a look at [modes.coffee] and [commands.coffee] for more information.

[vim.coffee]: ../extension/lib/vim.coffee
[modes.coffee]: ../extension/lib/modes.coffee
[commands.coffee]: ../extension/lib/commands.coffee

### `vimfx.categories`

An object whose keys are category names and whose values are categories.

A category is an object with the follwing properties:

- name: `Function`. Returns a human readable name of the category used in the
  help dialog and VimFx’s settings page in the Add-ons Manager. Users adding
  custom category could simply return a string; extension authors are encouraged
  to look up the name from a locale file.
- order: `Number`. The first of the default categories is the “uncategorized”
  category. It has the order `0` and then they increase by `100` per category.
  This allows to put new categories between two already existing ones.

```js
let {categories} = vimfx

// Add new category.
categories.custom = {
  name: () => 'Custom commands',
  order: 10000,
}

// Swap the order of the Location and Tabs categories.
;[categories.location.order, categories.tabs.order] =
  [categories.tabs.order, categories.location.order]
```


## Stability

The public API is currently **experimental** and therefore **unstable.** Things
might break with new VimFx versions.

As soon as VimFx 1.0.0 is released backwards compatibility will be a priority
and won’t be broken until VimFx 2.0.0.
