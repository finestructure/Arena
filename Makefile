.DEFAULT_GOAL := build

export VERSION=$(shell git describe --always --tags --dirty)
VERSION_FILE := Sources/ArenaCore/Version.swift

clean:
	swift package clean

force-clean:
	rm -rf .build

build:
	swift build

test:
	swift test

release: version
	swift build -c release

install: release
	install .build/release/arena /usr/local/bin/
	@# reset version file
	@git checkout $(VERSION_FILE)

version:
	@# run
	@# git update-index --assume-unchanged $(VERSION_FILE)
	@# to avoid tracking changes for file
	@echo VERSION: $(VERSION)
	@echo "public let ArenaVersion = \"$(VERSION)\"" > $(VERSION_FILE)
