# Known Bugs

Given that VimFx operates outside the bounds of what Mozilla supports, there
are some things that VimFx doesn't play along with well. This page lists
problems that affect VimFx when run on versions of Firefox we support
(latest *Release* and *ESR* versions).

## BFcache

**Affected**: Firefox >= 96  
**Solution**: `fission.bfcacheInParent;false`

VimFx is unloaded from tabs when the [bfcache] is handled in the parent
process.

The bfcache speeds up navigating back and forth through the browser history.
Mozilla moved the location of this cache from the content process into the
parent process. VimFx isn't properly restored when a page from this version of
the cache is loaded. By setting `fission.bfcacheInParent` to `false` in
`about:config` the cache can be bound to the content process again, avoiding
the bug.

<!-- Putting the bfcache into the parent process requires moving the data using
IPC between processes. It is likely that the BootstrapLoader would need to be
adapted to handle this, which is not happening unless someone else does it. -->

[bfcache]: https://web.dev/articles/bfcache

## Fission

**Affected**: Firefox >= 96  
**Workaround**: `fission.webContentIsolationStrategy;0`

With [Fission] enabled, VimFx doesn't work in out-of-process iframes.

With Fission, sometimes called *Site Isolation*, VimFx cannot place hint markers
or detect input elements inside iframes from a different domain to the top
document. We will instead enter insert mode whenever such an iframe is active.
Hit Escape or click outside the iframe to let VimFx re-gain control. Setting
`fission.webContentIsolationStrategy` to `0` in `about:config` only disables the
iframe part of Fission.

Note that as of now (Firefox 119), when `webContentIsolationStrategy` is set,
reloading a webpage causes additional entries in the history and loss of forward
history for the tab. This is tracked in [Bug 1832341]. To avoid this, disable
Fission completely by setting `fission.autostart` to `false`.

<!-- VimFx will probably never support Fission. Its architecture assumes that
all elements can be interacted with from a single point. It would require
revisiting 8a33140f and injecting a script into each frame and postMessage'ing
them instead of directly accessing elements within them. -->

[Fission]: https://wiki.mozilla.org/Project_Fission
[Bug 1832341]: https://bugzilla.mozilla.org/show_bug.cgi?id=1832341

## VimFx behaves broken after installation

**Affected**: all supported versions  
**Solution**: restart browser

For some as-of-yet undetermined reason, the addon sometimes breaks after
installation (or upgrade)<!-- possibly Gecko internals changed and the
BootstrapLoader is failing -->. Fastest way to restart Firefox is pressing
`<c-s-j>` to open the browser console, then `<c-a-r>` to restart.
