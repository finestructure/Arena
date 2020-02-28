![Swift-5.1](https://github.com/finestructure/Arena/workflows/Swift/badge.svg)

# 🏟 Arena (formerly know as SPMPlayground)

Arena is a macOS command line tool to create an Xcode project with a Swift Playground that's readily set up to use a Swift Package Manager library. You can reference both Github and local repositories. The latter is especially useful to spin up a Playground while working on a library.

```
arena --help
OVERVIEW: Creates an Xcode project with a Playground and one or more SPM libraries imported and ready for use.

USAGE: arena [--name <name>] [--libs <libs> ...] [--platform <platform>] [--force] [--outputdir <outputdir>] [--version] [<dependencies> ...]

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
  -h, --help              Show help information.
```

## Why Arena?

Arena – Spanish for "sand" – is where you battle-test your SPM packages and sand is, well, abundant in playgrounds, isn't it? 🙂

## Examples

### Import Github repository

```
arena https://github.com/finestructure/Gala
🔧  resolving package dependencies
📔  libraries found: Gala
✅  created project in folder 'SPM-Playground'
```

### Import local repository

```
arena ~/Projects/Parser
🔧  resolving package dependencies
📔  libraries found: Parser
✅  created project in folder 'SPM-Playground'
```

### Import both

```
arena ~/Projects/Parser https://github.com/finestructure/Gala
🔧  resolving package dependencies
📔  libraries found: Parser, Gala
✅  created project in folder 'SPM-Playground'
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

## How to build and install

You can build and install `arena` via the included `Makefile` by running:

```
make install
```

This will copy the binary `arena` to `/usr/local/bin`.

## Compatibility

`arena` was built and tested on macOS 10.15 Catalina using Swift 5.1.3. It should work on other versions of macOS and Swift as well.
