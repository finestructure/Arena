.DEFAULT_GOAL := release

export VERSION=$(shell git describe --always --tags --dirty)

clean:
	swift package clean

force-clean:
	rm -rf .build

release: version
	swift build -c release

install: release
	install .build/release/spm-playground /usr/local/bin/

version:
	# run
	# git update-index --assume-unchanged Sources/SPMPlayground/Version.swift
	# to avoid tracking changes for file
	@echo VERSION: $(VERSION)
	@echo "public let SPMPlaygroundVersion = \"$(VERSION)\"" > Sources/SPMPlayground/Version.swift
