
{.warning[UnusedImport]: off.}
{.hint[XDeclaredButNotUsed]: off.}
from std / macros import hint, warning, newLit, getSize

from std / os import parentDir

when not declared(ownSizeOf):
  macro ownSizeof(x: typed): untyped =
    newLit(x.getSize)

when not declared(hello):
  proc hello*(name: cstring): void {.cdecl, importc: "csalute_hello".}
else:
  static :
    hint("Declaration of " & "hello" & " already exists, not redeclaring")