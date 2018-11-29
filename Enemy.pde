class Enemy {
  //the dodger has x and y coordinates and an angle
  PVector pos;
  PVector move;
  PVector nPos;
  String type;
  //ship, kamikaze, asteroid
  int hp; // health points of circle
  int maxHp; // health points of circle
  float a;
  float size;
  float vel;
  float [] rndmAst = new float[16]; //random zahlen array fuer asteroid vertex

  boolean circleTouched = false;
  boolean circleActive = true;
  float bossCFactor = 1.5;              // boss has smaller circle and no add
  int spawnTimer = millis();
  int popTimer = 0;                   // timer that gets set when the aura gets harvested
  int popDuration = 450;             // duration of the aura harvest effect (aura lights up and then disappears)
  int untouchable = 6000; // time the bosses are untouchable
  float transparency;
  float rotation = random(-1, 1);

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
      vel = _vel * random(0.45, 0.9) + score * scEVel;
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
      bossCFactor = bossCFactor * 1.5;
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
  void drawCircle() {
    pg.pushMatrix();
    pg.translate(pos.x, pos.y);
    if(!circleTouched && circleActive) {
      pg.noStroke();
      if(type == "boss1" || type == "boss2" || type == "boss3" || type == "boss3") {
        pg.fill(255, 255, 255, circleTransparency + map(hp, 15, maxHp, 0, 60) );
        pg.ellipse(0, 0, 2*size*bossCFactor, 2*size*bossCFactor);
        pg.fill(0);
        pg.ellipse(0, 0, size, size);
      } else {
        pg.fill(255, 255, 255, circleTransparency + map(hp, 15, maxHp, 0, 60) );
        pg.ellipse(0, 0, 2*size*circleFactor + circleAdd, 2*size*circleFactor + circleAdd);
      }
    }
    if(popTimer != 0 && popTimer > millis() - popDuration ) {
      // make the aura light up for popDuration/2 and then fade out again
      float popTransparency = map(abs(millis()-popTimer-popDuration/2), 0, popDuration/2, 40, 0);

      pg.noStroke();
      if(type == "boss1" || type == "boss2" || type == "boss3" || type == "boss3") {
        pg.fill(255, 255, 255, circleTransparency + popTransparency );
        pg.ellipse(0, 0, 2*size*bossCFactor, 2*size*bossCFactor);
        pg.fill(0);
        pg.ellipse(0, 0, size, size);
      } else {
        pg.fill(255, 255, 255, popTransparency );
        float circleSize = map(millis() - popTimer, 0, popDuration, 1, 0);
        println(circleSize);
        circleSize *= 2*size*circleFactor + circleAdd;
        pg.ellipse(0, 0, circleSize, circleSize);
      }
    }
    if(!circleActive) {
      pg.fill(0, 0, 0, 60);
      pg.strokeWeight(1);
      pg.stroke(255, 255, 255);
      pg.ellipse(0, 0, 2*size*circleFactor + circleAdd, 2*size*circleFactor + circleAdd);
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
    if(!circleTouched) {
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
      pg.rotate(frameCount*0.03*rotation);
      pg.beginShape();
        pg.vertex(0, -rndmAst[1]);
        pg.vertex(rndmAst[2], 0);
        pg.vertex(0, rndmAst[3]);
        pg.vertex(-rndmAst[4], 0);
        pg.vertex(-12, -12);
        pg.vertex(0, -rndmAst[1]);
      pg.endShape();
    } else if(type == "kamikaze") {
      scale(0.6);
      pg.beginShape();
        pg.vertex(-0.32 * size, -1 * size);
        pg.vertex(0.32 * size, -1 * size);
        pg.vertex(0.32 * size, -0.5 * size);
        pg.vertex(0.64 * size, -0.5 * size);
        pg.vertex(0.64 * size, -1 * size);
        pg.vertex(0.9 * size, -1 * size);
        pg.vertex(0.9 * size, 1 * size);
        pg.vertex(0.64 * size, 1 * size);
        pg.vertex(0.64 * size, 0.3 * size);
        pg.vertex(0.32 * size, 0.3 * size);
        pg.vertex(0.32 * size, 0.5 * size);
        pg.vertex(0.16 * size, 0.66 * size);
        pg.vertex(0.16 * size, 0.83 * size);
        pg.vertex(0, 1 * size);
        pg.vertex(-0.16 * size, 0.83 * size);
        pg.vertex(-0.16 * size, 0.66 * size);
        pg.vertex(-0.32 * size, 0.5 * size);
        pg.vertex(-0.32 * size, 0.3 * size);
        pg.vertex(-0.64 * size, 0.3 * size);
        pg.vertex(-0.64 * size, 1 * size);
        pg.vertex(-0.9 * size, 1 * size);
        pg.vertex(-0.9 * size, -1 * size);
        pg.vertex(-0.64 * size, -1 * size);
        pg.vertex(-0.64 * size, -0.5 * size);
        pg.vertex(-0.32 * size, -0.5 * size);
        pg.vertex(-0.32 * size, -1 * size);
      pg.endShape();
      scale(1/0.6);
    } else if(type == "onoff") {
      pg.ellipse(0, 0, size, size);
      pg.stroke(0);
      pg.fill(0);
      pg.ellipse(0, size, size/3, size/3);
    } else if(type == "boss1") {
      transparency = map(millis() - spawnTimer, 0, untouchable, 55, 255);
      if(!circleTouched) {
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
    } else if(type == "boss2") {
      transparency = map(millis() - spawnTimer, 0, untouchable, 55, 255);
      if(!circleTouched) {
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
      if(!circleTouched) {
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
    if(type == "kamikaze" && !circleTouched){
      // slowly turn towards the player
      a = turnTowardsPlayer(0.05);
    }
    if(type == "onoff" && !circleTouched){
      // turn towards the player
      a = turnTowardsPlayer(0.7);
      // toggle aura on off
      int toggleTime = 6000;
      if(millis() - spawnTimer > toggleTime) {
        circleActive = !circleActive;
        spawnTimer = millis();
      }
    }
    if(type == "boss2" && !circleTouched){
      // slowly turn towards the player
      a = turnTowardsPlayer(0.02);
    }
    if(type == "boss3" && !circleTouched){
      // slowly turn towards the player
      a = dodger.a + PI;
    }
    if(type == "boss3b" && !circleTouched){
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
      if( (pos.x < 0-bossCFactor || pos.x > pgWidth+bossCFactor || pos.y < 0-bossCFactor || pos.y > pgHeight+bossCFactor) && !circleTouched){
        a = turnTowardsPlayer(1);
        bounded = true;
      //if one of the above and circleTouched
      } else if (bounded && !circleTouched) {
          if(circleTouched) return true;
          vel *= 1.1;
      }
      return false;
    } else if(type == "boss2"){
      return false;
    } else if((type == "boss3" || type == "boss3b") && !circleTouched){
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
    } else if((type == "boss3" || type == "boss3b") && circleTouched && (pos.x < 0-bossCFactor || pos.x > pgWidth+bossCFactor || pos.y < 0-bossCFactor || pos.y > pgHeight+bossCFactor) ) {
      return true;
    } else if( pos.x < 0-1.1*(circleFactor+circleAdd) || pos.x > pgWidth+1.1*(circleFactor+circleAdd)|| pos.y < 0-1.1*(circleFactor+circleAdd) || pos.y > pgHeight+1.1*(circleFactor+circleAdd) ) {
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
  boolean circleCollision() {
    if (type == "onoff" && !circleActive) {
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
    if(pos.dist(dodger.pos) <= (size*circleFactor + circleAdd/2 + dodger.size) ) {
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
