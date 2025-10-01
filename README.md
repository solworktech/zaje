# ZAJE

[![CI][badge-build]][build]
[![GoDoc][go-docs-badge]][go-docs]
[![GoReportCard][go-report-card-badge]][go-report-card]
[![License][badge-license]][license]

`zaje` is a syntax highlighter that aims to cover all your shell colouring needs. It can act as an ad hoc replacement for `cat` and, with a spot of one-line shell functions `tail` and other friends.

Sounds good? Skip ahead to the [screencast section](#asciinema-screencast-not-a-video) to see it in action.

## Motivation

Highlighting output in the shell is hardly a novel idea and its effectiveness is generally agreed to be high:)
There are other tools that provide similar functionality, for instance, `supercat` and `grc`. However, with this
project, I was looking to create a tool that can effectively replace `cat`, `tail` and other traditional utils with zero
to little effort.

### Features

- Supports over a hundred lexers for programming languages, configuration and log formats and UNIX commands (this is done using the
  [highlight Go package](https://github.com/jessp01/gohighlight))
- Can accept input as an argument as well as from an `STDIN` stream
- Can detect the lexer to use based on:
    * The file name (when acting in `cat` mode)
    * The first line of text (so it will usually work nicely when piping as well)
- Supports explicit specification of the lexer to use via a command-line arg and an `ENV` var
- Easy to deploy: since it's a Go CLI app, it's one, statically linked executable with no dynamic deps
- Easily extendable: see [Revising and adding new lexers](#adding-and-revising-lexers) for details

### Installation

If you're running a Debian or RPM based distro, the easiest way to install is by obtaining the packages from the [latest
release](https://github.com/solworktech/zaje/releases); otherwise, because `zaje` depends on lexers from the `gohighlight` package and also provides some [helper shell
functions](./utils/functions.rc), I've created [install\_zaje.sh](./install_zaje.sh) to handle its deployment.

This is a shell script and does not require Go to be installed. Simply download and invoke with no arguments:

```sh
$ curl https://raw.githubusercontent.com/jessp01/zaje/master/install_zaje.sh > install_zaje.sh
$ ./install_zaje.sh
```

If you run `install_zaje.sh` as a super user, you only need to start a new shell to get all the functionality.
Otherwise, you'll need to source the functions file (see the script's output for instructions).

Being a Golang application, you can also build it yourself with `go` get or fetch a [specific version](https://github.com/jessp01/zaje/releases).
Fetching from the master branch using `go`:

```sh
$ go install github.com/jessp01/zaje/cmd@latest
```

If you take this route, you'll need to copy the `highlight/syntax_files` and `utils/functions.rc` manually.

### Installing `super-zaje`

`super-zaje` does everything `zaje` does but provides the additional functionality of extracting text from an image. 

**NOTE**: `zaje` is capable of detecting the lexer to use based on the first line of text but with images, you'll often
need to help it and specify a designated lexer by passing `-l $NAME` (e.g: `zaje -l sh`, `zaje -l server-log`, etc).

It's a separate binary because it depends on the [gosseract](https://github.com/otiai10/gosseract) which in turn
depends on `libtesseract` and requires its SOs to be available on the machine.

First, install `zaje` using [install_zaje.sh](https://github.com/jessp01/zaje/blob/master/install_zaje.sh), and then...

#### Installing deps on Debian/Ubuntu
```sh
# apt-get install -y libtesseract-dev libleptonica-dev tesseract-ocr-eng golang-go
```

#### Installing deps on RHEL and clones
```sh
# yum install -y tesseract-devel leptonica-devel golang
```

Most popular Linux distros include the `libtesseract` package but it may be named differently. If the official repos of
your distro of choice do not have it, you can always compile it from source.

#### Installing deps on Darwin (what people mistakenly refer to as MacOS)
```sh
$ brew install tesseract
```

After installing `tesseract`, invoke the below to install `super-zaje`:

```sh
# install super-zaje
$ go install github.com/jessp01/zaje/cmd/super-zaje@latest
```

You can then use it thusly:
```sh
$ ~/go/bin/super-zaje -l sh </path/to/local/img/or/http/url>
```

For example, try:
```sh
$ ~/go/bin/super-zaje "https://github.com/jessp01/zaje/blob/master/testimg/go1.png?raw=true"
```

#### PDF inputs

PDF files are also supported by `super-zaje`. For example:

```sh
$ super-zaje --pdf  --pdf-page-number 63 /local/path/to/FORTRAN_colouring_book.pdf
```

Will convert page **64** (page numbers start from 0 in [go-fitz](https://github.com/gen2brain/go-fitz) which is used by
super-zaje) to a PNG and pass that on to [gosseract](https://github.com/otiai10/gosseract) for text extraction.

### Adding and revising lexers

See [Revising and adding new lexers](https://github.com/jessp01/gohighlight#revising-and-adding-new-lexers).

#### Supported specifiers

```yml
statement: will colour the char group green
identifier: will colour the char group blue
special: will colour the char group red
constant.string | constant | constant.number: will colour the char group cyan
constant.specialChar: will colour the char group magenta
type: will colour the char group yellow
comment: high.green will colour the char group bright green
preproc: will colour the char group bright red

```
Specifying the colour names in the YAML is also supported, see [df.yaml](https://github.com/jessp01/gohighlight/blob/master/syntax_files/df.yaml) for an example.

If your new lexer doesn't work as expected, run `zaje` with `-d` or `--debug` to get more info.



### ASCIInema screencast (Not a video!)

You can copy all text (commands, outputs, etc) straight off the player:)

[![super-zaje - extract and highlight text right off a remote image](https://asciinema.org/a/599719.svg)](https://asciinema.org/a/599719)

[![zaje - a colouriser to cover all your shell needs](https://asciinema.org/a/597732.svg)](https://asciinema.org/a/597732)

[![zaje - a colouriser to cover all your shell needs](https://asciinema.org/a/ltEfcN9sILkUFHruwQLn6rDXm.svg)](https://asciinema.org/a/ltEfcN9sILkUFHruwQLn6rDXm)

### Synopsis

```yml
NAME:
   zaje - Syntax highlighter to cover all your shell needs

USAGE:
   zaje [global options] command [command options] [input-file || - ]
   
COMMANDS:
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --syn-dir ZAJE_SYNDIR, -s ZAJE_SYNDIR  Path to lexer files. The ZAJE_SYNDIR ENV var is also honoured.
   If neither is set, ~/.config/zaje/syntax_files will be used. [$ZAJE_SYNDIR]

   --lexer value, -l value  config file to use when parsing input. 
   When none is passed, zaje will attempt to autodetect based on the file name or first line of input. 
   You can set the path to lexer files by exporting the ZAJE_SYNDIR ENV var. 
   If not exported, /etc/zaje/highlight will be used.

   --debug, -d  Run in debug mode.

   --help, -h  show help

   --print-version, -V  print only the version

   --build-info, --bi  Print build info.
 
EXAMPLES:
To use zaje as a cat replacement:
$ zaje /path/to/file

To replace tail -f:
$ tail -f /path/to/file | zaje -l server-log -
(- will make zaje read progressively from STDIN)

AUTHOR:
   Jesse Portnoy <jesse@packman.io>
   
COPYRIGHT:
   (c) packman.io

```

[license]: ./LICENSE
[badge-license]: https://img.shields.io/github/license/jessp01/zaje.svg
[go-docs-badge]: https://godoc.org/github.com/jessp01/zaje?status.svg
[go-docs]: https://godoc.org/github.com/jessp01/zaje
[go-report-card-badge]: https://goreportcard.com/badge/github.com/jessp01/zaje
[go-report-card]: https://goreportcard.com/report/github.com/jessp01/zaje
[badge-build]: https://github.com/jessp01/zaje/actions/workflows/go.yml/badge.svg
[build]: https://github.com/jessp01/zaje/actions/workflows/go.yml
