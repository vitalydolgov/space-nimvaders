# Configuration module for Space Nimvaders

const
  # Screen dimensions
  screenWidth* = 800
  screenHeight* = 600

  # Player
  playerWidth* = 50
  playerHeight* = 50
  playerSpeed* = 5

  # Bullets
  bulletWidth* = 4
  bulletHeight* = 10
  bulletSpeed* = 10
  maxBullets* = 10

  # Invaders
  invaderWidth* = 40
  invaderHeight* = 30
  invaderRows* = 5
  invaderCols* = 11
  invaderSpeed* = 5
  invaderMoveDelay* = 30
  invaderDropDistance* = 20
  invaderStartX* = 100
  invaderStartY* = 60
  invaderSpacingX* = 60
  invaderSpacingY* = 40

  # Enemy bullets
  enemyShootDelay* = 60
  enemyShootChance* = 5
  maxEnemyBullets* = 20

  # Shields
  shieldWidth* = 80
  shieldHeight* = 40
  numShields* = 4
  shieldStartY* = 450

