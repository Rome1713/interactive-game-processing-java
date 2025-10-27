class Coin extends FallingItem {
  int value = 10;
  color outerColor = color(255, 220, 100);
  color innerColor = color(255, 180, 50);
  color glowColor = color(255, 245, 180);

  Coin(float x, float y, float fallSpeed) {
    super(x, y, fallSpeed, 22);
  }

  void render() {
    // glow
    noStroke();
    for (int i = 0; i < 5; i++) {
      float t = i / 4.0;
      fill(lerpColor(glowColor, outerColor, t), 220 - i * 40);
      float size = radius * 2.6 - i * 5;
      ellipse(position.x, position.y, size, size);
    }
    // body with chunky outline
    stroke(40, 50, 80, 180);
    strokeWeight(3);
    fill(innerColor);
    ellipse(position.x, position.y, radius * 1.55, radius * 1.55);
    noStroke();
    // emboss
    fill(255, 220);
    ellipse(position.x - radius * 0.25, position.y - radius * 0.25, radius * 0.5, radius * 0.5);
    // mark
    fill(50, 80, 140);
    textAlign(CENTER, CENTER);
    textSize(12);
    text("C", position.x, position.y - 1);
  }

  void onCollect(Scoreboard scoreboard, Player player, ArrayList<Particle> particles) {
    scoreboard.collectCoin(value);
    Particle.burst(particles, position.x, position.y, color(255, 230, 140), 16, 4, 9);
  }

  void onMiss(Scoreboard scoreboard) {
    scoreboard.missCoin();
  }
}

class Gem extends FallingItem {
  int value = 25;
  color edgeColor = color(140, 220, 255);
  color coreColor = color(60, 160, 255);

  Gem(float x, float y, float fallSpeed) {
    super(x, y, fallSpeed, 24);
  }

  void render() {
    pushMatrix();
    translate(position.x, position.y);
    rotate(radians(frameCount % 360));
    noStroke();
    for (int i = 0; i < 6; i++) {
      float t = i / 5.0;
      fill(lerpColor(edgeColor, coreColor, t), 220 - i * 20);
      beginShape();
      vertex(0, -radius * 0.9 + i);
      vertex(radius * 0.8 - i, 0);
      vertex(0, radius * 0.9 - i);
      vertex(-radius * 0.8 + i, 0);
      endShape(CLOSE);
    }
    // rim outline
    noFill();
    stroke(20, 40, 70, 160);
    strokeWeight(3);
    rectMode(CENTER);
    ellipse(0, 0, radius * 1.9, radius * 1.9);
    popMatrix();
  }

  void onCollect(Scoreboard scoreboard, Player player, ArrayList<Particle> particles) {
    scoreboard.collectGem(value);
    Particle.burst(particles, position.x, position.y, color(160, 220, 255), 20, 5, 11);
  }

  void onMiss(Scoreboard scoreboard) {
    scoreboard.missCoin();
  }
}

abstract class FallingItem {
  PVector position;
  float fallSpeed;
  float radius;
  float swayOffset;
  float swayAmount;

  // squash animation on collect hit-frame
  float squash = 1.0;
  int squashTimer = 0;

  FallingItem(float x, float y, float fallSpeed, float radius) {
    position = new PVector(x, y);
    this.fallSpeed = fallSpeed;
    this.radius = radius;
    swayOffset = random(TWO_PI);
    swayAmount = random(0.2, 1.2);
  }

  void update(float speedScale) {
    position.y += fallSpeed * speedScale;
    position.x += sin(frameCount * 0.03 + swayOffset) * swayAmount;
    fallSpeed += 0.012 * speedScale;
    position.x = constrain(position.x, radius, width - radius);

    if (squashTimer > 0) {
      squashTimer--;
      float target = 0.8;
      squash = lerp(squash, target, 0.3);
      if (squashTimer == 0) squash = 1.0;
    }
  }

  boolean collidesWith(Player player) {
    float distance = dist(position.x, position.y, player.x, player.y);
    return distance < radius + player.radius * 0.75;
  }

  boolean offScreen(float screenHeight) {
    return position.y - radius > screenHeight + 10;
  }

  void hitSquash() {
    squashTimer = 8;
  }

  // render wrapper with squash
  void render() {
    pushMatrix();
    translate(position.x, position.y);
    scale(1.0 + (1.0 - squash) * 0.05, squash);
    translate(-position.x, -position.y);
    drawItem();
    popMatrix();
  }

  abstract void drawItem();
  abstract void onCollect(Scoreboard scoreboard, Player player, ArrayList<Particle> particles);
  abstract void onMiss(Scoreboard scoreboard);
}

class Bomb extends FallingItem {
  color shellColor = color(255, 90, 120);
  color fuseColor = color(255, 210, 120);

  Bomb(float x, float y, float fallSpeed) {
    super(x, y, fallSpeed, 24);
  }

  void drawItem() {
    // outer glow
    noStroke();
    for (int i = 0; i < 3; i++) {
      fill(255, 120, 160, 80 - i * 20);
      ellipse(position.x, position.y, radius * 2.8 - i * 8, radius * 2.8 - i * 8);
    }
    // body
    stroke(40, 30, 50, 180);
    strokeWeight(3);
    fill(shellColor);
    ellipse(position.x, position.y, radius * 2, radius * 2);

    // cap
    noStroke();
    fill(20, 20, 30);
    ellipse(position.x, position.y, radius * 1.2, radius * 1.2);

    // fuse
    pushMatrix();
    translate(position.x, position.y - radius * 0.9);
    stroke(80);
    strokeWeight(3);
    line(0, 0, 0, -radius * 0.6);
    noStroke();
    fill(fuseColor, random(120, 220));
    ellipse(0, -radius * 0.6, 8, 8);
    popMatrix();
  }

  void onCollect(Scoreboard scoreboard, Player player, ArrayList<Particle> particles) {
    if (player.absorbHit()) {
      scoreboard.blockedHit();
      Particle.burst(particles, position.x, position.y, color(120, 220, 255), 22, 5, 12);
    } else {
      scoreboard.hitBomb();
      Particle.burst(particles, position.x, position.y, color(255, 110, 150), 28, 6, 15);
    }
  }

  void onMiss(Scoreboard scoreboard) {
    // no penalty
  }
}

class Heart extends FallingItem {
  Heart(float x, float y, float fallSpeed) {
    super(x, y, fallSpeed, 22);
  }

  void drawItem() {
    pushMatrix();
    translate(position.x, position.y);
    float beat = sin(frameCount * 0.2) * 0.08;
    float scaleFactor = 1.0 + beat;
    scale(scaleFactor);
    noStroke();
    // glow
    for (int i = 0; i < 3; i++) {
      fill(255, 140, 170, 90 - i * 30);
      ellipse(0, 6, radius * 2.4 - i * 8, radius * 2.4 - i * 8);
    }
    // shape
    fill(255, 160, 190);
    beginShape();
    vertex(0, 6);
    bezierVertex(-radius * 0.9, -radius * 0.4, -radius * 0.9, radius * 0.6, 0, radius * 1.2);
    bezierVertex(radius * 0.9, radius * 0.6, radius * 0.9, -radius * 0.4, 0, 6);
    endShape(CLOSE);
    fill(255, 220);
    ellipse(-radius * 0.35, -radius * 0.1, radius * 0.8, radius * 0.8);
    popMatrix();
  }

  void onCollect(Scoreboard scoreboard, Player player, ArrayList<Particle> particles) {
    scoreboard.bonusLife();
    player.addShield(240);
    Particle.burst(particles, position.x, position.y, color(255, 160, 200), 22, 5, 12);
  }

  void onMiss(Scoreboard scoreboard) { }
}

/* ---------------- GLOBALS ---------------- */
Player player;
ArrayList<FallingItem> items;
ArrayList<Particle> particles;
ArrayList<Star> stars;
ArrayList<Bullet> bullets;
Scoreboard scoreboard;
PFont uiFont;
float spawnInterval = 70;
float spawnTimer = 0;
boolean isGameOver = false;

/* shooting */
int shootCooldown = 10;
int shootTimer = 0;
boolean fireHeld = false;

void setup() {
  size(720, 540);
  smooth();
  uiFont = createFont("SansSerif", 24);
  textFont(uiFont);

  player = new Player(width / 2, height - 70, 46, color(80, 180, 255));
  items = new ArrayList<FallingItem>();
  particles = new ArrayList<Particle>();
  stars = new ArrayList<Star>();
  bullets = new ArrayList<Bullet>();
  scoreboard = new Scoreboard();

  for (int i = 0; i < 70; i++) { // parallax layers
    float layer = random(1, 3);  // 1=near, 3=far
    stars.add(new Star(random(width), random(height), layer));
  }
}

void draw() {
  renderBackground();

  updateStars();
  renderStars();

  textFont(uiFont);
  scoreboard.update();

  if (!isGameOver) {
    updateGame();
  }

  updateParticles();
  updateBullets();

  renderItems();
  renderBullets();
  player.render();
  scoreboard.render();

  if (isGameOver) {
    showGameOver();
  }

  renderVignette();
}

/* ---------------- GAME LOOP ---------------- */
void updateGame() {
  spawnTimer++;
  if (spawnTimer >= spawnInterval) {
    items.add(spawnRandomItem());
    spawnTimer = 0;
    spawnInterval = max(30, spawnInterval - 0.25);
  }

  // shooting
  if (shootTimer > 0) shootTimer--;
  if ((mousePressed || fireHeld) && shootTimer == 0 && !isGameOver) {
    shootFromPlayer();
    shootTimer = shootCooldown;
  }

  player.update(mouseX);

  // items
  for (int i = items.size() - 1; i >= 0; i--) {
    FallingItem item = items.get(i);
    item.update(1);

    if (item.collidesWith(player)) {
      item.hitSquash();
      item.onCollect(scoreboard, player, particles);
      items.remove(i);
      continue;
    }

    if (item.offScreen(height)) {
      item.onMiss(scoreboard);
      items.remove(i);
    }
  }

  if (!scoreboard.hasLives()) {
    isGameOver = true;
  }
}

void shootFromPlayer() {
  float bx = player.x;
  float by = player.y - player.radius * 0.9;
  bullets.add(new Bullet(bx, by, -10));
  // muzzle flash
  Particle.burst(particles, bx, by, color(180, 230, 255), 8, 3, 6);
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.isDead()) particles.remove(i);
  }
}

/* ---------------- VISUALS ---------------- */
void renderBackground() {
  // vertical gradient
  for (int y = 0; y < height; y += 2) {
    float t = map(y, 0, height, 0, 1);
    int c = lerpColor(color(12, 18, 36), color(108, 32, 128), t);
    stroke(c);
    line(0, y, width, y);
  }
  noStroke();
}

void renderVignette() {
  // subtle radial vignette
  noStroke();
  for (int i = 0; i < 5; i++) {
    float a = 40 - i * 6;
    fill(0, a);
    ellipse(width / 2, height / 2, width + i * 120, height + i * 120);
  }
}

/* ---------------- STARS ---------------- */
void updateStars() {
  for (Star s : stars) s.update();
}

void renderStars() {
  for (Star s : stars) s.render();
}

/* ---------------- DRAW LISTS ---------------- */
void renderItems() {
  for (FallingItem item : items) item.render();
}

void renderBullets() {
  for (Bullet b : bullets) b.render();
}

/* ---------------- SPAWN ---------------- */
FallingItem spawnRandomItem() {
  float roll = random(1);
  float x = random(40, width - 40);
  if (roll < 0.6)       return new Coin(x, -40, random(2.6, 3.8));
  else if (roll < 0.8)  return new Gem(x, -40, random(2.4, 3.4));
  else if (roll < 0.93) return new Bomb(x, -50, random(3.0, 4.4));
  else                  return new Heart(x, -40, random(2.0, 3.2));
}

/* ---------------- UI ---------------- */
void showGameOver() {
  rectMode(CENTER);
  fill(12, 16, 24, 210);
  rect(width / 2 + 2, height / 2 + 3, 340, 210, 18); // drop shadow
  fill(20, 26, 42, 230);
  rect(width / 2, height / 2, 340, 210, 18);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Game Over", width / 2, height / 2 - 44);
  textSize(18);
  text("Click to play again", width / 2, height / 2 + 6);
  scoreboard.renderCentered(width / 2, height / 2 + 64);
  rectMode(CORNER);
}

void mousePressed() {
  if (isGameOver) restartGame();
  fireHeld = true;
}
void mouseReleased() { fireHeld = false; }
void keyPressed() { if (key == ' ') fireHeld = true; }
void keyReleased() { if (key == ' ') fireHeld = false; }

void restartGame() {
  items.clear();
  particles.clear();
  bullets.clear();
  scoreboard.reset();
  player.reset(width / 2);
  spawnInterval = 70;
  spawnTimer = 0;
  isGameOver = false;
}

/* ---------------- PARTICLES ---------------- */
class Particle {
  PVector position;
  PVector velocity;
  float size;
  float life;
  float maxLife;
  color baseColor;

  Particle(float x, float y, float vx, float vy, float size, float life, color baseColor) {
    this.position = new PVector(x, y);
    this.velocity = new PVector(vx, vy);
    this.size = size;
    this.life = life;
    this.maxLife = life;
    this.baseColor = baseColor;
  }

  void update() {
    position.add(velocity);
    velocity.mult(0.94);
    life--;
  }

  void render() {
    float alphaValue = map(life, 0, maxLife, 0, 255);
    alphaValue = constrain(alphaValue, 0, 255);
    noStroke();
    fill(red(baseColor), green(baseColor), blue(baseColor), alphaValue);
    ellipse(position.x, position.y, size, size);
  }

  boolean isDead() { return life <= 0; }

  static void burst(ArrayList<Particle> particles, float ox, float oy,
                    color baseColor, int count, float minSize, float maxSize) {
    for (int i = 0; i < count; i++) {
      float angle = random(TWO_PI);
      float speed = random(1.6, 3.6);
      float vx = cos(angle) * speed;
      float vy = sin(angle) * speed;
      float psize = random(minSize, maxSize);
      float plife = random(28, 46);
      particles.add(new Particle(ox, oy, vx, vy, psize, plife, baseColor));
    }
  }
}

/* ---------------- PLAYER ---------------- */
class Player {
  float x;
  float y;
  float radius;
  color baseColor;
  ArrayList<PVector> trail = new ArrayList<PVector>();
  int maxTrail = 16;
  float shieldTimer = 0;

  Player(float x, float y, float radius, color baseColor) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.baseColor = baseColor;
  }

  void update(float targetX) {
    float desired = constrain(targetX, radius, width - radius);
    x = lerp(x, desired, 0.25);

    trail.add(0, new PVector(x, y));
    if (trail.size() > maxTrail) trail.remove(trail.size() - 1);

    if (shieldTimer > 0) shieldTimer--;
  }

  void render() {
    // trail
    for (int i = trail.size() - 1; i >= 0; i--) {
      float factor = (i + 1) / float(maxTrail + 1);
      float alphaValue = trail.size() > 1 ? map(i, trail.size() - 1, 0, 40, 220) : 200;
      float size = lerp(radius * 0.6, radius * 1.6, factor);
      PVector p = trail.get(i);
      noStroke();
      fill(80, 170, 255, alphaValue * 0.6);
      ellipse(p.x, p.y, size, size);
    }

    // core body with glow rings
    noStroke();
    for (int i = 6; i >= 0; i--) {
      float t = i / 6.0;
      int shade = lerpColor(color(40, 120, 255), baseColor, t);
      float size = radius * 2.0 - i * 4;
      fill(shade, 240 - i * 20);
      ellipse(x, y, size, size);
    }
    fill(255, 220);
    ellipse(x - radius * 0.3, y - radius * 0.3, radius * 0.7, radius * 0.7);

    // shield
    if (shieldTimer > 0) {
      float pulse = sin(frameCount * 0.3) * 2;
      noFill();
      stroke(140, 230, 255, 200);
      strokeWeight(3);
      ellipse(x, y, radius * 2.8 + pulse, radius * 2.8 + pulse);
      noStroke();
    }
  }

  void addShield(float duration) {
    shieldTimer = max(shieldTimer, duration);
  }

  boolean absorbHit() {
    if (shieldTimer > 0) {
      shieldTimer = 0;
      return true;
    }
    return false;
  }

  void reset(float startX) {
    x = startX;
    y = height - 70;
    trail.clear();
    shieldTimer = 0;
  }
}

/* ---------------- SCOREBOARD ---------------- */
class Scoreboard {
  int score = 0;
  int lives = 3;
  int streak = 0;
  int bestStreak = 0;
  float multiplier = 1;
  String statusText = "";
  color statusColor = color(255);
  int statusTimer = 0;
  int statusTimerMax = 110;

  void update() {
    if (statusTimer > 0) {
      statusTimer--;
      if (statusTimer == 0) statusText = "";
    }
  }

  void collectCoin(int value) { addScore(value, "Coin", color(255, 240, 150)); }
  void collectGem(int value)  { addScore(value, "Gem", color(170, 220, 255)); }

  void addScore(int baseValue, String label, color messageColor) {
    streak++;
    bestStreak = max(bestStreak, streak);
    multiplier = min(5, 1 + streak / 4.0);
    int gained = round(baseValue * multiplier);
    score += gained;
    showStatus(label + " +" + gained, messageColor);
  }

  void missCoin() {
    streak = 0;
    multiplier = 1;
    score = max(0, score - 5);
    showStatus("Missed! Combo lost", color(255, 200, 120));
  }

  void hitBomb() {
    lives = max(0, lives - 1);
    streak = 0;
    multiplier = 1;
    score = max(0, score - 15);
    showStatus("Boom! -1 life", color(255, 130, 150));
  }

  void defuseBomb() {
    score += 5;
    showStatus("Bomb defused +5", color(200, 240, 255));
  }

  void blockedHit() { showStatus("Shield saved you!", color(160, 230, 255)); }

  void bonusLife() {
    lives = min(5, lives + 1);
    score += 30;
    showStatus("Heart +1 life", color(255, 190, 210));
  }

  void reset() {
    score = 0;
    lives = 3;
    streak = 0;
    bestStreak = 0;
    multiplier = 1;
    statusText = "";
    statusColor = color(255);
    statusTimer = 0;
  }

  boolean hasLives() { return lives > 0; }

  void render() {
    rectMode(CORNER);
    noStroke();
    // soft card + shadow
    fill(0, 0, 0, 80);
    rect(18, 18, 244, 144, 18);
    fill(12, 16, 26, 200);
    rect(16, 16, 244, 144, 18);

    fill(255);
    textAlign(LEFT, TOP);
    textSize(22);
    text("Score", 32, 30);
    textAlign(RIGHT, TOP);
    text(score, 244, 30);

    textAlign(LEFT, TOP);
    textSize(18);
    text("Multiplier", 32, 64);
    float barWidth = 160;
    float progress = constrain((multiplier - 1) / 4.0, 0, 1);
    fill(50, 70, 120);
    rect(32, 90, barWidth, 10, 6);
    fill(120, 210, 255);
    rect(32, 90, barWidth * progress, 10, 6);
    fill(200);
    textAlign(RIGHT, TOP);
    text(nf(multiplier, 1, 1) + "x", 244, 84);

    textAlign(LEFT, TOP);
    text("Lives", 32, 112);
    float hx = 32;
    for (int i = 0; i < 5; i++) {
      float a = i < lives ? 255 : 70;
      drawHeartIcon(hx, 140, 10, a);
      hx += 26;
    }

    if (statusTimer > 0 && statusText.length() > 0) {
      float fade = map(statusTimer, 0, statusTimerMax, 0, 255);
      fill(statusColor, fade);
      textAlign(CENTER, BOTTOM);
      textSize(20);
      text(statusText, width / 2, height - 28);
    }
  }

  void renderCentered(float x, float y) {
    textAlign(CENTER, CENTER);
    textSize(20);
    fill(255);
    text("Score: " + score + "   Max streak: " + bestStreak, x, y);
  }

  void showStatus(String text, color c) {
    statusText = text;
    statusColor = c;
    statusTimer = statusTimerMax;
  }

  void drawHeartIcon(float x, float y, float size, float a) {
    pushMatrix();
    translate(x, y);
    scale(size / 20.0);
    noStroke();
    fill(255, 120, 160, a);
    beginShape();
    vertex(0, 6);
    bezierVertex(-12, -6, -12, 10, 0, 24);
    bezierVertex(12, 10, 12, -6, 0, 6);
    endShape(CLOSE);
    popMatrix();
  }
}

/* ---------------- STAR (parallax) ---------------- */
class Star {
  PVector position;
  float speed;
  float size;
  float twinkle;
  float layer; // 1 near, 3 far

  Star(float x, float y, float layer) {
    position = new PVector(x, y);
    this.layer = layer;
    resetTraits();
  }

  void resetTraits() {
    speed = map(layer, 1, 3, 1.2, 0.4);
    size = map(layer, 1, 3, 2.2, 1.1);
    twinkle = random(TWO_PI);
  }

  void update() {
    position.y += speed;
    twinkle += 0.05 / layer;
    if (position.y > height + 10) {
      position.y = -10;
      position.x = random(width);
      resetTraits();
    }
  }

  void render() {
    float alphaValue = map(sin(twinkle), -1, 1, 90, 210) / layer;
    noStroke();
    fill(180 + speed * 20, 220, 255, alphaValue);
    ellipse(position.x, position.y, size, size);
  }
}

/* ---------------- BULLETS ---------------- */
class Bullet {
  float x, y, vy;
  float r = 6;

  Bullet(float x, float y, float vy) {
    this.x = x;
    this.y = y;
    this.vy = vy;
  }

  void update() {
    y += vy;
    // collisions with items
    for (int i = items.size() - 1; i >= 0; i--) {
      FallingItem it = items.get(i);
      float d = dist(x, y, it.position.x, it.position.y);
      if (d < r + it.radius) {
        it.hitSquash();
        if (it instanceof Bomb) {
          scoreboard.defuseBomb();
          Particle.burst(particles, it.position.x, it.position.y, color(255, 190, 210), 16, 4, 8);
        } else if (it instanceof Heart) {
          ((Heart)it).onCollect(scoreboard, player, particles);
        } else if (it instanceof Coin) {
          ((Coin)it).onCollect(scoreboard, player, particles);
        } else if (it instanceof Gem) {
          ((Gem)it).onCollect(scoreboard, player, particles);
        }
        items.remove(i);
        // bullet disappears on hit
        y = -9999;
        break;
      }
    }
  }

  boolean offScreen() { return y < -20; }

  void render() {
    // bloom trail
    noStroke();
    fill(180, 230, 255, 200);
    ellipse(x, y, r, r);
    fill(120, 200, 255, 120);
    ellipse(x, y + 8, r * 0.9, r * 1.2);
  }
}

void updateBullets() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    if (b.offScreen()) bullets.remove(i);
  }
}
