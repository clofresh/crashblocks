SHELL = /bin/bash -e

NAME:=$(shell basename $(shell pwd))

MAPS := assets/maps $(shell find src_assets/maps -type f -name '*.tmx' \
									| sed -e 's/\.tmx/.lua/g'  -e 's/src_assets/assets/g')
MESHES := assets/meshes $(shell find src_assets/meshes -type f -name '*.svg' \
									| sed -e 's/\.svg/.lua/g'  -e 's/src_assets/assets/g')
IMAGES := assets/images $(shell find src_assets/images -type f -name '*.png' -or -name '*.jpg' \
									| sed -e 's/src_assets/assets/g')
SOUNDS := assets/sounds $(shell find src_assets/sounds -type f -name '*.wav' -or -name '*.ogg' -or -name '*.mp3' \
									| sed -e 's/src_assets/assets/g')
FONTS := assets/fonts $(shell find src_assets/fonts -type f -name '*.ttf' \
									| sed -e 's/src_assets/assets/g')
ASSETS := $(MAPS) $(MESHES) $(IMAGES) $(SOUNDS) $(FONTS)

CODE := $(shell find . -type f -name '*.lua')
SHADERS := $(shell find shaders -type f -name '*.vert' -or -name '*.frag')

LOVE_FILE := game.love
FULL_LOVE_FILE := ./$(LOVE_FILE)
DROPBOX_FILE := ~/Dropbox/Apps/love/$(NAME).love

default: run-desktop

assets: $(ASSETS)

assets/%:
	mkdir -p $@

assets/maps/%.lua: src_assets/maps/%.tmx
	tiled --export-map $< $@

assets/meshes/%.lua: src_assets/meshes/%.svg
	TMPFILE=$$(mktemp) && python scripts/parse_svg.py $< > $$TMPFILE && mv $$TMPFILE $@

assets/images/%: src_assets/images/%
	ln -sfn ../../$< $@

assets/sounds/%: src_assets/sounds/%
	ln -sfn ../../$< $@

assets/fonts/%: src_assets/fonts/%
	ln -sfn ../../$< $@

$(FULL_LOVE_FILE): $(ASSETS) $(CODE) $(SHADERS)
	rm -f $@
	find assets/ -type l -exec test ! -e {} \; -delete
	zip -9 -i $^ -r $@ .

run-desktop: $(ASSETS)
	love .

dropbox: $(DROPBOX_FILE)
$(DROPBOX_FILE): $(FULL_LOVE_FILE)
	cp $< $@

.PHONY: run-desktop default assets dropbox
