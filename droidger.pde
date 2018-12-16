// import ddf.minim.*;
// Minim minim;

// // Load the sound files
// AudioSample pop, sLeft, sRight, snap0, snap1, snap2, gameover;
// AudioPlayer bg;
// boolean gameOverSoundPlayed;
// boolean muted = false;

//android gets a timer instead
int startTimer = 0;
int runDuration = 15 * 60 * 1000; //15 minutes
int enterTime; // timer for entering menus
int leaveTime; // timer for exiting menus


//prepare scaling screen to fixed resolution
PGraphics pg;
int pgWidth = 1728; //1920 * 0.9;
int pgHeight = 972; //1080 * 0.9;

PShape logo;
PShape logoOutline;

float score;
float startScore = 25;
float highScore = 0;
int totalScore = 100;
int playTime;

// game states
boolean gameOver; // goes to main menu
boolean mainMenu; // starts a new game
boolean menuDodgerInit;
float pausePenalty = 0.95; // penalty for going into pause (P key btw)

int diagBar = 0;  // sets the state of  the diagnostics bar, can be changed by num keys
float scoreRate;

float changeVel = 0.85;               // modifies all velocities

float nextScore;

/// Dodger
Dodger dodger;
int dodgerSize = 25;
float startVel;                       // beginning velocity of dodger, increases by scVel for every score
float scVel;
float rotVel;                         // rotation velocity of dodger
float rotAcc;                        // rotation acceleration of dodger, increases by scAcc for every score
float scAcc;
float rotMod = 1;                    // rotation modulation with q and e buttons
float rotDamp = 0.985;                // rotation velocity dampening
boolean clockwise;                    // is the player turning clockwise
PVector currentPos;                   // holds the current pos of dodger
float currentAng;                     // holds the current rotation of dodger
PVector highScorePosition;


/// Enemy
int maxE = 30;
Enemy[] enemies = new Enemy[maxE];
int eNum;                             // index of current obstacle
int sActive = 9;                      // enemies active at start
int enemiesPerScore = 30;             // amount of score necessary to increase sActive by one
int eActive;                          // enemies currently active
float limiter;                        // makes the arrow more narrow
float startEVel;                      // beginning velocity of enemies, increases by scEVel for every score
float scEVel;
float startSize = 25;                 // beginning size of enemies, increases by scESize for every score
float scESize = 0.015;
float obstacleDrain = 0.5;            // velocity of obstacle after aura was harvested
float obstacleRDrain = 0.4;           // rotation of obstacle after aura was harvested
float shipChance, shipVal;            // chance to spawn ship instead of asteroid
float kamiChance, kamiVal;            // chance to spawn kamikaze, starts at 0 increases with score
float onoffChance, onoffVal;          // chance to spawn onoff, starts at 0 increases with score
float chanceModifier = 0.001;         // number by which the chance for obstacle types gets modified
boolean bossActive = false;           // tells us if there is a boss on the field
int bossNumber;                       // cycles through the bosses
int nextBossNumber;
float modifier;                       // used to modify some starting values

/// Aura
float circleFactor = 1.25;             // size of aura per obstacle size
int circleAdd = 220;                  // added to size of aura
int circleTransparency = 20;
float bossCFactor = 1.5;              // boss has smaller circle and no add

void setup() {
  // setup screen
  fullScreen(P3D);
  orientation(LANDSCAPE);
  //prepare scaling screen to fixed resolution
  pg = createGraphics(pgWidth, pgHeight, P3D);
  frameRate(60);
  smooth(2);
  background(0);
  mainMenu = true;

  logo =        loadShape("logolast.svg");
  logoOutline = loadShape("logooutline.svg");
  shapeMode(CORNERS);

  score = startScore;
  totalScore = 0;
  currentAng = 0;
  highScorePosition = new PVector(pgWidth*1/2, pgHeight*6/7);
  currentPos = new PVector(pgWidth/2, pgHeight*3/4);
  initGame(); // set up the variables for game initialisation
}

//// set up the variables for game initialisation
void initGame() {

  if(startTimer == 0) {
    startTimer = millis();
  }

  menuDodgerInit = false;
  gameOver = false;
  playTime = second();

  // dodger attributes
  rotVel = 0;   // current rotation velocity
  startVel = 2.8 * changeVel;
  scVel = 0.002 * changeVel;
  // sponge something is horribly broken here, dodger always turns the same speed
  rotAcc = random(0.002, 0.004); // current rotation acceleration
  scAcc = 0.00001 * changeVel;
  dodger = new Dodger(currentPos.x, currentPos.y, currentAng);

  //obstacle attributes
  startEVel = 2 * changeVel;
  scEVel = 0.0025 * changeVel;
  limiter = 0.7;
  eActive = sActive;
  shipChance = 0.2; //starting chance for spawn to be ship, increases with score as well
  kamiChance = 0.1;
  onoffChance = 0.0;
  bossNumber = 0;
  bossActive = false;

  // generate new enemies
  for(eNum = 0; eNum < enemies.length; eNum++) {
    newEnemy();
  }
}

/////UP = SETUP//////////DOWN = UPDATE///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// draw function with gamestates
void draw() {
  // draw everything to the canvas with pgWidth*pgHeight
  pg.beginDraw();
  pg.background(0);

  if(gameOver){
    showScore();
  } else if(mainMenu){
    showMenu();
  } else {
    runGame();
    drawBar();
  }

  // scale everything from the canvas to the actual screen
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

//// perform a frame of the gameplay
void runGame() {
  // update next score (better move this to gameover)
  nextScore = score * scoreRate;

  //android
  if(startTimer + runDuration <= millis()) {
    storeDodgerPos();
    gameOver = true;
    enterTime = millis();
  }

  pg.background(0, 0, 0);
  pg.textSize(30);
  pg.fill(255);
  // adjust amount of enemies according to score
  if(int(score/enemiesPerScore + sActive) > eActive && eActive < maxE) {
    eActive++;
  }
  // ENEMY: update position, check collision, check aura collision, draw aura then draw obstacle
  for(eNum = 0; eNum < eActive; eNum++){
    enemies[eNum].update(); // update obstacle position
    // if the obstacle is out of bounds and not recently spawned make a new obstacle appear
    if (enemies[eNum].bounds() && millis() - enemies[eNum].spawnTimer > 1000) {
      newEnemy();
    }
    // if dodger collides with an obstacle
    if(enemies[eNum].collision()){
      totalScore += score;
      storeDodgerPos();
      gameOver = true;
      enterTime = millis();
    }
    // if dodger is colliding with an aura decrease hp and if aura is harvested increase score
    if(enemies[eNum].circleCollision()){
      enemies[eNum].hp--; // decrease life of enemies aura
      if(enemies[eNum].circleTouched == false && enemies[eNum].hp < 0) {
        // increase score depending on obstacle type (asteroid:1 ship:1.5 kamikaze:2.5 boss:5 )
        if(enemies[eNum].type == "boss1" || enemies[eNum].type == "boss2") {
          score += 3 + bossNumber*5;
          score += 3 + bossNumber*5;
          bossActive = false;
        } else if(enemies[eNum].type == "kamikaze") {
          score += 2.5;
        } else if(enemies[eNum].type == "ship") {
          score += 1.5;
        } else {
          score++;
        }
        enemies[eNum].circleTouched = true;
        enemies[eNum].popTimer = millis();
        enemies[eNum].vel *= random(obstacleDrain/2, obstacleDrain);                                           // reduce obstacle velocity when circle disappears
        enemies[eNum].rotation = (enemies[eNum].rotation % TWO_PI) *random(0.5*obstacleRDrain, 1.5*obstacleRDrain);  // reduce obstacle rotation when circle disappears
      }
    }
    enemies[eNum].drawCircle();           // draws aura first so no overlap with enemies
  }
  for(eNum = 0; eNum < eActive; eNum++){
    enemies[eNum].draw();
  }

  dodger.update();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawCircle(false, dodger.pos, 40);
  dodger.draw();
  rotAcc = (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity

  // draws the position in the song
  drawSongPos();
}

/////GAME LOGICKS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// spawn a new obstacle
void newEnemy() {
  String thisType = "asteroid";
  int border = (int) random(4);         // determine which edge enemies spawn from
  float typeR = random(1);               // determine which type the obstacle is going to be

  // check if bosses get spawned
  nextBossNumber = int(40 + bossNumber*5);
  if(score > 5 && score % nextBossNumber <= 5 && !bossActive) {
    modifier = score;
    bossActive = true;
    shipVal  = (             score *chanceModifier + shipChance);
    kamiVal  = (max(0, (score-20)) *chanceModifier + kamiChance);
    onoffVal = (max(0, (score-50)) *chanceModifier + onoffChance);
    float bossSeed = random(1,5);
    println("making boss", int(bossNumber+bossSeed));
    switch(int(bossNumber+bossSeed) % 4) {
      case 0:
        thisType = "boss1";
        break;
      case 1:
        thisType = "boss2";
        break;
      case 2:
        thisType = "boss3";
        break;
      case 3:
        thisType = "boss3b";
        break;
    }
    bossNumber += 1;
    } else if( (typeR) > 1-onoffVal ) {
      thisType = "onoff";
    } else if( (typeR) > 1-kamiVal ) {
    thisType = "kamikaze";
    } else if( (typeR) > 1-shipVal ) {
    thisType = "ship";
  } else {
    thisType = "asteroid";
  }
  float obstacleDiameter = (startSize + score*scESize) * circleFactor + circleAdd;
  if(thisType == "boss1"){
    enemies[eNum] = new Enemy(pgWidth/4 + random(pgWidth/2), pgHeight/4 + random(pgHeight/2), random(PI + limiter, TWO_PI - limiter), startEVel, thisType);
  } else if(thisType == "boss2"){
    enemies[eNum] = new Enemy(random(pgWidth), random(pgHeight), random(PI + limiter, TWO_PI - limiter), startEVel, thisType);
  } else if(border == 0) {
    //left border
    enemies[eNum] = new Enemy(0-obstacleDiameter, random(pgHeight), random(PI + limiter, TWO_PI - limiter), startEVel, thisType);
  }
  if(border == 1) {
    //top border
    enemies[eNum] = new Enemy(random(pgWidth), 0-obstacleDiameter, random(HALF_PI + PI + limiter, 3*QUARTER_PI - limiter), startEVel, thisType);
  }
  if(border == 2) {
    //right border
    enemies[eNum] = new Enemy(pgWidth+obstacleDiameter, random(pgHeight), random(TWO_PI + limiter, TWO_PI + PI - limiter), startEVel, thisType);
  }
  if(border == 3) {
    //bottom border
    enemies[eNum] = new Enemy(random(pgHeight), pgHeight+obstacleDiameter, random(3*QUARTER_PI + limiter, HALF_PI + PI - limiter), startEVel, thisType);
  }
  modifier = 0; // reset the modifier (used in obstacle class for special enemies)
}

///// sponge draw a white outline rectangle then fill it with scoreRate

//// show the game over screen, store dodger position
void showScore() {
  //update the high score
  if (score > highScore){
    highScore = int(score);
  }
  //draw dodger with current aura size
  if(!menuDodgerInit) {
    // make a dodger for the main menu
    changeVel = 1.3;                  // modifies all velocities
    rotVel = 0;   // current rotation velocity
    startVel = 2 * changeVel *1.2;
    scVel = 0.002 * changeVel *1.5;
    rotAcc = random(0.065, 0.069) * changeVel; // current rotation acceleration
    scAcc = 0.001 * changeVel;
    dodger = new Dodger(currentPos.x, currentPos.y, currentAng);
    menuDodgerInit = true; // initialized
    changeVel = 1;                  // reset changeVel
  }

  pg.background(0);
  pg.fill(255);
  pg.stroke(255);
  pg.strokeWeight(6);
  pg.textAlign(CENTER, CENTER);
  // draw score & high score
  int playDiff = second() - playTime;
  pg.textSize(140);
  pg.text(int(score), pgWidth*2/4, pgHeight*1/4 -50);
  pg.textSize(30);
  // pg.text(" || best "+ int(highScore) + " || total " + totalScore + " || rate "+ scoreRate + " || " + playDiff + "sec || next " + int(nextScore), pgWidth*2/4, pgHeight*2/5 -50);
  pg.text(" || best "+ int(highScore) +
          " || total " + totalScore +
          " || rate "+ nf(scoreRate, 0, 3) +
          " || next " + int(nextScore) +
          " || ", pgWidth*2/4, pgHeight*2/5 -50);

  if(startTimer + runDuration <= millis()) {
    float newStart = score * scoreRate/3 + highScore *scoreRate/4;
    pg.text(" || Your trial version timer has run out. Starting score is updated...          ||" , pgWidth*2/4, pgHeight*3.5/5);
    pg.text(" || The next run you can do will be lengthened by "+ int(newStart) + "sec, so enjoy...     ||" , pgWidth*2/4, pgHeight*3.5/5 +50);
    pg.text(" || " + int(score) +" * "+ nf(scoreRate, 0, 3) + "/3 +" + int(highScore) + " * " + nf(scoreRate, 0, 3) + "/4 ||" , pgWidth*2/4, pgHeight*3.5/5 +100);
    pg.text(" || new starting score: " + int(newStart) + " press a key to reset||" , pgWidth*2/4, pgHeight*3.5/5 +150);
  }
  // pg.text( "|| rate" + min(2, map(highScore, 0, 500, 0, 3)) /10 + " || rate " + (4 + min(2, map(totalScore, 0, 1200, 0, 3))) + "                                ", pgWidth*2/4, pgHeight*2.2/5 -50);
  // pg.textSize(100);
  // pg.text(int(score), pgWidth*2/4, pgHeight*3.3/4 -50);

  //android
  // if(bg.position() == bg.length()) {
  //   pg.rectMode(CENTER);
  //   pg.text("You have finished the song. Goodbye!", pgWidth*2/4, pgHeight*3.8/4);
  // }

  // draw and update dodger
  dodger.update();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawCircle(false, dodger.pos, 40);
  dodger.draw();
  rotAcc = rotMod * (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity
  // wait for key input to show mainMenu
}

//// show the menu screen
void showMenu() {

  // lights();
  pg.background(0);
  pg.fill(255);
  pg.stroke(255);
  pg.strokeWeight(6);
  pg.textAlign(CENTER, CENTER);

  // draw and update dodger
  dodger.update();
  dodger.draw();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawCircle(false, dodger.pos, 60); //draw an aura around dodger
  //dodger draw moved to after logo is drawn so dodger is still on top
  rotAcc = (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity

  // draw menu & high score
  if(highScore != 0) {
    dodger.drawCircle(true, highScorePosition, 200);
  }
  if(highScore >= 150) {
    pg.textSize(70);
    pg.fill(0);
    pg.text(int(highScore), pgWidth*2/4, pgHeight*3.4/4);
  }

  pg.textSize(80);
  pg.stroke(250);
  pg.strokeWeight(5);
  // if(bg.position() == bg.length()) {
  //   pg.rectMode(CENTER);
  //   pg.fill(250, 250, 250, 100);
  //   pg.text("Take a break! (or press R to rewind)", pgWidth*2/4, pgHeight*3.6/4);
  // } else {
    pg.fill(255, 255, 255, max(0, 150-highScore));
    pg.text("vol key to", pgWidth*2/4, pgHeight*3.45/4 -50);
    pg.text("enter void", pgWidth*2/4, pgHeight*3.7/4 -50);
  // }
  // draw logo
  int border = 150;
  // sponge the logos need to be scaled to really apply the offset
  // would be much better anyways because that way they keep their proportions
  float logoOffX = -10; //(logoOutline.width - logo.width)/2;
  float logoOffY = -8;//(logoOutline.height - logo.height)/2;
  int logoYstart = 355;
  int logoYend = 720;
  logoOutline.setFill(color(min(255, highScore*3/5), min(255, highScore*3/5), min(255, highScore*3/5)) );
  pushMatrix();
    translate(0, 0, 1);
    // android quickfix
    shape(logoOutline, 90 + border -10,
                logoYstart -15,
                90 + pgWidth-border +20,
                logoYend +30);
    logo.setFill(color(0, 0, 0)); //why is a regular black transparent? this needs to be real fill!
    int logoFlex = 30;
    shape(logo, logoOffX + 90 + border - (dodger.pos.x-pgWidth/2)/logoFlex,
                logoOffY + logoYstart - (dodger.pos.y-pgHeight/2)/logoFlex,
                logoOffX + 90 + pgWidth-border - (dodger.pos.x-pgWidth/2)/logoFlex,
                logoOffY + logoYend - (dodger.pos.y-pgHeight/2)/logoFlex);
    //sponge this doesnt work somehow... dodger should be drawn in the foreground
    translate(0, 0, 2);
  popMatrix();

  drawBar();
  // drawSongPos();
  // wait for key input to start new game
  // pass on the angle and position to initGame
}

boolean randomBool() {
  return random(1) > .5;
}

void storeDodgerPos(){
  currentPos.x = dodger.pos.x;
  currentPos.y = dodger.pos.y;
  currentAng = dodger.a;
}

//// draw the progress of the song
void drawSongPos() {
  // android
  pg.fill(255, 255, 255, 150);
  pg.noStroke();
  float poos = millis() - startTimer;
  float leng = runDuration;
  pg.rect(pgWidth/2, pgHeight-10, poos/leng*pgWidth, 10);
  pg.fill(0);

  // desktop
  // pg.fill(255, 255, 255, 150);
  // pg.noStroke();
  // float poos = bg.position();
  // float leng = bg.length();
  // // pg.rect(pgWidth/2,   0,                       1*pgWidth, 100);
  // pg.rect(pgWidth/2, pgHeight-10, poos/leng*pgWidth, 10);
  // pg.fill(0);
  // // println(poos, leng);
}

//// rewind the song and calculate a new starting value
void rewindSong() {
  startScore = score * scoreRate/3 + highScore *scoreRate/4;
  runDuration += startScore * 1000;
  highScore *= (0.1 + scoreRate); //current max score rate is 0.9 so under ideal conditions highScore is preserved
  startTimer = millis();
  enterTime = millis();
  setup();
}

///////////////DIAGNOSE////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// display a bar with information
void drawBar() {
  scoreRate = (5 + min(1, map(totalScore, 0, 2000, 0, 1)) + min(1.5, map(totalScore, 0, 8000, 0, 1)) + min(1, map(score, 0, 200, 0, 1)) + min(1, map(highScore, 0, 500, 0, 1))) /10;            // watch an ad or buy the game to keep 70% of your score
  pg.textSize(22);
  pg.fill(255, 255, 255, 150);
  pg.noStroke();
  pg.textAlign(LEFT, TOP);
  switch(diagBar) {
    case 0:
    // show just score
      pg.text(" || "+ nf(score, 0, 1) + " ||", 10, 10);
      break;
    case 1:
      int playDiff = second() - playTime;

      pg.text(" || "+ nf(score, 3, 0) +
              " || total "+ totalScore +
              " || rate "+ nf(scoreRate, 0, 3) +
              " || start "+ nf(startScore, 3, -3) +
              " || " + playDiff +
              "sec || next " + nf(nextScore, 0, 3) +
              "              || 0 = remove bar | 1 = this bar | 2 = Enemies | 3 = Dodger | 9 = hotkeys ||", 10, 10);

      break;
    // show obstacle stats
    case 2:
      pg.text(" || "+ nf(score, 0, 1) +
      " || Enemies || active:" + eActive +
      " || vel start:" + startEVel +
      "  +s* " + scEVel +
      "  current:" + nf(startEVel + score*scEVel, 0, 3) +
      " || size start:" + startSize +
      "  +s* " + scESize +
      "  current:" + nf(startSize + score*scESize, 0, 3) +
      " || chance for ship:" + shipVal +
      " kami:" + kamiVal, 10, 10);
      break;
    // show dodger stats
    case 3:
      pg.text(" || "+ nf(score, 0, 1) +
              " || dodger || vel start:" + startVel +
              "  +s* " + scVel +
              "  current:" + nf(startVel + score*scVel, 0, 3) +
              " || size:" + dodgerSize +
              " || chance for ship:" + shipVal +
              " kami:" + kamiVal +
              " || rotation vel:" + nf(rotVel, 0, 1) +
              " acc:" + rotAcc +
              "*" + rotMod, 10, 10);
    break;
    case 4:
      pg.text(" || "+ nf(score, 0, 1) +
              " || skills || total score 0-2000: " +   nf(min(100, map(totalScore, 0,  2000, 0, 1)*100), 3, -3) +
              "% / 0-8000: " + nf(min(100, map(totalScore, 0, 8000, 0, 1)*100), 3, -3) +
              "% / score 0-200: " + nf(min(100, map(     score, 0,   200, 0, 1)*100), 3, -3) +
              "%  / highscore 0-500: " +           nf(min(100, map( highScore, 0,   500, 0, 1)*100), 3, -3) +
              "% || total:"+ int(totalScore) +
              " | rate:"+ nf(scoreRate, 0, 3) +
              " | next:" + nf(nextScore, 0, 3), +10, 10);
      break;
    case 9:
      pg.text(" || "+ score +" || (case sensitive) K = game over | WASD = modify score ||" + score % nextBossNumber, 10, 10);
      break;
  }

  float startVel;                       // beginning velocity of dodger, increases by scVel for every score
}

///////////////INPUTS////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void keyPressed() { // listen for user input // touchStarted
  if(gameOver && !clockwise){
    // android quickfix
    gameOver = false;
    mainMenu = true;
    // update dodger position and angle
    storeDodgerPos();
    // update the scores for next round
    scoreRate = (5 + min(1, map(totalScore, 0, 2000, 0, 1)) + min(1.5, map(totalScore,    0,  8000, 0, 1)) +
                     min(1, map(score,      0,  200, 0, 1)) + min(1, map(   highScore,    0,   500, 0, 1))) /10;            // watch an ad or buy the game to keep +5% of your score
    score *=    (5 + min(1, map(totalScore, 0, 2000, 0, 1)) + min(1.5, map(totalScore,    0,  8000, 0, 1)) +
                     min(1, map(score,      0,  200, 0, 1)) + min(1, map(   highScore,    0,   500, 0, 1))) /10;            // watch an ad or buy the game to keep +5% of your score
    if(startTimer + runDuration <= millis()) {
      rewindSong();
    } else {
      showMenu();
    }
  } else if(mainMenu && !clockwise){
    mainMenu = false;
    // update dodger position and angle
    storeDodgerPos();
    // initiate the game
    leaveTime = millis();
    startTimer += leaveTime - enterTime;
    initGame();
  }
  // change diagbar state with the num keys
  switch(keyCode) {
    case '0':
      diagBar = 0;
      break;
    case '1':
      diagBar = 1;
      break;
    case '2':
      diagBar = 2;
      break;
    case '3':
      diagBar = 3;
      break;
    case '4':
      diagBar = 4;
      break;
    case '5':
      diagBar = 5;
      break;
    case '6':
      diagBar = 6;
      break;
    case '7':
      diagBar = 7;
      break;
    case '8':
      diagBar = 8;
      break;
    case '9':
      diagBar = 9;
      break;
    case 'K':
      // bg.pause();
      storeDodgerPos();
      gameOver = true;
      enterTime = millis();
      break;
    case 'P':
      // bg.pause();
      score *= pausePenalty;
      mainMenu = true;
      break;
    case 'M':
      // muted = !muted;
      break;
    // case 'R':
    //   if(bg.position() == bg.length()) {
    //     rewindSong();
    //   }
    //   break;
    case 'D':
      score++;
      break;
    case 'W':
      score += 10;
      break;
    case 'Q':
      rotMod -= 0.02;
      break;
    case 'E':
      rotMod += 0.02;
      break;
    case 'A':
      score--;
      break;
    case 'S':
      score -= 10;
      break;
  }

  // removeDroid
  if(!clockwise){
    rotVel = max(-150, -22-rotVel/4);
  }
  clockwise = true;
}

void touchStarted() { // listen for user input // touchStarted
  if(!clockwise){
    rotVel = max(-150, -22-rotVel/4);
  }
  clockwise = true;
}

void touchEnded() { // listen for user input // touchEnded
  if(clockwise){
    rotVel = max(-150, -22-rotVel/4);
  }
  clockwise = false;
}

void keyReleased() { // listen for user input // touchEnded
  // removeDroid
  if(clockwise){
    rotVel = max(-150, -22-rotVel/4);
  }
  clockwise = false;
}
