import futhark

importc:
  path "../csalute"
  "hello.h"

{.compile: "csalute/hello.c".}

when isMainModule:
  hello("Row".cstring)
