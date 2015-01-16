XCODEFLAGS=-workspace 'SourceKitten.xcworkspace' -scheme 'sourcekitten'

TEMPORARY_FOLDER=/tmp/SourceKitten.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/sourcekitten.app
SOURCEKITTEN_FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/SourceKittenFramework.framework
COMMANDANT_FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/Commandant.framework
LLAMAKIT_FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/LlamaKit.framework
SOURCEKITTEN_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/sourcekitten

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=SourceKitten.pkg

VERSION_STRING=$(shell agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=Source/sourcekitten/Components.plist

.PHONY: all bootstrap clean install package test uninstall

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build

bootstrap:
	script/bootstrap

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg SourceKitten.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/SourceKittenFramework.framework"
	rm -rf "$(FRAMEWORKS_FOLDER)/Commandant.framework"
	rm -rf "$(FRAMEWORKS_FOLDER)/LlamaKit.framework"
	rm -f "$(BINARIES_FOLDER)/sourcekitten"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(SOURCEKITTEN_FRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SourceKittenFramework.framework"
	mv -f "$(COMMANDANT_FRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Commandant.framework"
	mv -f "$(LLAMAKIT_FRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/LlamaKit.framework"
	mv -f "$(SOURCEKITTEN_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/sourcekitten"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/SourceKittenFramework.framework" "$(PREFIX)/Frameworks/"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Commandant.framework" "$(PREFIX)/Frameworks/"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/LlamaKit.framework" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/sourcekitten" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/SourceKittenFramework.framework/Versions/Current/Frameworks/"  "$(PREFIX)/bin/sourcekitten"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "com.sourcekitten.SourceKitten" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
