import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class dodgernew extends PApplet {


Minim minim;

// Load the sound files
AudioSample pop, sLeft, sRight, snap0, snap1, snap2, gameover;
AudioPlayer bg;
boolean gameOverSoundPlayed;
boolean soundEffects = true;
boolean cheatsEnabled = true;

//prepare scaling screen to fixed resolution
PGraphics pg;
int pgWidth = 1920;
int pgHeight = 980;

PShape logo;
PShape logoOutline;

float score;
float scoreBuffer;
float startScore = 10;
float highScore = 0;
int totalScore = 100;
int playTime;
int deathObst; // number of the obstacle that ended dodger

// game states
boolean gameOver; // goes to main menu
int gameOverTime; // time the player went gameOver
int scoreDropFrame; // gets set to frameCount when showState is set true
int scoreDropDuration = 240; // (in frames)

boolean mainMenu; // starts a new game
boolean menuDodgerInit;
float pausePenalty = 0.95f; // penalty for going into pause (P key btw)

// game modes
final int music = 0;    // const
final int endless = 1;  // const

int gameMode = music;

int diagBar = 6;  // sets the state of  the diagnostics bar, can be changed by num keys
float scoreRate;

float changeVel = 0.8f;               // modifies all velocities
int frameDropDuration = 2000;

float nextScore;

/// Dodger
Dodger dodger;
int dodgerSize = 22;
float startVel;                       // beginning velocity of dodger, increases by scVel for every score
float scVel;
float rotVel;                         // rotation velocity of dodger
float rotAcc;                        // rotation acceleration of dodger, increases by scAcc for every score
float scAcc;
// float rotMod = 1;                    // rotation modulation with q and e buttons
float rotDamp = 0.98f;                // rotation velocity dampening
boolean clockwise;                    // is the player turning clockwise
PVector currentPos;                   // holds the current pos of dodger
float currentAng;                     // holds the current rotation of dodger
PVector highScorePosition;

/// Enemy
int maxE = 30;
Enemy[] enemies = new Enemy[maxE];
int eNum;                             // index of current obstacle
int sActive = 11;                     // enemies active at start
int enemiesPerScore = 30;             // amount of score necessary to increase sActive by one
int eActive;                          // enemies currently active
float limiter;                        // makes the arrow more narrow
float startEVel;                      // beginning velocity of enemies, increases by scEVel for every score
float scEVel;
float startSize = 22;                 // beginning size of enemies, increases by scESize for every score
float scESize = 0.01f;
float obstacleDrain = 0.5f;            // velocity of obstacle after aura was harvested
float obstacleRDrain = 0.4f;           // rotation of obstacle after aura was harvested
float shipChance, shipVal;            // chance to spawn ship instead of asteroid
float sinuChance, sinuVal;            // chance to spawn ship instead of asteroid
float kamiChance, kamiVal;            // chance to spawn kamikaze, starts at 0 increases with score
float onoffChance, onoffVal;          // chance to spawn onoff, starts at 0 increases with score
float chanceModifier = 0.0012f;         // number by which the chance for obstacle types gets modified
boolean bossActive = false;           // tells us if there is a boss on the field
int nextBossNumber;
float modifier;                       // used to modify some starting values

/// Aura
float auraFactor = 1.3f;             // size of aura per obstacle size
int auraAdd = 230;                  // added to size of aura
int auraTransparency = 20;

public void setup() {
  // setup screen
  // size(960, 540, P3D);
  
  orientation(PORTRAIT);
  //prepare scaling screen to fixed resolution
  pg = createGraphics(pgWidth, pgHeight, P3D);
  // noCursor();
  frameRate(60);
  background(0);
  mainMenu = true;

  //sounds
  minim = new Minim(this);
  int bufferSize = 512;
  // load song
  if(gameMode == music) {
    bg = minim.loadFile("song.wav", bufferSize);           // this is a placeholder to conserve filesize. replace with your own .wav music
    // bg = minim.loadFile("betonkusten.wav", bufferSize);    // Betonkusten Mix - Eindleader Videonet & Nintendo Pantera //7m
    // bg = minim.loadFile("feedbacker.wav", bufferSize);     // BORIS - feedbacker stretched reversed               //24m
    // bg = minim.loadFile("dolphin.wav", bufferSize);        // BORIS - feedbacker stretched reversed               //24m
    // bg = minim.loadFile("bochum2.wav", bufferSize);        // bochum 2                                            //7m
    // bg = minim.loadFile("bochum3.wav", bufferSize);        // bochum 3                                            //9m
    // bg = minim.loadFile("bg2full.wav", bufferSize);        // A.G. Cook - windowlicker stretched                  //18m
    // bg = minim.loadFile("bg3full.wav", bufferSize);        // Sufjan Stevens - Futile Devices stretched           //4.5m
    // bg = minim.loadFile("bg4full.wav", bufferSize);        // Conan Mockassin stretched                           //21m
    // bg = minim.loadFile("bg5full.wav", bufferSize);        // BORIS - flood 1 stretched                           //31m
    // bg = minim.loadFile("snap0.wav", bufferSize);          // end of song test
  }
  // load the sound effects
  if(soundEffects){
    pop = minim.loadSample("pop.wav", bufferSize);
    sLeft = minim.loadSample("perc1l.wav", bufferSize);
    sRight = minim.loadSample("perc2l.wav", bufferSize);
    snap0 = minim.loadSample("snap0.wav", bufferSize);
    snap1 = minim.loadSample("snap1.wav", bufferSize);
    snap2 = minim.loadSample("snap2.wav", bufferSize);
    gameover = minim.loadSample("gameover.wav", bufferSize);
  }

  logo =        loadShape("logolast.svg");
  logoOutline = loadShape("logooutline.svg");
  shapeMode(CORNERS);

  score = startScore;
  totalScore = 0;
  currentAng = 0;
  highScorePosition = new PVector(pgWidth*1/2, pgHeight*6/7);
  currentPos = new PVector(pgWidth/2, pgHeight*1.3f/4);
  initGame(); // set up the variables for game initialisation
}

//// set up the variables for game initialisation
public void initGame() {
  frameRate(60);
  menuDodgerInit = false;
  gameOver = false;
  playTime = second();

  // dodger attributes
  rotVel = 0;   // current rotation velocity
  startVel = 3 * changeVel;
  scVel = 0.0013f * changeVel;
  // sponge something is horribly broken here, dodger always turns the same speed
  rotAcc = random(0.002f, 0.003f); // current rotation acceleration
  scAcc = 0.00001f * changeVel;
  dodger = new Dodger(currentPos.x, currentPos.y, currentAng);

  //obstacle attributes
  startEVel = 2.55f * changeVel;
  scEVel = 0.0015f * changeVel;
  limiter = 0.7f;
  eActive = sActive;
  shipChance = 0.1f; //starting chance for spawn to be ship, increases with score as well
  sinuChance = 0.1f;
  kamiChance = 0.0f;
  onoffChance = 0.0f;
  bossActive = false;

  // generate new enemies
  for(eNum = 0; eNum < enemies.length; eNum++) {
    newEnemy();
  }
}

/////UP = SETUP//////////DOWN = UPDATE///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// draw function with gamestates
public void draw() {
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
  pg.fill(0, 0, 0, 0);
  pg.stroke(255);
  pg.strokeWeight(1);
  pg.endDraw();
  image(pg, 0, 0, width, height);
  /// Stuff for screen recording / centering dodger
  // pg.endDraw();
  // pushMatrix();
  // translate(pgWidth/2-dodger.pos.x, pgHeight/2-dodger.pos.y);
  // println(dodger.pos.x, dodger.pos.y);
  // image(pg, -width/2, -height/2, width*4/2, height*4/2);
  // popMatrix();


}

//// draw the progress of the song
public void drawSongPos() {
  pg.fill(255, 255, 255, 150);
  pg.noStroke();
  float poos = bg.position();
  float leng = bg.length();
  // pg.rect(pgWidth/2,   0,                       1*pgWidth, 100);
  pg.rect(pgWidth/2, pgHeight-10, poos/leng*pgWidth, 10);
  pg.fill(0);
  // println(poos, leng);
}

//// perform a frame of the gameplay
public void runGame() {
  // update next score (better move this to gameover)
  nextScore = score * scoreRate;

  if(gameMode == music) {
    bg.play();
    // when the song is over it needs to be rewinded
    if(bg.position() == bg.length()) {
      runOver();
    }
  }

  pg.background(0, 0, 0);
  pg.textSize(30);
  pg.fill(255);
  // adjust amount of enemies according to score
  if(PApplet.parseInt(score/enemiesPerScore + sActive) > eActive && eActive < maxE) {
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
      runOver();
    }
    // if dodger is colliding with an aura decrease hp and if aura is harvested increase score
    if(enemies[eNum].auraCollision()){
      enemies[eNum].hp--; // decrease life of enemies aura
      if(enemies[eNum].auraTouched == false && enemies[eNum].hp < 0) {
        // increase score depending on obstacle type (asteroid:1 ship:1.5 kamikaze:2.5 boss:5 )
        if(enemies[eNum].type == "boss1" || enemies[eNum].type == "boss2" || enemies[eNum].type == "boss3" || enemies[eNum].type == "boss3b") {
          score += 3 + score/50;
          score += 3 + score/50;
          bossActive = false;
        } else if(enemies[eNum].type == "onoff") { // + 4.5
          score += 4.5f;
        } else if(enemies[eNum].type == "kamikaze") { // + 2.5
          score += 2.5f;
        } else if(enemies[eNum].type == "sinusoid") { // + 2
          score += 2;
        } else if(enemies[eNum].type == "ship") { // + 1.5
          score += 1.5f;
        } else { // + 1
          score++;
        }
        //play a random snap sound
        if(soundEffects) {
          switch(frameCount % 3) {
            case 0:
              snap0.trigger();
              break;
            case 1:
              snap1.trigger();
              break;
            case 2:
              snap2.trigger();
              break;
          }
        }
        enemies[eNum].auraTouched = true;
        enemies[eNum].popTimer = millis();
        enemies[eNum].vel *= random(obstacleDrain/2, obstacleDrain);                                           // reduce obstacle velocity when aura disappears
        enemies[eNum].rotationVel *= random(0.5f*obstacleRDrain, 1.5f*obstacleRDrain);  // reduce obstacle rotation when aura disappears
      }
    }
    enemies[eNum].drawAura();           // draws aura first so no overlap with enemies
  }
  for(eNum = 0; eNum < eActive; eNum++){
    enemies[eNum].draw();
  }

  dodger.update();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawAura(false, dodger.pos, 40);
  dodger.draw();
  rotAcc = (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity

  // draws the position in the song
  if(gameMode == music) {
    drawSongPos();
  }
}

/////GAME LOGICKS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// spawn a new obstacle
public void newEnemy() {
  String thisType = "asteroid";
  int border = (int) random(4);         // determine which edge enemies spawn from
  float typeR = random(0.5f+onoffVal+kamiVal+shipVal+sinuVal);              // determine which type the obstacle is going to be

  // refresh spawn chances
  shipVal  = (min(200,  score    ) *chanceModifier + shipChance);
  sinuVal  = (min(300,  score    ) *chanceModifier + sinuChance);
  kamiVal  = (max(  0, (score-30)) *chanceModifier + kamiChance);
  onoffVal = (max(  0, (score-80)) *chanceModifier + onoffChance);
  // check if bosses get spawned
  nextBossNumber = PApplet.parseInt(45 + score/40);
  if(score > 5 && score % nextBossNumber <= 5 && !bossActive) {
    modifier = score;
    bossActive = true;
    float bossSeed = 0;
    if(score <= 100) bossSeed = PApplet.parseInt(random(1,2) - 0.5f);
    else if(score <= 200) bossSeed = PApplet.parseInt(random(1,3) - 0.5f);
    else if(score <= 300) bossSeed = PApplet.parseInt(random(1,4) - 0.5f);
    else if(score >= 300) bossSeed = PApplet.parseInt(random(2,4) - 0.5f);
    println("making boss " + bossSeed + " with " + score + " score.");
    switch(PApplet.parseInt(bossSeed) % 4) {
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
  } else if( (typeR) > 0.5f+sinuVal+shipVal+kamiVal) {
    thisType = "onoff";
  } else if( (typeR) > 0.5f+sinuVal+shipVal) {
    thisType = "kamikaze";
  } else if( (typeR) > 0.5f+sinuVal ) {
    thisType = "ship";
  } else if( (typeR) > 0.5f ) {
    thisType = "sinusoid";
  } else {
    thisType = "asteroid";
  }
  float obstacleDiameter = (startSize + score*scESize) * auraFactor + auraAdd;
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
public void showScore() {
  // play the game over sound
  if(gameMode == music){
    bg.pause(); //pause background sound
  }
  if(!gameOverSoundPlayed && soundEffects) {
    gameover.trigger(); //play the game over sample
    gameOverSoundPlayed = true; //so it doesnt play again
  }
  //update the high score
  if (score > highScore){
    highScore = PApplet.parseInt(score);
  }
  // make the animation for the shrinking aura
  if(frameCount - scoreDropFrame <= scoreDropDuration) {
    score = map(frameCount - scoreDropFrame , 0, scoreDropDuration, scoreBuffer, nextScore);
  }
  //draw dodger with current aura size
  if(!menuDodgerInit) {
    enemies[deathObst].auraTouched = false;
    enemies[deathObst].hp = enemies[deathObst].maxHp;
    // make a dodger for the main menu
    rotVel = 0;   // current rotation velocity
    startVel = 3 * changeVel;
    scVel = 0.002f * changeVel;
    rotAcc = random(0.065f, 0.069f) * changeVel; // current rotation acceleration
    scAcc = 0.001f * changeVel;
    dodger = new Dodger(currentPos.x, currentPos.y, currentAng);
    menuDodgerInit = true; // initialized
  }

  pg.background(0);
  pg.fill(255);
  pg.stroke(255);
  pg.strokeWeight(6);
  pg.textAlign(CENTER, CENTER);
  // draw score & high score
  int playDiff = second() - playTime;
  pg.textSize(60);
  pg.text(PApplet.parseInt(scoreBuffer), pgWidth*2/4, pgHeight*1.1f
  /4);
  pg.textSize(30);
  pg.text(" || best "+ PApplet.parseInt(highScore) +
          " || total " + totalScore +
          " || rate "+ nf(scoreRate, 0, 3) +
          " || next " + PApplet.parseInt(nextScore) +
          " || ", pgWidth*2/4, pgHeight*2/5 -50);

  if(gameMode == music) {
    if(bg.position() == bg.length()) {
      pg.rectMode(CENTER);
      pg.text("You have finished the song. Goodbye!", pgWidth*2/4, pgHeight*3.8f/4);
    }
  }

  // draw and update dodger
  dodger.update();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawAura(false, dodger.pos, 40);
  dodger.draw();
  // draw and update the enemy that ended your life. When aura is harvested go to menu.
  enemies[deathObst].update(); // update obstacle position
  if(enemies[deathObst].bounds()) {
    enemies[deathObst].hp = enemies[deathObst].maxHp;
    enemies[deathObst].pos.x = random(pgWidth/2) + pgWidth/4;
    enemies[deathObst].pos.y = random(pgHeight/2) + pgHeight/4;
    enemies[deathObst].vel *= random(obstacleDrain/3, obstacleDrain/2);                  // reduce obstacle velocity when aura disappears
  }
  enemies[deathObst].drawAura();           // draws aura first so no overlap with enemies
  if(enemies[deathObst].auraCollision()){
    enemies[deathObst].hp--; // decrease life of enemies aura
    if(enemies[deathObst].auraTouched == false && enemies[deathObst].hp <= 0) {
      enemies[deathObst].auraTouched = true;
      enemies[deathObst].popTimer = millis();
      enemies[deathObst].vel *= random(obstacleDrain/2, obstacleDrain);                  // reduce obstacle velocity when aura disappears
      enemies[deathObst].rotationVel *= random(0.5f*obstacleRDrain, 1.5f*obstacleRDrain);  // reduce obstacle rotation when aura disappears
    }
  }
  if(enemies[deathObst].collision() && enemies[deathObst].auraTouched && millis() > gameOverTime+500){
    overMenu();
  }
  if(bg.position() != bg.length()) {
    enemies[deathObst].draw();
  }

  rotAcc = (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity

  drawBar();
  // wait for key input to show mainMenu
}

//// show the menu screen
public void showMenu() {
  // lights();
  pg.background(0);
  pg.fill(255);
  pg.stroke(255);
  pg.strokeWeight(6);
  pg.textAlign(CENTER, CENTER);

  // draw and update dodger
  dodger.update();
  dodger.bounds();                        // check if dodger is still in bounds (if not, put back)
  dodger.drawAura(false, dodger.pos, 40); //draw an aura around dodger
  //dodger draw moved to after logo is drawn so dodger is still on top
  rotAcc = (2 + score*scAcc) * changeVel; // increase the rotation velocity by rotation acceleration
  rotVel += rotAcc;                       // velocity increases by acceleration
  rotVel *= rotDamp;                      // dampen the rotation velocity

  // draw menu & high score
  if(highScore != 0) {
    dodger.drawAura(true, highScorePosition, 200);
  }
  if(highScore >= 150) {
    pg.textSize(70);
    pg.fill(0);
    pg.text(PApplet.parseInt(highScore), pgWidth*2/4, pgHeight*3.4f/4);
  }

  pg.textSize(20);
  pg.stroke(250);
  pg.strokeWeight(5);
  pg.fill(250, 250, 250, 100);

  if(gameMode == music) {
    pg.text("Music Mode", pgWidth*0.2f/4, pgHeight*0.15f/4);
  } else {
    pg.text("Endless", pgWidth*0.2f/4, pgHeight*0.15f/4);
  }
  pg.text("g to switch", pgWidth*0.2f/4, pgHeight*0.25f/4);
  if(soundEffects) {
    pg.text("m to mute", pgWidth*0.2f/4, pgHeight*0.35f/4);
  } else {
    pg.text("muted sfx", pgWidth*0.2f/4, pgHeight*0.35f/4);
  }

  pg.textSize(80);
  if(gameMode == music) {
    if(bg.position() == bg.length()) {
      pg.rectMode(CENTER);
      pg.text("Take a break! (or press R to rewind)", pgWidth*2/4, pgHeight*3.6f/4);
    } else {
      pg.fill(255, 255, 255, max(0, 150-highScore));
      pg.text("spacebar", pgWidth*2/4, pgHeight*3.45f/4 -50);
      pg.text("enter void", pgWidth*2/4, pgHeight*3.7f/4 -50);
    }
    } else {
    pg.fill(255, 255, 255, max(0, 150-highScore));
    pg.text("spacebar", pgWidth*2/4, pgHeight*3.45f/4 -50);
    pg.text("enter void", pgWidth*2/4, pgHeight*3.7f/4 -50);
  }

  // draw logo
  int border = 350;
  // sponge the logos need to be scaled to really apply the offset
  // would be much better anyways because that way they keep their proportions
  float logoOffX = -11; //(logoOutline.width - logo.width)/2;
  float logoOffY = -10;//(logoOutline.height - logo.height)/2;
  int logoXstart = 100;
  int logoXend = pgWidth - 170;
  int logoYstart = 255;
  int logoYend = 520;
  logoOutline.setFill(color(min(255, highScore*3/5), min(255, highScore*3/5), min(255, highScore*3/5)) );
  pushMatrix();
    pg.translate(0, 0, 1);
    pg.shape(logoOutline, logoXstart,
                          logoYstart,
                          logoXend,
                          logoYend);
    logo.setFill(color(0, 0, 0));
    int logoFlex = 30;
    pg.shape(logo, logoXstart +15 + logoOffX - (dodger.pos.x-pgWidth /2)/logoFlex,
                   logoYstart +10 + logoOffY - (dodger.pos.y-pgHeight/2)/logoFlex,
                   logoXend   - 5 + logoOffX - (dodger.pos.x-pgWidth /2)/logoFlex,
                   logoYend   -10 + logoOffY - (dodger.pos.y-pgHeight/2)/logoFlex);
    //sponge this doesnt work somehow... dodger should be drawn in the foreground
    pg.translate(0, 0, 2);
    dodger.draw();
  popMatrix();

  drawBar();
  // wait for key input to start new game
  // pass on the angle and position to initGame
}

public boolean randomBool() {
  return random(1) > .5f;
}

public void storeDodgerPos(){
  currentPos.x = dodger.pos.x;
  currentPos.y = dodger.pos.y;
  currentAng = dodger.a;
}

//// rewind the song and calculate a new starting value
public void rewindSong() {
  startScore = score * scoreRate/3 + highScore *scoreRate/4;
  highScore *= (0.1f + scoreRate); //current max score rate is 0.9 so under ideal conditions highScore is preserved
  bg.rewind();
  setup();
}
///////////////DIAGNOSE////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// display a bar with information
public void drawBar() {
  scoreRate = (5 + min(1, map(totalScore, 0, 2000, 0, 1)) + min(1.5f, map(totalScore,    0,  8000, 0, 1)) +
                   min(1, map(scoreBuffer,      0,  200, 0, 1)) + min(1, map(   highScore,    0,   500, 0, 1))) /10;            // watch an ad or buy the game to keep +5% of your score
  pg.textSize(22);
  pg.fill(255, 255, 255, 150);
  pg.noStroke();
  pg.textAlign(LEFT, TOP);
  switch(diagBar) {
    case 0:
    // show just score
      pg.text(" || "+ nf(score, 3, -3) + " ||", 10, 10);
      break;
    case 1:
      int playDiff = second() - playTime;

      pg.text(" || "+ nf(score, 3, -3) +
              " || total "+ totalScore +
              " || rate "+ nf(scoreRate, 0, 3) +
              " || start "+ nf(startScore, 3, -3) +
              " || " + playDiff +
              "sec || next " + nf(nextScore, 0, 3) +
              "              || 0 = remove bar | 1 = this bar | 2 = Enemies | 3 = Dodger | 9 = hotkeys ||", 10, 10);

      break;
    // show obstacle stats
    case 2:
      pg.text(" || "+ nf(score, 3, -3) +
      " || Enemies || active:" + eActive +
      " || vel start:" + startEVel +
      "+s* " + scEVel +
      "  now:" + nf(startEVel + score*scEVel, 0, 3) +
      " || size start:" + startSize +
      "+s* " + scESize +
      "  now:" + nf(startSize + score*scESize, 0, 3) +
      " || chance for ship:" + nf(shipVal, 0, 3) +
      " kami:" + nf(kamiVal, 0, 3) +
      " onoff:" + nf(onoffVal, 0, 3) +
      " sinusoid:" + nf(sinuVal, 0, 3) , 10, 10);
      break;
    // show dodger stats
    case 3:
      pg.text(" || "+ nf(score, 3, -3) +
              " || dodger || vel start:" + startVel +
              "+s* " + scVel +
              "  now:" + nf(startVel + score*scVel, 0, 3) +
              " || size:" + dodgerSize +
              " || chance for ship:" + nf(shipVal, 0, 3) +
              " kami:" + nf(kamiVal, 0, 3) +
              " onoff:" + nf(onoffVal, 0, 3) +
              " sinusoid:" + nf(sinuVal, 0, 3) +
              " || rotation vel:" + nf(rotVel, 0, 1) +
              " acc:" + rotAcc +
              " dampen:" + nf(rotDamp, 0, 3), 10, 10);
    break;
    case 4:
      pg.text(" || "+ nf(score, 3, -3) +
              " || skills || total score 0-2000: " +   nf(min(100, map(totalScore, 0,  2000, 0, 1)*100), 3, -3) +
              "% / 0-8000: " + nf(min(100, map(totalScore, 0, 8000, 0, 1)*100), 3, -3) +
              "% / score 0-200: " + nf(min(100, map(     score, 0,   200, 0, 1)*100), 3, -3) +
              "%  / highscore 0-500: " +           nf(min(100, map( highScore, 0,   500, 0, 1)*100), 3, -3) +
              "% || total:"+ PApplet.parseInt(totalScore) +
              " | rate:"+ nf(scoreRate, 0, 3) +
              " | next:" + nf(nextScore, 0, 3), +10, 10);
      break;
    case 9:
      pg.text(" || "+ score +" || (case sensitive) K = game over | WASD = modify score ||" + score % nextBossNumber, 10, 10);
      break;
  }

  float startVel;                       // beginning velocity of dodger, increases by scVel for every score
}

///////////////STATES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// from game over to menu
public void overMenu() {
  // go to menu state
  gameOver = false;
  mainMenu = true;
  // update score
  score =  scoreBuffer * scoreRate;
  // update dodger position and angle
  storeDodgerPos();
  showMenu();
}

// from menu to run game
public void menuRun() {
  // initiate the game
  mainMenu = false;
  menuDodgerInit = false;
  // update dodger position and angle
  storeDodgerPos();
  initGame(); // set up the variables for game initialisation
}

// from run game to game over
public void runOver() {
  deathObst = eNum;
  gameOverSoundPlayed = false;
  if(gameMode == music) {
    bg.pause();
  }
  totalScore += score;
  storeDodgerPos();
  // put the current score into a buffer
  scoreBuffer = score;
  scoreDropFrame = frameCount;
  gameOverTime = millis();
  gameOver = true;
}


///////////////INPUTS////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void keyPressed() { // listen for user input // touchStarted
  if(gameOver && !clockwise  && keyCode == ' '){
    overMenu();
  } else if(mainMenu && !clockwise && keyCode == ' '){
    menuRun();
  } else {
    if(!clockwise){
      // if(soundEffects) {
      //   sRight.trigger();
      // }
      rotVel = max(-150, -22-rotVel/5);
    }
    clockwise = true;
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
    }
  // important keys
  switch(keyCode){
    case 'K': // seppuku
      runOver();
      break;
    case 'P': // pause the game (and lose 5% of your score)
      if(gameMode == music) {
        bg.pause();
      }
      score *= pausePenalty;
      mainMenu = true;
      break;
    case 'M': // mute the sound effects
      soundEffects = !soundEffects;
      break;
    case 'G': // toggle beween gameModes (only in mainMenu)
      if(mainMenu) {
        switch(gameMode){
          case endless:
            gameMode = music;
            println("now in music mode");
            setup();
            return;
          case music:
          println("now in endless mode");
            gameMode = endless;
            return;
        }
      }
      break; // mute the sound effects
    case 'R': // rewind the song
      if(gameMode == music) {
        if(bg.position() == bg.length()) {
          rewindSong();
        }
      }
      break;
    }
  // cheats ie changing score and internal variables
  if (cheatsEnabled) {
    switch(keyCode){
      // case 'Q':
      //   rotDamp -= 0.005;
      //   break;
      // case 'E':
      //   rotDamp += 0.003;
      //   break;
      case 'D': // increase score by 1
        score++;
        break;
      case 'W': // decrease score by 1
        score += 10;
        break;
      case 'A': // decrease score by 1
        score--;
        break;
      case 'S': // decrease score by 10
        score -= 10;
        break;
      }
  }
}

public void keyReleased() { // listen for user input // touchEnded
  if(clockwise){
    // if(soundEffects) {
    //   sLeft.trigger();
    // }
    rotVel = max(-150, -22-rotVel/5);
  }
  clockwise = false;
}
//// this is the dodger class, which is an entity controlled by player input
class Dodger {

  //the dodger has x and y coordinates and an angle
  PVector pos;
  PVector move;
  float a;
  float size = dodgerSize;
  float vel = startVel;
  float auraTrans = 0;
                     // scales dodger aura

  Dodger (float _x, float _y, float _a) {
    pos = new PVector(_x, _y);
    a = _a;
  }

  //// draw the aura of dodger
  public void drawAura(boolean scrType, PVector cPos, int scale) {
    // scrType false: score true:highScore

    pg.pushMatrix();
    pg.translate(cPos.x, cPos.y);

    // float auraSize = 1 + map(score, 0, highScore + 10, 0, 2);

    pg.noStroke();
    // if(!clockwise){
    //   pg.fill(255, 255, 255, 35);
    // } else {
    //   pg.fill(255, 255, 255, 45);
    // }
    auraTrans = (map(abs(rotVel), 0, 110, 30, 70) + auraTrans)/2;
    pg.fill(255, 255, 255, auraTrans);
    if(!scrType) {
      float intscore = score - score%1; // to get a round number
      pg.ellipse(0, 0, 2*size*(                             intscore% 9 /9 * scale/7),                       2*size*(     intscore% 9 /9 * scale/7) );
      pg.ellipse(0, 0, 2*size*(                ((intscore- (intscore%9))/9)%9/9 * scale/5),              2*size*( ((intscore- (intscore%9))/9)%9/9 * scale/5) );
      pg.stroke(255, 255, 255, 100);
      pg.strokeWeight(4);
      pg.ellipse(0, 0, 2*size*(   ((intscore- (intscore%81) )/81)%9/9 * scale/4), 2*size*(  ((intscore- (intscore%81) )/81)%9/9* scale/4) );
      pg.noStroke();
      pg.fill(0);
      pg.ellipse(0, 0, size, size);
    } else {
      pg.ellipse(0, 0, 2*size*(                             highScore% 9 /9 * scale/7),                             2*size*(     highScore% 9 /9 * scale/7) );
      pg.ellipse(0, 0, 2*size*(                ((highScore- (highScore%9))/9)%9/9 * scale/5),                2*size*( ((highScore- (highScore%9))/9)%9/9 * scale/5) );
      pg.stroke(255, 255, 255, 100);
      pg.strokeWeight(4);
      pg.ellipse(0, 0, 2*size*(   ((highScore- (highScore%81))/81)%9/9 * scale/4), 2*size*(  ((highScore- (highScore%81))/81)%9/9* scale/4) );
    }
    pg.noStroke();
    pg.popMatrix();
  }

  //// draw dodger
  public void draw() {
    pg.rectMode(CENTER);
    pg.pushMatrix();
    pg.translate(pos.x, pos.y);
    pg.rotate(a);
    // rect(0, 0, sin(a)*30, 50);
    pg.stroke(255);
    pg.strokeWeight(6);
    float legMod = map(rotVel, 0, 100, 0, 10);
    if(!clockwise) legMod *= -1;
    pg.line(-0.5f * size, -1 * size + legMod, 0, 1 * size);
    pg.line(0.5f * size, -1 * size - legMod, 0, 1 * size);
    pg.line(-0.4f * size, -0.6f * size, 0.4f * size, -0.6f * size); //back line
    pg.popMatrix();
  }

  //// update dodger position
  public void update() {
    //dodger moves
    move = new PVector(0, vel + score*scVel); // velocity adjust
    if(!clockwise){
      a -= 0.001f * rotVel;
    } else {
      a += 0.001f * rotVel;
    }
    move = move.rotate(a);
    pos.add(move);
  }

  //// check if dodger is inside the boundaries
  public void bounds() {
    if(mainMenu && (pos.x < 0+200 || pos.x > pgWidth-200 || pos.y < 0+200 || pos.y > pgHeight-200)) {
      menuRun();
    }
    if(pos.x < 0+size*2/3) {
      pos.x = 0+size*2/3;
    } else if(pos.x > pgWidth-size*2/3) {
      pos.x = pgWidth-size*2/3;
    }
    if(pos.y < 0+size*2/3) {
      pos.y = 0+size*2/3;
    } else if(pos.y > pgHeight-size*2/3) {
      pos.y = pgHeight-size*2/3;
    }
  }
}
//// this is the dodger class, which is an entity controlled by player input
class Enemy {
  //the obstacle has x and y coordinates and an angle
  PVector pos;
  PVector move;
  PVector nPos;
  String type;
  //ship, kamikaze, asteroid, onoff
  //boss 1 2 3 3b
  int hp; // health points of aura
  int maxHp; // health points of aura
  float a; //
  float size;
  float vel;
  float [] rndmAst = new float[16]; //random zahlen array fuer asteroid vertex

  boolean auraTouched = false;
  boolean auraActive = true;
  float bossCFactor = 1.5f;              // boss has smaller aura and no add
  int spawnTimer = millis();
  int popTimer = 0;                   // timer that gets set when the aura gets harvested
  int popDuration = 450;             // duration of the aura harvest effect (aura lights up and then disappears)
  int untouchable = 6000; // time the bosses are untouchable
  float transparency;
  float rotation = random(-1, 1);
  float rotationVel = 0.03f;
  float rotationPos = 0;

  //// construct the obstacle
  Enemy (float _x, float _y, float _a, float _vel, String _type) {
    pos = new PVector(_x, _y);
    a = _a;
    type = _type;
    if(type == "asteroid"){
      size = startSize + score*scESize;
      size *= random(0.7f, 1.4f); // RNG for obstacle size
      vel = _vel * random(0.7f, 1.3f) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(size/4, size*5/4);
      }
      hp = PApplet.parseInt((35 + score/50) / changeVel);
    }
    if(type == "sinusoid"){
      size = startSize + score*scESize;
      size *= random(0.7f, 1.4f); // RNG for obstacle size
      vel = _vel * random(0.7f, 1.3f) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(size/4, size*5/4);
      }
      hp = PApplet.parseInt((35 + score/50) / changeVel);
    }
    if(type == "ship"){
      size = startSize + score*scESize;
      size *= random(0.6f, 1.2f); // RNG for obstacle size
      vel = _vel * random(1.2f, 1.7f) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = PApplet.parseInt((25 + score/40) /changeVel);
    }
    if(type == "kamikaze"){
      size = startSize + score*scESize;
      size *= random(0.6f, 1.2f); // RNG for obstacle size
      vel = _vel * random(0.8f, 1.2f) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = PApplet.parseInt((20 + score/15) /changeVel);
    }
    if(type == "onoff"){
      size = startSize + score*scESize;
      size *= random(0.6f, 1.2f); // RNG for obstacle size
      vel = _vel * random(0.4f, 0.8f) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = PApplet.parseInt((45 + score/15) /changeVel);
    }
    if(type == "boss1"){
      size = 100 + (startSize + score*scESize)*0.4f + modifier/4;
      size *= random(0.9f, 1.1f); // RNG for obstacle size
      vel = _vel * random(0.6f, 0.95f) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(4, size);
        hp = PApplet.parseInt(250 + modifier / changeVel);
        //+ int(score/8);
      }
    }
    if(type == "boss2"){
      size = 100 + (startSize + score*scESize/2)/5 + modifier/5;
      size *= random(0.9f, 1.1f); // RNG for obstacle size
      vel = _vel * random(0.9f, 1.1f) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(4, size);
        hp = PApplet.parseInt(300 + modifier / changeVel);
        //+ int(score/8);
      }
    }
    if(type == "boss3"){
      size = dodger.size*2;
      vel = (dodger.vel + score*scVel) * 1;
      hp = PApplet.parseInt(220 + modifier / changeVel);
      a = dodger.a + PI;
      bossCFactor = bossCFactor * 2;
    }
    if(type == "boss3b"){
      size = dodger.size*2;
      vel = (dodger.vel + score*scVel) * 1.5f;
      hp = PApplet.parseInt(160 + modifier / changeVel);
      a = dodger.a + HALF_PI;
      bossCFactor = bossCFactor * 1.5f;
    }
    maxHp = hp;
  }

  //// draw the aura of the obstacle
  public void drawAura() {
    pg.pushMatrix();
    pg.translate(pos.x, pos.y);
    if(!auraTouched && auraActive) {
      pg.noStroke();
      if(type == "boss1" || type == "boss2" || type == "boss3" || type == "boss3") {
        pg.fill(255, 255, 255, auraTransparency + map(hp, 15, maxHp, 0, 60) );
        pg.ellipse(0, 0, 2*size*bossCFactor, 2*size*bossCFactor);
        pg.fill(0);
        pg.ellipse(0, 0, size, size);
      } else {
        pg.fill(255, 255, 255, auraTransparency + map(hp, 15, maxHp, 0, 60) );
        pg.ellipse(0, 0, 2*size*auraFactor + auraAdd, 2*size*auraFactor + auraAdd);
      }
    }
    if(popTimer != 0 && popTimer > millis() - popDuration ) {
      // make the aura light up for popDuration/2 and then fade out again
      float popTransparency = map(abs(millis()-popTimer-popDuration/2), 0, popDuration/2, 40, 0);

      pg.noStroke();
      if(type == "boss1" || type == "boss2" || type == "boss3" || type == "boss3") {
        pg.fill(255, 255, 255, auraTransparency + popTransparency );
        pg.ellipse(0, 0, 2*size*bossCFactor, 2*size*bossCFactor);
        pg.fill(0);
        pg.ellipse(0, 0, size, size);
      } else {
        pg.fill(255, 255, 255, popTransparency );
        float auraSize = map(millis() - popTimer, 0, popDuration, 1, 0);
        auraSize *= 2*size*auraFactor + auraAdd;
        pg.ellipse(0, 0, auraSize, auraSize);
      }
    }
    if(!auraActive) {
      pg.fill(0, 0, 0, 60);
      pg.strokeWeight(1);
      pg.stroke(255, 255, 255);
      pg.ellipse(0, 0, 2*size*auraFactor + auraAdd, 2*size*auraFactor + auraAdd);
    }
    pg.noStroke();
    pg.popMatrix();
  }

  //// draw the obstacle
  public void draw() {
    pg.fill(0);
    pg.rectMode(CENTER);
    pg.ellipseMode(CENTER);

    pg.pushMatrix();
    pg.translate(pos.x, pos.y);
    pg.rotate(a);
    if(!auraTouched) {
      pg.stroke(255);
      pg.fill(0);
    } else {
      pg.stroke(255);
      pg.fill(255);
    }
    pg.strokeWeight(3);
    if(type == "ship") {
      pg.beginShape();
              pg.vertex(-0.4f * size, -1 * size);
              pg.vertex(0.4f * size, -1 *size);
              pg.vertex(0.9f * size, -0.66f * size);
              pg.vertex(0.9f * size, -0.33f * size);
              pg.vertex(0.4f * size, 0);
              pg.vertex(0.4f * size, 0.66f * size);
              pg.vertex(0, 1 * size);
              pg.vertex(-0.4f * size, 0.66f * size);
              pg.vertex(-0.4f * size, 0);
              pg.vertex(-0.9f * size, -0.33f * size);
              pg.vertex(-0.9f * size, -0.66f * size);
              pg.vertex(-0.4f * size, -1 * size);
            pg.endShape();
    } else if(type == "asteroid") {
      rotationPos = rotationPos + rotationVel * rotation;
      pg.rotate(rotationPos);
      pg.beginShape();
        pg.vertex(0, -rndmAst[1]);
        pg.vertex(rndmAst[2], 0);
        pg.vertex(0, rndmAst[3]);
        pg.vertex(-rndmAst[4], 0);
        pg.vertex(-12, -12);
        pg.vertex(0, -rndmAst[1]);
      pg.endShape();
    } else if(type == "sinusoid") {
      pg.beginShape();
        pg.vertex(-0.5f * size,   -1 * size);
        pg.vertex(0          ,    1 * size);
        pg.vertex(0.5f * size ,   -1 * size);
        pg.vertex(0          , -0.3f * size);
        pg.vertex(-0.5f * size,   -1 * size);
      pg.endShape();
      pg.pushMatrix();
      pg.rotate(sin((frameCount + spawnTimer)/TWO_PI/5 )/2);
      pg.stroke(0);
      pg.fill(0);
      if(!auraTouched) pg.triangle(0, -size*2, -size/3, -size, size/3, -size);
      // pg.ellipse(0, size*2, size/4, size/4);
      pg.popMatrix();
    } else if(type == "kamikaze") {
      pg.beginShape();
        pg.vertex(-0.5f * size,   -1 * size);
        pg.vertex(0          ,    1 * size);
        pg.vertex(0.5f * size ,   -1 * size);
        pg.vertex(0          , -0.3f * size);
        pg.vertex(-0.5f * size,   -1 * size);
      pg.endShape();
    } else if(type == "onoff") {
      pg.beginShape();
        pg.vertex(-1 * size, -1 * size);
        pg.vertex(-0.7f * size, -1 * size);
        pg.vertex(-0.7f * size, -0.8f * size);
        pg.vertex(0.7f * size, -0.8f * size);
        pg.vertex(0.7f * size, -1 * size);
        pg.vertex(1 * size, -1 * size);
        pg.vertex(1 * size, -0.35f * size);
        pg.vertex(0.5f * size, -0.1f * size);
        //insert lil wing here
        //-------------------
        pg.vertex(0.5f * size, 0.5f * size);
        pg.vertex(0, 1 * size);
        pg.vertex(-0.5f * size, 0.5f * size);
        //insert lil wing here
        //-------------------
        pg.vertex(-0.5f * size, -0.1f * size);
        pg.vertex(-1 * size, -0.35f * size);
        pg.vertex(-1 * size, -1 * size);
        //vertex(-0.8 * size, -1 * size);
        //vertex(-0.8 * size, -0.8 * size);
        //vertex(-0.8 * size, -0.8 * size);
        pg.vertex(-0.8f * size, -1 * size);
        pg.vertex(-1 * size, -1 * size);
      pg.endShape();
    } else if(type == "boss1") {
      transparency = map(millis() - spawnTimer, 0, untouchable, 55, 255);
      if(!auraTouched) {
        pg.stroke(255, 255, 255, transparency);
        pg.fill(255-transparency, 255-transparency, 255-transparency);
      } else {
        pg.stroke(255);
        pg.fill(255);
      }
      pg.beginShape();
        pg.vertex(-0.32f * size, -0.6f * size);
        pg.vertex(0.32f * size, -0.6f * size);
        pg.vertex(0.32f * size, -0.5f * size);
        pg.vertex(0.54f * size, -0.5f * size);
        pg.vertex(0.54f * size, -0.6f * size);
        pg.vertex(0.59f * size, -0.6f * size);
        pg.vertex(0.59f * size, 0.6f * size);
        pg.vertex(0.54f * size, 0.6f * size);
        pg.vertex(0.54f * size, 0.3f * size);
        pg.vertex(0.32f * size, 0.3f * size);
        pg.vertex(0.32f * size, 0.5f * size);
        pg.vertex(0.16f * size, 0.56f * size);
        pg.vertex(0.16f * size, 0.83f * size);
        pg.vertex(0, 0.6f * size);
        pg.vertex(-0.16f * size, 0.83f * size);
        pg.vertex(-0.16f * size, 0.56f * size);
        pg.vertex(-0.32f * size, 0.5f * size);
        pg.vertex(-0.32f * size, 0.3f * size);
        pg.vertex(-0.54f * size, 0.3f * size);
        pg.vertex(-0.54f * size, 0.6f * size);
        pg.vertex(-0.59f * size, 0.6f * size);
        pg.vertex(-0.59f * size, -0.6f * size);
        pg.vertex(-0.54f * size, -0.6f * size);
        pg.vertex(-0.54f * size, -0.5f * size);
        pg.vertex(-0.32f * size, -0.5f * size);
        pg.vertex(-0.32f * size, -0.59f * size);
      pg.endShape();
      // draws the spawnTimer ellipse
      // pg.ellipse(0, 0, size, size);
      // pg.stroke(0);
      // pg.fill(0);
      // pg.ellipse(0, size, size/3, size/3);
    } else if(type == "boss2") {
      transparency = map(millis() - spawnTimer, 0, untouchable, 55, 255);
      if(!auraTouched) {
        pg.stroke(255, 255, 255, transparency);
        pg.fill(255-transparency, 255-transparency, 255-transparency);
      } else {
        pg.stroke(255);
        pg.fill(255);
      }
      // draws the spawnTimer ellipse
      pg.ellipse(0, 0, size, size);
      pg.stroke(0);
      pg.fill(0);
      pg.ellipse(0, size, size/3, size/3);
    } else if(type == "boss3" || type == "boss3b") {
      transparency = map(millis() - spawnTimer, 0, untouchable, 55, 255);
      if(!auraTouched) {
        pg.stroke(255, 255, 255, transparency);
        pg.fill(255-transparency, 255-transparency, 255-transparency);
      } else {
        pg.stroke(255);
        pg.fill(255);
      }
      // draws the spawnTimer ellipse
      pg.stroke(255);
      pg.strokeWeight(6);
      pg.line(-0.5f * size, -1 * size, 0, 1 * size);
      pg.line(0.5f * size, -1 * size, 0, 1 * size);
      pg.line(-0.4f * size, -0.6f * size, 0.4f * size, -0.6f * size); //back line
  }
    pg.popMatrix();
  }

  //// update obstacle position
  public void update() {
    if(type == "kamikaze" && !auraTouched){
      // slowly turn towards the player
      a = turnTowardsPlayer(0.05f);
    }
    if(type == "onoff" && !auraTouched){
      // turn towards the player
      a = turnTowardsPlayer(0.7f);
      // toggle aura on off
      int toggleTime = 6000;
      if(millis() - spawnTimer > toggleTime) {
        auraActive = !auraActive;
        spawnTimer = millis();
      }
    }
    if(type == "sinusoid" && !auraTouched){
      // slowly turn towards the player
      a += sin((frameCount + spawnTimer)/TWO_PI/5)/50;
    }
    if(type == "boss2" && !auraTouched){
      // slowly turn towards the player
      a = turnTowardsPlayer(0.02f);
    }
    if(type == "boss3" && !auraTouched){
      // slowly turn towards the player
      a = dodger.a + PI;
    }
    if(type == "boss3b" && !auraTouched){
      // slowly turn towards the player
      a = dodger.a + HALF_PI;
    }
    move = new PVector(0, vel);
    move = move.rotate(a);
    pos.add(move);
    //dodger moves
  }

  //// check if obstacle is still inside bounds
  public boolean bounds() {
    if(type == "boss1"){
      // put boss back into the field if aura was not broken. Also, increase it's velocity.
      boolean bounded = false; // went against boundary?
      // left
      if( (pos.x < 0-bossCFactor || pos.x > pgWidth+bossCFactor || pos.y < 0-bossCFactor || pos.y > pgHeight+bossCFactor) && !auraTouched){
        a = turnTowardsPlayer(1);
        bounded = true;
      //if one of the above and auraTouched
      } else if (bounded && !auraTouched) {
          if(auraTouched) return true;
          vel *= 1.1f;
      }
      return false;
    } else if(type == "boss2"){
      return false;
    } else if((type == "boss3" || type == "boss3b") && !auraTouched){
      if(pos.x < 0+size*2/3) {
        pos.x = 0+size*2/3;
      } else if(pos.x > pgWidth-size*2/3) {
        pos.x = pgWidth-size*2/3;
      }
      if(pos.y < 0+size*2/3) {
        pos.y = 0+size*2/3;
      } else if(pos.y > pgHeight-size*2/3) {
        pos.y = pgHeight-size*2/3;
      }
      return false;
    } else if((type == "boss3" || type == "boss3b") && auraTouched && (pos.x < 0-bossCFactor || pos.x > pgWidth+bossCFactor || pos.y < 0-bossCFactor || pos.y > pgHeight+bossCFactor) ) {
      return true;
    } else if( pos.x < 0-1.1f*(auraFactor+auraAdd) || pos.x > pgWidth+1.1f*(auraFactor+auraAdd)|| pos.y < 0-1.1f*(auraFactor+auraAdd) || pos.y > pgHeight+1.1f*(auraFactor+auraAdd) ) {
      return true;
    } else {
      return false;
    }
  }

  //// check if dodger collides with the obstacle
  public boolean collision() {
    // don't collide with boss if it just spawned
    if (type == "boss1"  || type == "boss2") {
      if(millis() - spawnTimer < 6000) return false;
      if(pos.dist(dodger.pos) <= (0.5f*size + dodger.size) ) {
        return true;
      } else {
        return false;
      }
    }
    if(pos.dist(dodger.pos) <= (0.5f*(size + dodger.size)) ) {
      return true;
    } else {
      return false;
    }
  }

  //// check if dodger collides with the enemies aura
  public boolean auraCollision() {
    if (type == "onoff" && !auraActive) {
      return false;
    }
    if (type == "boss1"  || type == "boss2") {
      // don't allow damage if boss can't do any either?
      // if(millis() - spawnTimer < 6000) return false;
      pg.pushMatrix();
      pg.translate(pos.x, pos.y);
      // pg.ellipse(0, 0, (size+dodger.size), (size+dodger.size));
      pg.popMatrix();

      if(pos.dist(dodger.pos) <= size*bossCFactor) {
        return true;
      } else {
        return false;
      }
    }
    if(pos.dist(dodger.pos) <= (size*auraFactor + auraAdd/2 + dodger.size) ) {
      return true;
    } else {
      return false;
    }
  }

  public float turnTowardsPlayer(float lerpFactor) {
    PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
    PVector pointToPlayer = PVector.fromAngle(nPos.heading() - HALF_PI);
    PVector direction = PVector.fromAngle(a);
    direction.lerp(pointToPlayer, lerpFactor);
    return direction.heading();
  }
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "dodgernew" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
