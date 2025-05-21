import futhark
import paths
from std/os import parentDir, `/`
from std/strutils import replace

proc rename(name: string, kind: SymbolKind, path: string, overloading: var bool): string =
  return name.replace("csalute_", "")

importc:
  outputPath srcDir/"csalute.nim"
  path csaluteDir
  renameCallback rename
  "hello.h"
