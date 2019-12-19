# SPMPlaygrounds

SPMPlaygrounds is a macOS command line tool to create an Xcode project with a Swift Playground that's readily set up to use a Swift Package Manager library.

```
 ~  spm-playground --help
OVERVIEW: Creates an Xcode project with a Playground and an SPM library ready for use in it.

USAGE: spm-playground [options]

OPTIONS:
  --force          overwrite existing file/directory [default: false]
  --from, -f       from revision [default: 0.0.0]
  --help, -h       Display available options [default: false]
  --library, -l    name of library to import (inferred if not provided) [default: nil]
  --name, -n       name of directory and Xcode project [default: SPM-Playground]
  --url, -u        package url [default: nil]
  --version, -v    Display tool version [default: false]
```

## Example

```
 ~  spm-playground -u https://github.com/johnsundell/Plot.git
ℹ️  inferred library name 'Plot' from url 'https://github.com/johnsundell/Plot.git'
✅  created project in folder 'SPM-Playground'
```