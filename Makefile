.DEFAULT_GOAL := release

export VERSION=$(shell git describe --always --tags --dirty)
VERSION_FILE := Sources/SPMPlayground/Version.swift

clean:
	swift package clean

force-clean:
	rm -rf .build

release: version
	swift build -c release

install: release
	install .build/release/spm-playground /usr/local/bin/
	@# reset version file
	@git checkout $(VERSION_FILE)

version:
	@# run
	@# git update-index --assume-unchanged Sources/SPMPlayground/Version.swift
	@# to avoid tracking changes for file
	@echo VERSION: $(VERSION)
	@echo "public let SPMPlaygroundVersion = \"$(VERSION)\"" > $(VERSION_FILE)
