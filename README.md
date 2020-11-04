[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffinestructure%2FArena%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/finestructure/Arena)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffinestructure%2FArena%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/finestructure/Arena)

[![@_sa_s](https://img.shields.io/badge/Twitter-@_sa_s-3e8bb0.svg?style=flat)](https://twitter.com/_sa_s)

# 🏟 Arena

Arena is a macOS command line tool to create an Xcode project with a Swift Playground that's readily set up to use a Swift Package Manager library. You can reference both Github and local repositories. The latter is especially useful to spin up a Playground while working on a library.

![Arena demo](misc/Arena-demo-1.0.0.gif)

Arena can also create a Playground in "Playground Book" format, which is the file format supported by ["Swift Playgrounds"](https://apps.apple.com/app/swift-playgrounds/id1496833156). These playgrounds can then be synced and opened on the iOS version of "Swift Playgrounds" as well.

Here is an overview of the `arena` command line interface:

```
arena --help
OVERVIEW: Creates an Xcode project with a Playground and one or more SPM libraries imported and
ready for use.

USAGE: arena [--book] [--force] [--libs <libs> ...] [--outputdir <outputdir>] [--platform <platform>] [--version] [--skip-open] [<dependencies> ...]

ARGUMENTS:
  <dependencies>          Dependency url(s) and (optionally) version specification

OPTIONS:
  --book                  Create a Swift Playgrounds compatible Playground Book bundle
                          (experimental).
  -f, --force             Overwrite existing file/directory
  -l, --libs <libs>       Names of libraries to import (inferred if not provided)
  -o, --outputdir <outputdir>
                          Directory where project folder should be saved (default:
                          /Users/sas/Projects/Arena/Arena-Playground)
  -p, --platform <platform>
                          Platform for Playground (one of 'macos', 'ios', 'tvos') (default:
                          macos)
  -v, --version           Show version
  --skip-open             Do not open project in Xcode on completion
  -h, --help              Show help information.
```

## Examples

### Import Github repository

```
arena https://github.com/finestructure/Gala
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Gala
✅ Created project in folder 'Arena-Playground'
```

### Using Github shorthand syntax

You can skip the protocol and domain when referring to Github projects:

```
arena finestructure/Gala
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Gala
✅ Created project in folder 'Arena-Playground'
```


### Import local repository

```
arena ~/Projects/Parser
➡️ Package: file:///Users/sas/Projects/Parser @ path
🔧 Resolving package dependencies ...
📔 Libraries found: Parser
✅ Created project in folder 'Arena-Playground'
```

### Import both

```
arena ~/Projects/Parser finestructure/Gala
➡️ Package: file:///Users/sas/Projects/Parser @ path
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Parser, Gala
✅ Created project in folder 'Arena-Playground'
```

## Specifying versions

In case you want to fetch a particular revision, range of revisions, or branch, you can use a syntax similar to the one used in a `Package.swift` file. Here's what's supported and the corresponding package dependecy that it will create in the generated project:

- `https://github.com/finestructure/Gala@0.1.0`
  
  → `.package(url: "https://github.com/finestructure/Gala", .exact("0.1.0"))`

- `https://github.com/finestructure/Gala@from:0.1.0`
  
  → `.package(url: "https://github.com/finestructure/Gala", from: "0.1.0")`

- `"https://github.com/finestructure/Gala@0.1.0..<4.0.0"`

  → `.package(url: "https://github.com/finestructure/Gala", "0.1.0"..<"4.0.0")`

- `https://github.com/finestructure/Gala@0.1.0...4.0.0` 

  → `.package(url: "https://github.com/finestructure/Gala", "0.1.0"..<"4.0.1")`

- `https://github.com/finestructure/Gala@branch:master` 

  → `.package(url: "https://github.com/finestructure/Gala", .branch("master"))`

- `https://github.com/finestructure/Gala@revision:7235531e92e71176dc31e77d6ff2b128a2602110` 

  → `.package(url: "https://github.com/finestructure/Gala", .revision("7235531e92e71176dc31e77d6ff2b128a2602110"))`

Make sure to properly quote the URL if you are using the `..<` range operator. Otherwise your shell will interpret the `<` character as input redirection.

## Adding another dependency

Arena does not currently support adding further depenencies to an existing playground. However, since its dependencies are managed via the `Dependencies` package, so can simply add further entries to its `Package.swift` file - just like you would when extending any other package manifest.

Here's what this looks like:

![Adding a dependency](misc/Arena-add-dependency.gif)

## How to install Arena

### Homebrew

You can install Arena with [Homebrew](https://brew.sh):

```
brew install finestructure/tap/arena
```

### Mint

You can install Arena with [Mint](https://github.com/yonaskolb/Mint):

```
mint install finestructure/arena
```

### Make

Last not least, you can build and install `arena` via the included `Makefile` by running:

```
make install
```

This will copy the binary `arena` to `/usr/local/bin`.

## Why Arena?

Arena – Spanish for "sand" – is abundant in playgrounds. And also, sometimes you've got to take your source code to the arena for a fight 😅

## Compatibility

Starting with version 1.0, `arena` requires Xcode 12. Xcode 12 brings a number of improvements that make playgrounds work much better than previous versions of Xcode. Also, `arena` now creates a simpler project structer that can be manually edited to add more dependencies.

If you want to use `arena` with Xcode 11, please use the latest 0.x release.

Playground books created by `arena` should run on macOS as well as iOS. Please bear in mind that the Swift packages you import when creating playground books will need to be iOS compatible.

Note that while creating playgrounds requires macOS 10.15+ and Swift 5.3, the resulting playgrounds should be supported on a wider range of operating system and compiler versions. This will mainly depend on the packages you are importing.
