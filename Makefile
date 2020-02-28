.DEFAULT_GOAL := build

VERSION := $(shell git describe --always --tags --dirty)
VERSION_FILE := Sources/ArenaCore/Version.swift

clean:
	swift package clean

force-clean:
	rm -rf .build

build: version
	swift build

test:
	swift test

release: version
	swift build -c release --disable-sandbox

install: release
	install .build/release/arena /usr/local/bin/
	@# reset version file
	@git checkout $(VERSION_FILE)

version:
	@# avoid tracking changes for file:
	@git update-index --assume-unchanged $(VERSION_FILE)
	@echo VERSION: $(VERSION)
	@echo "public let ArenaVersion = \"$(VERSION)\"" > $(VERSION_FILE)
