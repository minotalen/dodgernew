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
  void drawCircle(boolean scrType, PVector cPos, int scale) {
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
    auraTrans = (map(abs(rotVel), 0, 110, 30, 55) + auraTrans)/2;
    pg.fill(255, 255, 255, auraTrans);
    if(!scrType) {
      pg.ellipse(0, 0, 2*size*(                             score% 9 /9 * scale/7),                       2*size*(     score% 9 /9 * scale/7) );
      pg.ellipse(0, 0, 2*size*(                ((score- (score%9))/9)%9/9 * scale/5),              2*size*( ((score- (score%9))/9)%9/9 * scale/5) );
      pg.stroke(255, 255, 255, 100);
      pg.strokeWeight(4);
      pg.ellipse(0, 0, 2*size*(   ((score- (score%81) )/81)%9/9 * scale/4), 2*size*(  ((score- (score%81) )/81)%9/9* scale/4) );
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
  void draw() {
    pg.rectMode(CENTER);
    pg.pushMatrix();
    pg.translate(pos.x, pos.y);
    pg.rotate(a);
    // rect(0, 0, sin(a)*30, 50);
    pg.stroke(255);
    pg.strokeWeight(6);
    pg.line(-0.5 * size, -1 * size, 0, 1 * size);
    pg.line(0.5 * size, -1 * size, 0, 1 * size);
    pg.line(-0.4 * size, -0.6 * size, 0.4 * size, -0.6 * size); //back line
    pg.popMatrix();
  }

  //// update dodger position
  void update() {
    //dodger moves
    move = new PVector(0, vel + score*scVel); // velocity adjust
    if(!clockwise){
      a -= 0.001 * rotVel;
    } else {
      a += 0.001 * rotVel;
    }
    move = move.rotate(a);
    pos.add(move);
  }

  //// check if dodger is inside the boundaries
  void bounds() {
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
