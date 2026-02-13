# Nim bindings for raylib

{.emit: """
#include "raylib.h"
""".}

type
  Color* = object
    r*: uint8  # Red
    g*: uint8  # Green
    b*: uint8  # Blue
    a*: uint8  # Alpha

  KeyboardKey* = enum
    KEY_SPACE = 32
    KEY_ENTER = 257
    KEY_RIGHT = 262
    KEY_LEFT = 263
    KEY_R = 82

# Constants
const
  LIGHTGRAY* = Color(r: 200, g: 200, b: 200, a: 255)
  RED* = Color(r: 230, g: 41, b: 55, a: 255)
  GREEN* = Color(r: 0, g: 228, b: 48, a: 255)
  BLUE* = Color(r: 0, g: 121, b: 241, a: 255)
  SKYBLUE* = Color(r: 102, g: 191, b: 255, a: 255)
  YELLOW* = Color(r: 253, g: 249, b: 0, a: 255)
  GOLD* = Color(r: 255, g: 203, b: 0, a: 255)
  ORANGE* = Color(r: 255, g: 161, b: 0, a: 255)
  BLACK* = Color(r: 0, g: 0, b: 0, a: 255)
  WHITE* = Color(r: 255, g: 255, b: 255, a: 255)
  RAYWHITE* = Color(r: 245, g: 245, b: 245, a: 255)

# Function bindings
proc InitWindow*(width: int, height: int, title: cstring) {.importc.}
proc CloseWindow*() {.importc.}
proc WindowShouldClose*(): bool {.importc.}
proc SetTargetFPS*(fps: int) {.importc.}
proc BeginDrawing*() {.importc.}
proc EndDrawing*() {.importc.}
proc ClearBackground*(color: Color) {.importc.}
proc DrawText*(text: cstring, posX: int, posY: int, fontSize: int, color: Color) {.importc.}
proc DrawRectangle*(posX: int, posY: int, width: int, height: int, color: Color) {.importc.}
proc MeasureText*(text: cstring, fontSize: int): int {.importc.}
proc GetScreenWidth*(): int {.importc.}
proc GetScreenHeight*(): int {.importc.}
proc ColorAlpha*(color: Color, alpha: float32): Color {.importc.}
proc IsKeyDown*(key: KeyboardKey): bool {.importc.}
proc IsKeyPressed*(key: KeyboardKey): bool {.importc.}
proc GetRandomValue*(min: int, max: int): int {.importc.}
