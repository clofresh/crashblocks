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

CODE := $(shell find . -type f -name '*.lua' -not -path '*packaging*')
SHADERS := $(shell find shaders -type f -name '*.vert' -or -name '*.frag')

ANDROID_DIR := packaging/love-android-sdl2
ANDROID_LOCAL_PROPERTIES := $(ANDROID_DIR)/local.properties
ANDROID_ASSETS_DIR := $(ANDROID_DIR)/app/src/main/assets
ANDROID_MANIFEST_FILE := $(ANDROID_DIR)/app/src/main/AndroidManifest.xml
TMP_LOVE_FILE := /storage/self/primary/Download/$(NAME).love
LOVE_FILE := game.love
FULL_LOVE_FILE := ./$(LOVE_FILE)
APK_FILE := $(ANDROID_DIR)/app/build/outputs/apk/app-debug.apk
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

$(ANDROID_LOCAL_PROPERTIES):
	echo 'sdk.dir = /opt/android-sdk' > $@
	echo 'ndk.dir = /opt/android-ndk' >> $@

$(ANDROID_ASSETS_DIR):
	mkdir $@

$(FULL_LOVE_FILE): $(ASSETS) $(CODE) $(SHADERS)
	rm -f $@
	find assets/ -type l -exec test ! -e {} \; -delete
	zip -9 -i $^ -r $@ .

$(APK_FILE): $(FULL_LOVE_FILE) $(ANDROID_MANIFEST_FILE) $(ANDROID_LOCAL_PROPERTIES)
	cd $(ANDROID_DIR) && gradle build

install-love: $(FULL_LOVE_FILE)
	adb push $(FULL_LOVE_FILE) $(TMP_LOVE_FILE)

run-desktop: $(ASSETS)
	love .

run-mobile: install-love
	adb shell 'am force-stop org.love2d.android; am start -d file://$(TMP_LOVE_FILE) org.love2d.android/org.love2d.android.GameActivity'

logcat:
	adb logcat -s SDL/APP:I

install-apk: $(APK_FILE)
	adb install -r $(APK_FILE)

dropbox: $(DROPBOX_FILE)
$(DROPBOX_FILE): $(FULL_LOVE_FILE)
	cp $< $@

.PHONY: install-love run-desktop run-mobile logcat install-apk default assets dropbox
