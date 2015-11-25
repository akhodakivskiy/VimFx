<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Questions & Answers

## What does `<s-escape>` mean?

It means that you should press Escape while holding shift. In some other
programs it might be written as `Shift+Escape`, but not in VimFx’s [key
notation].

(`<s-escape>` is the default shortcut to exit Ignore mode.)

[key notation]: shortcuts.md#key-notation

## How do I disable VimFx?

If you press `i` you will enter Ignore mode. VimFx’s toolbar [button] turns red
to reflect this.

As you can see in VimFx’s Keyboard Shortcuts dialog (which you can open by
pressing `?`), Ignore mode only has two shortcuts. That means that almost all
key presses will be ignored by VimFx, and will be handled as if VimFx wasn’t
installed.

By adding `*currentdomain.com*` to the [blacklist] option you can make VimFx
start out in Ignore mode on currentdomain.com. (Set the option to `*` to make
VimFx start out in Ignore mode _everywhere._)

Finally, there’s nothing stopping you from hitting the “Disable” button in the
Add-ons Manager if you want to disable VimFx completely (just like you can with
any add-on).

[button]: button.md
[blacklist]: options.md#blacklist

## How do I get out of Ignore mode?

Either press [`<s-escape>`] or click VimFx’s toolbar [button].

[`<s-escape>`]: #what-does-s-escape-mean
[button]: button.md

## VimFx’s shortcuts work in my English layout but not in my other layout!

If you use more than one keyboard layout, such as Russian plus English, enable
the [Ignore keyboard layout] option.

[Ignore keyboard layout]: options.md#ignore-keyboard-layout

## Going back/forward doesn’t work!

Pressing `H` is like hitting the back button. Use `L` for the forward button.

`[` clicks the link labeled “Previous” on the page, and `]` the link labeled
“Next.” (See also the [Previous/Next page patterns] option.)

[Previous/Next page patterns]: options.md#previousnext-page-patterns

## How do i re-map `<escape>` to blur text inputs?

The default shortcut is actually `<force><escape>`! Don’t forget [`<force>`] at
the beginning, and your new shortcut should work fine.

[`<force>`]: shortcuts.md#force

## Will VimFx provide advanced Find features?

One VimFx’s key feauters is to embrace standard Firefox features. As long as
Firefox’s Find Bar doesn’t support for example reverse search (vim’s `?`
command) or regex search, VimFx won’t either.

The [public API] could be used, though, to integrate with another Add-on that
provides advanced Find features.

[public API]: api.md
