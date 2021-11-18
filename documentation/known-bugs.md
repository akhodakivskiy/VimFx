# Known Bugs

Given that VimFx operates outside the bounds of what Mozilla supports, there
are some things that VimFx doesn't play along with well. This page lists
problems that affect VimFx when run on versions of Firefox we support
(latest *Release* and *ESR* versions).

## Responsive Design Mode

**Affected**: Firefox <= 78  
**Workaround**: `devtools.responsive.browserUI.enabled;true`

Launching the (old) Responsive Design Mode breaks VimFx for this tab. The only
way to recover is to copy-paste the URL into a new tab.

The [new RDM] does not have this bug; it can be enabled by switching
`devtools.responsive.browserUI.enabled` to `true` in `about:config` in Firefox
78 ESR. There is no workaround for Firefox 68 ESR.

[new RDM]: https://mail.mozilla.org/pipermail/firefox-dev/2020-March/007397.html

## Fission

**Affected**: Firefox >= 96  
**Workaround**: `fission.webContentIsolationStrategy;0`

With [Fission] enabled, VimFx can't inspect out-of-process iframes.

With Fission, sometimes called *Site Isolation*, VimFx cannot place hint markers
or detect input elements inside iframes from a different domain to the top
document. We will instead enter insert mode whenever such an iframe is active.
Hit Escape or click outside the iframe to let VimFx re-gain control. Setting
`fission.webContentIsolationStrategy` to `0` in `about:config` only disables the
iframe part of Fission, but is available only since Firefox 94. Some Nightly
installations were opted into Fission earlier; set `fission.autostart`
to `false` if the main workaround is unavailable.

<!-- VimFx will probably never support Fission. Its architecture assumes that
all elements can be interacted with from a single point. It would require
revisiting 8a33140f and injecting a script into each frame and postMessage'ing
them instead of directly accessing elements within them. -->

[Fission]: https://wiki.mozilla.org/Project_Fission

## VimFx behaves broken after installation

**Affected**: all supported versions  
**Solution**: restart browser

For some as-of-yet undetermined reason, the addon sometimes breaks after
installation (or upgrade)<!-- possibly Gecko internals changed and the
BootstrapLoader is failing -->. Fastest way to restart Firefox is pressing
`<c-s-j>` to open the browser console, then `<c-a-r>` to restart.
