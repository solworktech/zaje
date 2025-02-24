zaje 1 "February 2025" zaje "User Manual"
==================================================

`zaje` is a syntax highlighter that aims to cover all your shell colouring needs. 
It can act as an ad hoc replacement for `cat` and, with a spot of one-line shell 
functions `tail` and other friends.


## Motivation

Highlighting output in the shell is hardly a novel idea and its effectiveness 
is generally agreed to be high:)
There are other tools that provide similar functionality, for instance, `supercat` and `grc`. 
However, with this project, I was looking to create a tool that can effectively replace `cat`, `tail` 
and other traditional utils with zero to little effort.

## Features

- Supports over a hundred lexers for programming languages, configuration and log formats and UNIX commands 
  (this is done using the [highlight Go package](https://github.com/jessp01/gohighlight))
- Can accept input as an argument as well as from an `STDIN` stream
- Can detect the lexer to use based on:
    * The file name (when acting in `cat` mode)
    * The first line of text (so it will usually work nicely when piping as well)
- Supports explicit specification of the lexer to use via a command-line arg and an `ENV` var
- Easily to deploy: since it's a Go CLI app, it's one, statically linked executable with no dynamic deps
- Easily extendable: see [Revising and adding new lexers](#adding-and-revising-lexers) for details

## Synopsis

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

## Adding and revising lexers

See [Revising and adding new lexers](https://github.com/jessp01/gohighlight#revising-and-adding-new-lexers).

### Supported specifiers

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
Specifying the colour names in the YML is also supported, see [df.yaml](https://github.com/jessp01/gohighlight/blob/master/syntax_files/df.yaml) for an example.

If your new lexer doesn't work as expected, run `zaje` with `-d` or `--debug` to get more info.
