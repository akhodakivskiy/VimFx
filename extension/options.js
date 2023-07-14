"use strict";

const Services = globalThis.Services || ChromeUtils.import("resource://gre/modules/Services.jsm").Services;

window.addEventListener("load", () => {
  Services.obs.notifyObservers(document, "vimfx-options-displayed", "");
}, { once: true });

window.addEventListener("unload", () => {
  Services.obs.notifyObservers(document, "vimfx-options-hidden", "");
}, { once: true });
