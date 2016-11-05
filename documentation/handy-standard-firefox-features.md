<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Handy standard Firefox features

One of VimFx’s key features is embracing standard Firefox features. That is
preferred over re-implementing similar functionality.

This section lists a few handy such standard features.


## The location bar

Firefox’s location bar is sometimes called the “Awesomebar” because it is so
powerful. Other than simply entering URLs, you can also use it to:

- Search through bookmarks. `*`
- Search through history. `^`
- Search through open tabs. `%`
- Search using search engines.

Type a lone `*`, `^` or `%` to search for _only_ bookmarks, history or tabs,
respectively. If you use this a lot, you might be interested in adding a [custom
command as a shortcut][location-bar-custom-command].

Use `<c-enter>` to open results in new tabs.

Here’s [documentation for all of the cool Awesomebar features][location-bar].

[location-bar]: http://kb.mozillazine.org/Location_Bar_search
[location-bar-custom-command]: https://github.com/akhodakivskiy/VimFx/wiki/Custom-Commands#search-bookmarks--search-open-tabs


## Menus

Use the `ec` command to open the context menu of elements. (If that fails, try
and see if the element can be focused using the `ef` command—if so, you should
be able to open the context menu using the `<menu>` key.)

Instead of clicking on menus, you can press `<a-accesskey>` where “accesskey” is
the underlined letter of the menu name. Sometimes the underlines aren’t visible
until you hold the `<alt>` key. In already open menus, you can type the access
key _without_ holding `<alt>`. If there is no access key for the menu item you
want to activate, you can usually start typing the name of the menu item to go
to it. This is a nice alternative to using the arrow keys. This is true for most
programs, not just Firefox.

Here are two examples where the above comes especially in handy for VimFx:

- You can use the `ec` command to open the context menu of an image, a link or a
  video, providing you a plethora of things to do with the focused target, such
  as saving an image or the target of a link. For videos, the access key for the
  “Play/Pause” menu item is often `p`. This allows you, for example, to control
  some video players using the keyboard.

- When using the `gH` command (which opens the back/forward button menu), or the
  `gX` command (which opens the Recently Closed Tabs menu), you can start typing
  the name of one the entries of the list to go to it (if you don’t feel like
  using the good ol’ arrow keys and `<enter>`).
