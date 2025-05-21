# Package
version       = "0.0.1"
author        = "RowDaBoat"
description   = "Nim bindings for shaderc"
license       = "ISC"

# Project Setup
bin           = @["salute"]
srcDir        = "src"
binDir        = "bin"

# Dependencies
requires "nim >= 2.0.0"
requires "futhark >= 0.15.0"

# Tasks
before build:
  exec "cd csalute && ./build.sh"
  exec "nim c -r -d:futharkRebuild -d:opirRebuild gen/generator.nim"
  exec "rm gen/generator"
