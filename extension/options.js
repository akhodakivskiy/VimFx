"use strict";

const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

window.addEventListener("load", () => {
  Services.obs.notifyObservers(document, "vimfx-options-displayed", "");
}, { once: true });

window.addEventListener("unload", () => {
  Services.obs.notifyObservers(document, "vimfx-options-hidden", "");
}, { once: true });
