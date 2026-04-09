APP_NAME = SpotifyController
BUNDLE   = $(APP_NAME).app
BINARY   = .build/release/$(APP_NAME)
VERSION  = 0.3.0

.PHONY: icons build run dmg clean

## Generate .icns from icon.svg
icons:
	bash make-icons.sh

## Build the release binary and assemble the .app bundle
build: icons
	swift build -c release
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	cp $(BINARY) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp SpotifyController/Info.plist $(BUNDLE)/Contents/Info.plist
	cp SpotifyController.icns $(BUNDLE)/Contents/Resources/AppIcon.icns
	# Ad-hoc sign so macOS accepts the bundle (no Apple Developer account needed)
	codesign --force --deep --sign - $(BUNDLE)
	# Register the URL scheme with Launch Services
	/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
		-f $(BUNDLE)
	@echo ""
	@echo "Built: $(BUNDLE)"
	@echo "Run with: make run"

## Launch the app
run: build
	open $(BUNDLE)

## Create a distributable DMG with drag-to-Applications layout
dmg: build
	rm -rf dmg-tmp SpotifyRemote-$(VERSION).dmg
	mkdir -p dmg-tmp
	cp -r $(BUNDLE) dmg-tmp/
	ln -s /Applications dmg-tmp/Applications
	hdiutil create -volname "SpotifyRemote" \
		-srcfolder dmg-tmp \
		-ov -format UDZO \
		SpotifyRemote-$(VERSION).dmg
	rm -rf dmg-tmp
	@echo "Created SpotifyRemote-$(VERSION).dmg"

## Remove build artifacts
clean:
	rm -rf .build $(BUNDLE) SpotifyController.iconset SpotifyController.icns dmg-tmp *.dmg
