.DEFAULT: all
.PHONY: clean lint release

V=@

plugin_archive := VimFx.xpi

coffee_files = extension/bootstrap.coffee
coffee_files += $(shell find extension/packages -type f -name '*.coffee')

js_files = $(coffee_files:.coffee=.js)

zip_files = chrome.manifest icon.png install.rdf options.xul resources locale
zip_files += $(subst extension/,,$(js_files))

all: clean gen zip
	$(V)echo "Done dev"

release: clean gen min zip
	$(V)echo "Done release"

min: say-min $(js_files:.js=.min.js)

say-min:
	$(V)echo "Minifing js files…"

%.min.js: %.js
	$(V)uglifyjs $< --screw-ie8 -c -m -o $<

lint:
	$(V)echo "Running coffeescript lint…"
	$(V)coffeelint -f lint-config.json $(coffee_files)

zip: $(plugin_archive)

$(plugin_archive): $(addprefix extension/,$(zip_files))
	$(V)echo "Creating archive…"
	$(V)cd extension && zip -qr ../$(plugin_archive) $(zip_files)

gen: $(js_files)

$(js_files):
	$(V)echo "Generating js files…"
	$(V)coffee -c --bare $(coffee_files)

clean:
	$(V)echo "Performing clean…"
	$(V)rm -f ./$(plugin_archive)
	$(V)rm -f $(js_files)
