.DEFAULT_GOAL := build

VERSION = $(shell git describe --always --tags --dirty)
VERSION_FILE = Sources/ArenaCore/Version.swift
XCODE = /Applications/Xcode.app

clean:
	swift package clean

force-clean:
	rm -rf .build

build: version
	env DEVELOPER_DIR=$(XCODE) xcrun swift build

build-release:
	env DEVELOPER_DIR=$(XCODE) xcrun swift build -c release --disable-sandbox

test:
	env DEVELOPER_DIR=$(XCODE) xcrun swift test

release: version build-release

install: release
	install .build/release/arena /usr/local/bin/
	@# reset version file
	@git checkout $(VERSION_FILE)

version:
	@# avoid tracking changes for file:
	@git update-index --assume-unchanged $(VERSION_FILE)
	@echo VERSION: $(VERSION)
	@echo "public let ArenaVersion = \"$(VERSION)\"" > $(VERSION_FILE)
