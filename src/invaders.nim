import std/strformat
import std/options
import raylib
import config

type
  Rectangle = concept c
    c.x is int
    c.y is int
    c.width is int
    c.height is int

proc intersects[A, B: Rectangle](a: A, b: B): bool =
  a.x < b.x + b.width and
  a.x + a.width > b.x and
  a.y < b.y + b.height and
  a.y + a.height > b.y

type
  Player = object
    x, y, width, height: int
    speed = 5

  Bullet = object
    x, y, width, height: int
    speed = 10
    active = false

  Invader = object
    x, y, width, height: int
    speed = 5
    alive = true

  InvaderGrid = seq[seq[Invader]]

  EnemyBullet = object
    x, y, width, height: int
    speed = 5
    active = false

  Shield = object
    x, y, width, height: int
    health = 10
    hitTimer = 0

# Iterators for invader grid
iterator invaders(grid: InvaderGrid): Invader =
  for row in grid:
    for invader in row:
      if invader.alive:
        yield invader

iterator invadersMut(grid: var InvaderGrid): var Invader =
  for row in grid.mitems:
    for invader in row.mitems:
      if invader.alive:
        yield invader

# Player
proc update(player: var Player) =
  if IsKeyDown(KEY_RIGHT):
    player.x += player.speed
  if IsKeyDown(KEY_LEFT):
    player.x -= player.speed

  if player.x < 0:
    player.x = 0
  if player.x + player.width > GetScreenWidth():
    player.x = GetScreenWidth() - player.width

proc draw(player: Player) =
  DrawRectangle(player.x, player.y, player.width, player.height, BLUE)

# Bullets
proc update(bullets: var seq[Bullet]) =
  for bullet in bullets.mitems:
    if bullet.active:
      bullet.y -= bullet.speed
      if bullet.y + bullet.height < 0:
        bullet.active = false

proc draw(bullets: seq[Bullet]) =
  for index in 0..<bullets.len:
    let bullet = bullets[index]
    if bullet.active:
      DrawRectangle(bullet.x, bullet.y, bullet.width, bullet.height, RED)

# Invaders
proc update(grid: var InvaderGrid, dx, dy: int) =
  for invader in grid.invadersMut:
    invader.x += dx
    invader.y += dy

proc draw(grid: InvaderGrid) =
  for invader in grid.invaders:
    if invader.alive:
      DrawRectangle(invader.x, invader.y, invader.width,
        invader.height, GREEN)

# Enemy bullets
proc update(bullets: var seq[EnemyBullet]) =
  for bullet in bullets.mitems:
    if bullet.active:
      bullet.y += bullet.speed
      if bullet.y > GetScreenHeight():
        bullet.active = false

proc draw(bullets: seq[EnemyBullet]) =
  for bullet in bullets:
    if bullet.active:
      DrawRectangle(bullet.x, bullet.y, bullet.width, bullet.height, YELLOW)

# Shields
proc update(shields: var seq[Shield]) =
  for shield in shields.mitems:
    if shield.hitTimer > 0:
      shield.hitTimer -= 1

proc draw(shields: seq[Shield]) =
  for shield in shields:
    if shield.health > 0:
      let color =
        if shield.hitTimer > 0:
          ORANGE
        else:
          let alpha = float32(shield.health) / 10.0
          ColorAlpha(SKYBLUE, alpha)

      DrawRectangle(shield.x, shield.y, shield.width, shield.height, color)

# Game update
type
  GameState = ref object
    player: Player
    invaderGrid: InvaderGrid
    bullets: seq[Bullet]
    enemyBullets: seq[EnemyBullet]
    shields: seq[Shield]
    invaderMoveTimer: int
    enemyShootTimer: int
    invaderDirection = 1
    score = 0
    gameEnd: Option[GameEnd]

  GameEnd = enum
    Won, GameOver

proc updateGame(state: GameState) =
  state.player.update()
  state.shields.update()

  # Periodically update invaders, change direction on hitting edge
  state.invaderMoveTimer += 1
  if state.invaderMoveTimer >= invaderMoveDelay:
    state.invaderMoveTimer = 0

    var hitEdge = false
    for invader in state.invaderGrid.invaders:
      let nextX = invader.x + (invaderSpeed * state.invaderDirection)
      if nextX < 0 or nextX + invader.width > GetScreenWidth():
        hitEdge = true
        break

    if hitEdge:
      hitEdge = false
      state.invaderDirection *= -1
      state.invaderGrid.update(invaderSpeed * state.invaderDirection,
        invaderDropDistance)
    else:
      state.invaderGrid.update(invaderSpeed * state.invaderDirection, 0)

  # Fire bullets
  if IsKeyPressed(KEY_SPACE):
    let player = state.player
    for bullet in state.bullets.mitems:
      if not bullet.active:
        bullet.x = player.x + (player.width - bullet.width) div 2
        bullet.y = player.y
        bullet.active = true
        break

  state.bullets.update()

  # Bullets kill invaders and damage shields
  for bullet in state.bullets.mitems:
    if bullet.active:
      for invader in state.invaderGrid.invadersMut:
        if bullet.intersects(invader):
          bullet.active = false
          invader.alive = false
          state.score += 10
          break

      for shield in state.shields.mitems:
        if shield.health > 0 and bullet.intersects(shield):
          bullet.active = false
          shield.health -= 1
          shield.hitTimer = 10
          break

  # Fire enemy bullets randomly
  state.enemyShootTimer += 1
  if state.enemyShootTimer >= enemyShootDelay:
    state.enemyShootTimer = 0
    for invader in state.invaderGrid.invaders:
      if GetRandomValue(0, 100) < enemyShootChance:
        for bullet in state.enemyBullets.mitems:
          if not bullet.active:
            bullet.x = invader.x + invader.width div 2 - bullet.width div 2
            bullet.y = invader.y + invader.height
            bullet.active = true
            break

  state.enemyBullets.update()

  # Enemy bullets kill player and damage shields
  for bullet in state.enemyBullets.mitems:
    if bullet.active:
      if bullet.intersects(state.player):
        bullet.active = false
        state.gameEnd = some(GameOver)
      else:
        for shield in state.shields.mitems:
          if shield.health > 0 and bullet.intersects(shield):
            bullet.active = false
            shield.health -= 1
            shield.hitTimer = 10
            break

  # Invaders destroy shields on contact
  for shield in state.shields.mitems:
    if shield.health > 0:
       for invader in state.invaderGrid.invaders:
          if invader.alive and invader.intersects(shield):
            shield.health = 0

  # Game end conditions
  var allInvadersDead = true
  for invader in state.invaderGrid.invaders:
    allInvadersDead = false
    break

  if allInvadersDead:
    state.gameEnd = some(Won)
  else:
    for invader in state.invaderGrid.invaders:
      # Collision with an invader
      if invader.intersects(state.player):
        state.gameEnd = some(GameOver)
        break
      # Invaders reached bottom
      elif invader.y + invader.height >= GetScreenHeight() - 20:
        state.gameEnd = some(GameOver)
        break

proc resetGame(state: GameState) =
  # Reset player position
  state.player.x = (screenWidth - playerWidth) div 2
  state.player.y = screenHeight - 60

  # Reset invaders
  state.invaderGrid = newSeq[seq[Invader]](invaderRows)
  for row in 0..<invaderRows:
    state.invaderGrid[row] = newSeq[Invader](invaderCols)
    for col in 0..<invaderCols:
      let invader = Invader(x: invaderStartX + col * invaderSpacingX,
        y: invaderStartY + row * invaderSpacingY, width: invaderWidth,
        height: invaderHeight)
      state.invaderGrid[row][col] = invader

  # Reset bullets
  for bullet in state.bullets.mitems:
    bullet.active = false

  # Reset enemy bullets
  for bullet in state.enemyBullets.mitems:
    bullet.active = false

  # Reset shields
  for shield in state.shields.mitems:
    shield.health = 10
    shield.hitTimer = 0

  # Reset state
  state.invaderDirection = 1
  state.invaderMoveTimer = 0
  state.enemyShootTimer = 0
  state.score = 0
  state.gameEnd = none(GameEnd)

# Program entry
when isMainModule:
  InitWindow(screenWidth, screenHeight, "Space Nimvaders!")

  # Setup state
  let player = Player(x: (screenWidth - playerWidth) div 2,
    y: screenHeight - 60, width: playerWidth, height: playerHeight)
  var state = GameState(player: player)

  # Setup shields
  state.shields = newSeq[Shield](numShields)
  let totalShieldWidth = numShields * shieldWidth
  let shieldSpacing = (screenWidth - totalShieldWidth) div (numShields + 1)
  for i in 0..<numShields:
    let shieldX = shieldSpacing + i * (shieldWidth + shieldSpacing)
    let shield = Shield(x: shieldX, y: shieldStartY, width: shieldWidth,
      height: shieldHeight)
    state.shields[i] = shield

  # Setup invaders
  state.invaderGrid = newSeq[seq[Invader]](invaderRows)
  for row in 0..<invaderRows:
    state.invaderGrid[row] = newSeq[Invader](invaderCols)
    for col in 0..<invaderCols:
      let invader = Invader(x: invaderStartX + col * invaderSpacingX,
        y: invaderStartY + row * invaderSpacingY, width: invaderWidth,
        height: invaderHeight)
      state.invaderGrid[row][col] = invader

  # Setup bullets (pool)
  state.bullets = newSeq[Bullet](maxBullets)
  for i in 0..<maxBullets:
    state.bullets[i] = Bullet(x: 0, y: 0, width: bulletWidth,
      height: bulletHeight)

  # Setup enemy bullets (pool)
  state.enemyBullets = newSeq[EnemyBullet](maxEnemyBullets)
  for i in 0..<maxEnemyBullets:
    state.enemyBullets[i] = EnemyBullet(x: 0, y: 0, width: bulletWidth,
      height: bulletHeight)

  # Render loop
  SetTargetFPS(60)

  while not WindowShouldClose():
    if state.gameEnd.isSome and IsKeyPressed(KEY_R):
      resetGame(state)

    if not state.gameEnd.isSome:
      updateGame(state)

    BeginDrawing()
    ClearBackground(BLACK)

    if state.gameEnd.isSome:
      let (gameText, gameColor) =
        case state.gameEnd.get()
        of Won:
          ("YOU WON!", GOLD)
        of GameOver:
          ("GAME OVER", RED)

      let gameTextC = cstring(gameText)
      let gameWidth = MeasureText(gameTextC, 40)
      let gameX = (GetScreenWidth() - gameWidth) div 2
      let gameY = (GetScreenHeight() div 2) - 40
      DrawText(gameTextC, gameX, gameY, 40, gameColor)

      let finalScoreText = cstring(fmt"Final Score: {state.score}")
      let finalScoreWidth = MeasureText(finalScoreText, 20)
      let finalScoreX = (GetScreenWidth() - finalScoreWidth) div 2
      let finalScoreY = gameY + 60
      DrawText(finalScoreText, finalScoreX, finalScoreY, 20, LIGHTGRAY)

      let restartText = cstring("Press R to restart")
      let restartWidth = MeasureText(restartText, 20)
      let restartX = (GetScreenWidth() - restartWidth) div 2
      let restartY = finalScoreY + 40
      DrawText(restartText, restartX, restartY, 20, LIGHTGRAY)

      EndDrawing()
      continue

    state.player.draw()
    state.invaderGrid.draw()
    state.bullets.draw()
    state.enemyBullets.draw()
    state.shields.draw()

    let titleX = (GetScreenWidth() - MeasureText("Space Nimvaders!", 20)) div 2
    DrawText("Space Nimvaders!", titleX, 20, 20, GREEN)

    let scoreText = cstring(fmt"Score: {state.score}")
    DrawText(scoreText, 20, GetScreenHeight() - 40, 20, LIGHTGRAY)

    EndDrawing()

  CloseWindow()
