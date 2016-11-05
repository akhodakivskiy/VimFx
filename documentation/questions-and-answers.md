<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Questions & Answers

## How do I disable VimFx?

If you press `i` you will enter Ignore mode. VimFx’s toolbar [button] turns red
to reflect this.

As you can see in VimFx’s Keyboard Shortcuts help dialog (which you can open by
pressing `?`), Ignore mode only has two shortcuts. That means that almost all
keypresses will be ignored by VimFx, and will be handled as if VimFx wasn’t
installed.

By adding `*currentdomain.com*` to the [blacklist] option you can make VimFx
start out in Ignore mode on currentdomain.com. (Set the option to `*` to make
VimFx start out in Ignore mode _everywhere._)

**The fastest way to edit the blacklist is to use the `gB` command.**

Finally, there’s nothing stopping you from hitting the “Disable” button in the
Add-ons Manager if you want to disable VimFx completely (just like you can with
any add-on).

[button]: button.md
[blacklist]: options.md#blacklist

## How do I get out of Ignore mode?

Either press `<s-escape>` or click VimFx’s toolbar [button].

[button]: button.md

## What does `<s-escape>` mean?

It means that you should press Escape while holding shift. In some other
programs it might be written as `Shift+Escape`, but not in VimFx’s [key
notation].

(`<s-escape>` is the default shortcut to exit Ignore mode.)

[key notation]: shortcuts.md#key-notation

## VimFx’s shortcuts work in my English layout but not in my other layout!

If you use more than one keyboard layout, such as Russian plus English, enable
the [Ignore keyboard layout] option.

[Ignore keyboard layout]: options.md#ignore-keyboard-layout

## Can I make Hints mode work with element text?

… **like Vimium, Vimperator and Pentadactyl** can?

Yes! By default, that is done by typing _uppercase_ characters (hold down
shift!). Have a look at how [hint characters] work for more information.

[hint characters]: options.md#hint-characters

## How do I change the font size of hint markers?

Head over to the [Styling] documentation to learn how to do that.

[Styling]: styling.md

## How do I re-map Escape (which blurs text inputs)?

… for example, **to ctrl+[ ?**

First off, ctrl+[ is spelled `<c-[>` in VimFx. (Tip: [`<c-q>` helps you get the
“spelling” correct automatically][helper-shortcuts].)

Secondly, the default shortcut is not just `<escape>`, but actually
`<force><escape>`! Don’t forget [`<force>`] at the beginning, and your new
shortcut should work fine. For example:

    <force><c-[>

Or, if you’d like to you both `<escape>` _and_ something else:

    <force><escape>    <force><c-[>

[`<force>`]: shortcuts.md#force

## Re-mapping Escape doesn’t always work!

There are several default shortcuts which use `<escape>`. Apart from the Normal
mode command for blurring text inputs, the Caret, Hints, Find and Marks modes
have one command each for returning to Normal mode. All of these use `<escape>`.

Perhaps you forgot to re-map some of them?

## Going back/forward doesn’t work!

Pressing `H` is like hitting the back button. Use `L` for the forward button.

`[` clicks the link labeled “Previous” on the page, and `]` the link labeled
“Next.” (See also [“Previous”/“Next” link patterns].)

[helper-shortcuts]: shortcuts.md#helper-keyboard-shortcuts
[“Previous”/“Next” link patterns]: options.md#previousnext-link-patterns

## How do I switch tabs?

There are a bunch of VimFx commands for switching tabs, such as [`J` and `K`],
[`gl`], [`gL`][gl-1] as well as [`g0`, `g^` and `g$`].

Other than that, you can use the `eb` command to click tabs using hint markers.

Firefox’s location bar also searches among your open tabs, and lets you switch
to them. By typing a lone `%` in the location bar, _only_ open tabs are searched
for. See [Handy standard Firefox features][location-bar] for more information.

Finally, there’s nothing stopping you from also using [standard Firefox tab
shortcuts]!

[`J` and `K`]: commands.md#j-k
[`gl`]: commands.md#gl
[gl-1]: commands.md#gl-1
[`g0`, `g^` and `g$`]: commands.md#g0-g-g
[location-bar]: handy-standard-firefox-features.md#the-location-bar
[standard Firefox tab shortcuts]: https://support.mozilla.org/en-US/kb/keyboard-shortcuts-perform-firefox-tasks-quickly#w_windows-tabs

## Can I search in the Keyboard Shortcuts help dialog?

Yes! Pressing `/` while the help dialog is open makes a little search box appear
in the bottom-right corner of the window (instead of opening the find bar),
which is specialized at searching your keyboard shortcuts.

## Can I edit shortcuts in the Keyboard Shortcuts help dialog?

Clicking on any command in it opens VimFx’s options page in the Add-ons Manager
and automatically selects the text input for that command. Tip: Use the `eb`
command to click without using the mouse.

## Will VimFx provide advanced Find features?

One of VimFx’s key features is to embrace standard Firefox features. As long as
Firefox’s Find Bar doesn’t support for example reverse search (Vim’s `?`
command) or regex search, VimFx won’t either.

## Switching between tabs works oddly when [NoScript] is installed!

This is a [known bug][noscript-bug] in NoScript. To work around it, either
switch to multi-process Firefox or set `noscript.clearClick.rapidFireCheck` to
`false` in [about:config].

You’re not really missing out security-wise by disabling
`noscript.clearClick.rapidFireCheck`. All it does is preventing one specific,
less common type of “clickjacking” attack, that isn’t even mentioned in
NoScript’s [ClearClick] documentation. It is, however, quickly mentionend in a
[blog post][hackademix-clickjacking] by NoScript’s author (which links to
another site explaining the attack in more detail).

See also [issue 588].

[NoScript]: https://noscript.net/
[noscript-bug]: https://forums.informaction.com/viewtopic.php?f=10&t=21597
[about:config]: http://kb.mozillazine.org/About:config
[ClearClick]: https://noscript.net/faq/#clearclick
[hackademix-clickjacking]: https://hackademix.net/2011/07/11/fancy-clickjacking-tougher-noscript/
[issue 588]: https://github.com/akhodakivskiy/VimFx/issues/588

## My question isn’t listed here!

Tell us, and we’ll add it. Let’s make this a great resource for new users.
