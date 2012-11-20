rm -f ./VimFx.xpi

coffee -c --bare \
    extension/bootstrap.coffee \
    extension/packages/*.coffee \
    extension/includes/*.coffee

cd extension
zip -r ../VimFx.xpi \
    bootstrap.js \
    icon.png \
    install.rdf \
    options.xul \
    includes/*.js \
    packages/*.js \
    resources/* \
    locale
cd ..
