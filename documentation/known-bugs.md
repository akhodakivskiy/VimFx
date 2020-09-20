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

**Affected**: (future versions)
**Workaround**: `fission.autostart;false`

With [Fission] enabled, VimFx can't inspect out-of-process iframes.

Fission is not (yet) turned on by default, but can be disabled by switching
`fission.autostart` to `false` in `about:config`. A [patch is in the works] that
at least prevents VimFx from crashing, but for full OOP-iframe support it is way
too early.
<!-- As of May 2020, not even Firefox' DevTools support it, let alone other Vim
like (web)extensions. Further, I suspect that to avoid a huge rewrite of how
VimFx handles element discovery and interaction, we'd need cross-process-DOM
APIs that just don't exist right now. -->

[Fission]: https://wiki.mozilla.org/Project_Fission
[patch is in the works]: https://git.gir.st/VimFx.git/shortlog/refs/heads/fission-v2
