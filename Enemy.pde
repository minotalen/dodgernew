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
  float bossCFactor = 1.5;              // boss has smaller aura and no add
  int spawnTimer = millis();
  int popTimer = 0;                   // timer that gets set when the aura gets harvested
  int popDuration = 450;             // duration of the aura harvest effect (aura lights up and then disappears)
  int untouchable = 6000; // time the bosses are untouchable
  float transparency;
  float rotation = random(-1, 1);
  float rotationVel = 0.03;
  float rotationPos = 0;

  //// construct the obstacle
  Enemy (float _x, float _y, float _a, float _vel, String _type) {
    pos = new PVector(_x, _y);
    a = _a;
    type = _type;
    if(type == "asteroid"){
      size = startSize + score*scESize;
      size *= random(0.7, 1.4); // RNG for obstacle size
      vel = _vel * random(0.7, 1.3) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(size/4, size*5/4);
      }
      hp = int((35 + score/50) / changeVel);
    }
    if(type == "sinusoid"){
      size = startSize + score*scESize;
      size *= random(0.7, 1.4); // RNG for obstacle size
      vel = _vel * random(0.7, 1.3) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(size/4, size*5/4);
      }
      hp = int((35 + score/50) / changeVel);
    }
    if(type == "ship"){
      size = startSize + score*scESize;
      size *= random(0.6, 1.2); // RNG for obstacle size
      vel = _vel * random(1.2, 1.7) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = int((25 + score/40) /changeVel);
    }
    if(type == "kamikaze"){
      size = startSize + score*scESize;
      size *= random(0.6, 1.2); // RNG for obstacle size
      vel = _vel * random(0.8, 1.2) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = int((20 + score/15) /changeVel);
    }
    if(type == "onoff"){
      size = startSize + score*scESize;
      size *= random(0.6, 1.2); // RNG for obstacle size
      vel = _vel * random(0.4, 0.8) + score * scEVel;
      //set angle to player
      PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
      a = nPos.heading() - HALF_PI;
      hp = int((45 + score/15) /changeVel);
    }
    if(type == "boss1"){
      size = 100 + (startSize + score*scESize)*0.4 + modifier/4;
      size *= random(0.9, 1.1); // RNG for obstacle size
      vel = _vel * random(0.6, 0.95) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(4, size);
        hp = int(250 + modifier / changeVel);
        //+ int(score/8);
      }
    }
    if(type == "boss2"){
      size = 100 + (startSize + score*scESize/2)/5 + modifier/5;
      size *= random(0.9, 1.1); // RNG for obstacle size
      vel = _vel * random(0.9, 1.1) + score * scEVel;
      for (int i=0; i < rndmAst.length; i++){
        rndmAst[i] = random(4, size);
        hp = int(300 + modifier / changeVel);
        //+ int(score/8);
      }
    }
    if(type == "boss3"){
      size = dodger.size*2;
      vel = (dodger.vel + score*scVel) * 1;
      hp = int(220 + modifier / changeVel);
      a = dodger.a + PI;
      bossCFactor = bossCFactor * 2;
    }
    if(type == "boss3b"){
      size = dodger.size*2;
      vel = (dodger.vel + score*scVel) * 1.5;
      hp = int(160 + modifier / changeVel);
      a = dodger.a + HALF_PI;
      bossCFactor = bossCFactor * 1.5;
    }
    maxHp = hp;
  }

  //// draw the aura of the obstacle
  void drawAura() {
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
  void draw() {
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
              pg.vertex(-0.4 * size, -1 * size);
              pg.vertex(0.4 * size, -1 *size);
              pg.vertex(0.9 * size, -0.66 * size);
              pg.vertex(0.9 * size, -0.33 * size);
              pg.vertex(0.4 * size, 0);
              pg.vertex(0.4 * size, 0.66 * size);
              pg.vertex(0, 1 * size);
              pg.vertex(-0.4 * size, 0.66 * size);
              pg.vertex(-0.4 * size, 0);
              pg.vertex(-0.9 * size, -0.33 * size);
              pg.vertex(-0.9 * size, -0.66 * size);
              pg.vertex(-0.4 * size, -1 * size);
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
        pg.vertex(-0.5 * size,   -1 * size);
        pg.vertex(0          ,    1 * size);
        pg.vertex(0.5 * size ,   -1 * size);
        pg.vertex(0          , -0.3 * size);
        pg.vertex(-0.5 * size,   -1 * size);
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
        pg.vertex(-0.5 * size,   -1 * size);
        pg.vertex(0          ,    1 * size);
        pg.vertex(0.5 * size ,   -1 * size);
        pg.vertex(0          , -0.3 * size);
        pg.vertex(-0.5 * size,   -1 * size);
      pg.endShape();
    } else if(type == "onoff") {
      pg.beginShape();
        pg.vertex(-1 * size, -1 * size);
        pg.vertex(-0.7 * size, -1 * size);
        pg.vertex(-0.7 * size, -0.8 * size);
        pg.vertex(0.7 * size, -0.8 * size);
        pg.vertex(0.7 * size, -1 * size);
        pg.vertex(1 * size, -1 * size);
        pg.vertex(1 * size, -0.35 * size);
        pg.vertex(0.5 * size, -0.1 * size);
        //insert lil wing here
        //-------------------
        pg.vertex(0.5 * size, 0.5 * size);
        pg.vertex(0, 1 * size);
        pg.vertex(-0.5 * size, 0.5 * size);
        //insert lil wing here
        //-------------------
        pg.vertex(-0.5 * size, -0.1 * size);
        pg.vertex(-1 * size, -0.35 * size);
        pg.vertex(-1 * size, -1 * size);
        //vertex(-0.8 * size, -1 * size);
        //vertex(-0.8 * size, -0.8 * size);
        //vertex(-0.8 * size, -0.8 * size);
        pg.vertex(-0.8 * size, -1 * size);
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
        pg.vertex(-0.32 * size, -0.6 * size);
        pg.vertex(0.32 * size, -0.6 * size);
        pg.vertex(0.32 * size, -0.5 * size);
        pg.vertex(0.54 * size, -0.5 * size);
        pg.vertex(0.54 * size, -0.6 * size);
        pg.vertex(0.59 * size, -0.6 * size);
        pg.vertex(0.59 * size, 0.6 * size);
        pg.vertex(0.54 * size, 0.6 * size);
        pg.vertex(0.54 * size, 0.3 * size);
        pg.vertex(0.32 * size, 0.3 * size);
        pg.vertex(0.32 * size, 0.5 * size);
        pg.vertex(0.16 * size, 0.56 * size);
        pg.vertex(0.16 * size, 0.83 * size);
        pg.vertex(0, 0.6 * size);
        pg.vertex(-0.16 * size, 0.83 * size);
        pg.vertex(-0.16 * size, 0.56 * size);
        pg.vertex(-0.32 * size, 0.5 * size);
        pg.vertex(-0.32 * size, 0.3 * size);
        pg.vertex(-0.54 * size, 0.3 * size);
        pg.vertex(-0.54 * size, 0.6 * size);
        pg.vertex(-0.59 * size, 0.6 * size);
        pg.vertex(-0.59 * size, -0.6 * size);
        pg.vertex(-0.54 * size, -0.6 * size);
        pg.vertex(-0.54 * size, -0.5 * size);
        pg.vertex(-0.32 * size, -0.5 * size);
        pg.vertex(-0.32 * size, -0.59 * size);
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
      pg.line(-0.5 * size, -1 * size, 0, 1 * size);
      pg.line(0.5 * size, -1 * size, 0, 1 * size);
      pg.line(-0.4 * size, -0.6 * size, 0.4 * size, -0.6 * size); //back line
  }
    pg.popMatrix();
  }

  //// update obstacle position
  void update() {
    if(type == "kamikaze" && !auraTouched){
      // slowly turn towards the player
      a = turnTowardsPlayer(0.05);
    }
    if(type == "onoff" && !auraTouched){
      // turn towards the player
      a = turnTowardsPlayer(0.7);
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
      a = turnTowardsPlayer(0.02);
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
  boolean bounds() {
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
          vel *= 1.1;
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
    } else if( pos.x < 0-1.1*(auraFactor+auraAdd) || pos.x > pgWidth+1.1*(auraFactor+auraAdd)|| pos.y < 0-1.1*(auraFactor+auraAdd) || pos.y > pgHeight+1.1*(auraFactor+auraAdd) ) {
      return true;
    } else {
      return false;
    }
  }

  //// check if dodger collides with the obstacle
  boolean collision() {
    // don't collide with boss if it just spawned
    if (type == "boss1"  || type == "boss2") {
      if(millis() - spawnTimer < 6000) return false;
      if(pos.dist(dodger.pos) <= (0.5*size + dodger.size) ) {
        return true;
      } else {
        return false;
      }
    }
    if(pos.dist(dodger.pos) <= (0.5*(size + dodger.size)) ) {
      return true;
    } else {
      return false;
    }
  }

  //// check if dodger collides with the enemies aura
  boolean auraCollision() {
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

  float turnTowardsPlayer(float lerpFactor) {
    PVector nPos = new PVector(-pos.x + dodger.pos.x, -pos.y + dodger.pos.y);
    PVector pointToPlayer = PVector.fromAngle(nPos.heading() - HALF_PI);
    PVector direction = PVector.fromAngle(a);
    direction.lerp(pointToPlayer, lerpFactor);
    return direction.heading();
  }
}
