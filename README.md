# SPMPlaygrounds

SPMPlaygrounds is a macOS command line tool to create an Xcode project with a Swift Playground that's readily set up to use a Swift Package Manager library.

```
 ~  spm-playground --help
OVERVIEW: Creates an Xcode project with a Playground and an SPM library ready for use in it.

USAGE: spm-playground [options]

OPTIONS:
  --deps, -d        dependency url(s) and (optionally) version specification [default: []]
  --force           overwrite existing file/directory [default: false]
  --help, -h        Display available options [default: false]
  --library, -l     name of library to import (inferred if not provided) [default: nil]
  --name, -n        name of directory and Xcode project [default: SPM-Playground]
  --platform, -p    platform for Playground (one of 'macos', 'ios', 'tvos') [default: macos]
  --version, -v     Display tool version [default: false]
```

## Example

```
 ~  spm-playground -d https://github.com/johnsundell/plot
🔧  resolving package dependencies
📔  libraries found: Plot
✅  created project in folder 'SPM-Playground'
```

## Specifying versions

In case you want to fetch a particular revision, range of revisions, or branch, you can use a syntax similar to the one used in a `Package.swift` file. Here's what's supported and the corresponding package dependecy that it will create in the generated project:

- `-d https://github.com/johnsundell/plot@0.3.0`
  
  → `.package(url: "https://github.com/johnsundell/plot", .exact("0.3.0"))`

- `-d https://github.com/johnsundell/plot@from:0.1.0`
  
  → `.package(url: "https://github.com/johnsundell/plot", "0.1.0"..<"1.0.0")`

- `-d "https://github.com/johnsundell/plot@0.1.0..<4.0.0"`

  → `.package(url: "https://github.com/johnsundell/plot", "0.1.0"..<"4.0.0")`

- `-d https://github.com/johnsundell/plot@0.1.0...4.0.0"` 

  → `.package(url: "https://github.com/johnsundell/plot", "0.1.0"..<"4.0.1")`

- `-d https://github.com/johnsundell/plot@branch:master` 

  → `.package(url: "https://github.com/johnsundell/plot", .branch("master"))`

- `-d https://github.com/johnsundell/plot@revision:2e5574972f83bc5cdea59662986e701b86137642` 

  → `.package(url: "https://github.com/johnsundell/plot", .revision("2e5574972f83bc5cdea59662986e701b86137642"))`

Make sure to properly quote the URL if you are using the `..<` range operator.

## Importing multiple packages

You can import multiple dependencies into your Playground:

```
spm-playground -d https://github.com/johnsundell/plot https://github.com/hartbit/Yaap.git@from:1.0.0
🔧  resolving package dependencies
📔  libraries found: Plot, Yaap
✅  created project in folder 'SPM-Playground'
```

## How to build and install

You can build and install `spm-playground` via the included `Makefile` by running:

```
make install
```

This will copy the binary `spm-playground` to `/usr/local/bin`.

## Compatibility

`spm-playground` was built and tested on macOS 10.15 Catalina using Swift 5.1.3. It should work on other versions of macOS and Swift as well.
