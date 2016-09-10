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
key presses will be ignored by VimFx, and will be handled as if VimFx wasn’t
installed.

By adding `*currentdomain.com*` to the [blacklist] option you can make VimFx
start out in Ignore mode on currentdomain.com. (Set the option to `*` to make
VimFx start out in Ignore mode _everywhere._) The quickest way to edit the
blacklist is to use the `gB` command.

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

## How do I change the font size of hint markers?

Head over to the [Styling] documentation to learn how to do that.

[Styling]: styling.md

## Going back/forward doesn’t work!

Pressing `H` is like hitting the back button. Use `L` for the forward button.

`[` clicks the link labeled “Previous” on the page, and `]` the link labeled
“Next.” (See also the [“Previous”/“Next” link patterns] option.)

[“Previous”/“Next” link patterns]: options.md#previousnext-link-patterns

## How do I re-map `<escape>` to blur text inputs?

The default shortcut is actually `<force><escape>`! Don’t forget [`<force>`] at
the beginning, and your new shortcut should work fine.

[`<force>`]: shortcuts.md#force

## Can I search in the Keyboard Shortcuts help dialog?

Yes! Pressing `/` while the help dialog is open makes a little search box appear
in the bottom-right corner of the window (instead of opening the find bar),
which is specialized at searching your keyboard shortcuts.

## Can I edit shortcuts in the Keyboard Shortcuts help dialog?

No, but clicking on any command in it opens VimFx’s settings page in the Add-ons
Manager and automatically selects the text input for that command. Tip: Use the
`eb` command to click without using the mouse.

## Can I make Hints mode work with element text?

… like the modes Vimium, Vimperator and Pentadactyl provide?

Yes! Have a look at [Filtering hints by element text] for more information.

[Filtering hints by element text]: options.md#filtering-hints-by-element-text

## Will VimFx provide advanced Find features?

One of VimFx’s key features is to embrace standard Firefox features. As long as
Firefox’s Find Bar doesn’t support for example reverse search (vim’s `?`
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
