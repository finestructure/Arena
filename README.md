![Swift-5.1](https://github.com/finestructure/Arena/workflows/Swift/badge.svg)
[![@_sa_s](https://img.shields.io/badge/Twitter-@_sa_s-3e8bb0.svg?style=flat)](https://twitter.com/_sa_s)

# 🏟 Arena

Arena is a macOS command line tool to create an Xcode project with a Swift Playground that's readily set up to use a Swift Package Manager library. You can reference both Github and local repositories. The latter is especially useful to spin up a Playground while working on a library.

![Arena demo](misc/Arena-demo.gif)

Arena can also create a Playground in "Playground Book" format, which is the file format supported by ["Swift Playgrounds"](https://apps.apple.com/app/swift-playgrounds/id1496833156). These playgrounds can then be synced and opened on the iOS version of "Swift Playgrounds" as well.

Here is an overview of the `arena` command line interface:

```
arena --help
OVERVIEW: Creates an Xcode project with a Playground and one or more SPM libraries imported and ready for use.

USAGE: arena [--name <name>] [--libs <libs> ...] [--platform <platform>] [--force] [--outputdir <outputdir>] [--version] [--skip-open] [--book] [<dependencies> ...]

ARGUMENTS:
  <dependencies>          Dependency url(s) and (optionally) version specification

OPTIONS:
  -n, --name <name>       Name of directory and Xcode project (default: SPM-Playground)
  -l, --libs <libs>       Names of libraries to import (inferred if not provided)
  -p, --platform <platform>
                          Platform for Playground (one of 'macos', 'ios', 'tvos') (default: macos)
  -f, --force             Overwrite existing file/directory
  -o, --outputdir <outputdir>
                          Directory where project folder should be saved (default: /Users/sas/Projects/Arena)
  -v, --version           Show version
  --skip-open             Do not open project in Xcode on completion
  --book                  Create a Swift Playgrounds compatible Playground Book bundle (experimental).
  -h, --help              Show help information.
```

## Examples

### Import Github repository

```
arena https://github.com/finestructure/Gala
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Gala
🔨 Building package dependencies ...
✅ Created project in folder 'Arena-Playground'
```

### Using Github shorthand syntax

You can skip the protocol and domain when refereing Github projects:

```
arena finestructure/Gala
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Gala
🔨 Building package dependencies ...
✅ Created project in folder 'Arena-Playground'
```


### Import local repository

```
arena ~/Projects/Parser
➡️ Package: file:///Users/sas/Projects/Parser @ path
🔧 Resolving package dependencies ...
📔 Libraries found: Parser
🔨 Building package dependencies ...
✅ Created project in folder 'Arena-Playground'
```

### Import both

```
arena ~/Projects/Parser finestructure/Gala
➡️ Package: file:///Users/sas/Projects/Parser @ path
➡️ Package: https://github.com/finestructure/Gala @ from(0.2.1)
🔧 Resolving package dependencies ...
📔 Libraries found: Parser, Gala
🔨 Building package dependencies ...
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

Arena – Spanish for "sand" – is where you battle-test your SPM packages and sand is, well, abundant in playgrounds, isn't it? 🙂

## Compatibility

`arena` was built and tested on macOS 10.15 Catalina using Swift 5.1.3. It should work on other versions of macOS and Swift as well.

Playground books created by `arena` should equally run on macOS 10.15 Catalina as well as iOS 13. Please bear in mind that the Swift packages you import when creating playground books will need to be iOS compatible.
