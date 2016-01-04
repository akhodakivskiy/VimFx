<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Styling

It is possible to change the style of VimFx’s hint markers, help dialog and
button with CSS.

1. Copy rules from [style.css] into [userChrome.css] or a new [Stylish] style.

2. Make sure that the following code is at the top of the file:

   ```css
   @namespace url(http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul);
   ```

   It makes sure that your CSS only affects the browser chrome and not web
   pages.

3. Adjust the rules to your likings. Make sure to end all declarations with
   `!important` so that they override VimFx’d default styles properly.

If you use `userChrome.css` you need to restart Firefox for your changes to take
effect, while Stylish applies them instantly.

[style.css]: ../extension/skin/style.css
[userChrome.css]: http://kb.mozillazine.org/UserChrome.css
[Stylish]: https://addons.mozilla.org/firefox/addon/stylish/

## Examples

Making small adjustments to hint markers:

```css
#VimFxMarkersContainer .marker {
  font-size: 1.2em !important; /* Larger text. */
  text-transform: lowercase !important; /* Lowercase text. */
  opacity: 0.8 !important; /* Semi-transparent. Warning: Might be slow! */
}
```

To make the hint markers look like they did in version 0.5.x:

```css
/* Warning: This might slow hint generation down! */
#VimFxMarkersContainer .marker {
  padding: 1px 2px 0 2px !important;
  background-color: #FFD76E !important;
  border: solid 1px #AD810C !important;
  border-radius: 2px !important;
  box-shadow: 0 3px 7px 0 rgba(0, 0, 0, 0.3) !important;
  font-size: 12px !important;
  color: #302505 !important;
  font-family: "Helvetica Neue", "Helvetica", "Arial", "Sans" !important;
  font-weight: bold !important;
  text-shadow: 0 1px 0 rgba(255, 255, 255, 0.6) !important;
}
#VimFxMarkersContainer .marker--matched,
#VimFxMarkersContainer .marker-char--matched {
  color: #FFA22A !important;
}
```

Making the location bar red when in ignore mode (you may substitute “ignore”
with any mode name below):

```css
#main-window[vimfx-mode="ignore"] #urlbar {
    background: red !important;
}
```

(While speaking of highlighting the current mode, you might be interested in
reading about the [the `modeDisplayChange` event].)

[the `modeDisplayChange` event]: api.md#the-modedisplaychange-event
