class UI {
  //draw filled Box
  void fillBox(String label, int startX, int startY, int boxWidth, int boxHeight, float value, float lowBound, float highBound, boolean showBound) {
    /*
    draws a box UI element from startX, startY with set width and height
    box has a white outline and is filled white based on the relation of value to lowBound and highBound

    */

    pg.rectMode(CORNER);
    pg.pushMatrix();
    pg.translate(startX, startY);
    //draws white outline und black fill in full size
    pg.fill(0, 0, 0, 200);
    pg.stroke(255);
    pg.strokeWeight(4);
    pg.rect(0, 0, boxWidth, boxHeight);
    //draws white fill based on value
    pg.fill(255, 255, 255, 133);

    if(value >= highBound){
      pg.rect(0, 0, boxWidth, boxHeight);
    } else if(value > lowBound) {
      float boxFill = map(value, lowBound, highBound, 0, boxWidth);
      pg.rect(0, 0, boxFill, boxHeight); // left to right
    } else {
    }
    // draw label
    pg.fill(255);
    pg.textSize(16);
    pg.noStroke();
    pg.textAlign(LEFT);
    pg.text(label, 10, boxHeight+15);
    // draw upper boundary
    pg.textAlign(RIGHT);
    if(showBound) pg.text(int(highBound), boxWidth-10, boxHeight+15);
    pg.popMatrix();
  }

  /*
  draws a bar chart from any array within a rectangle space
  */
}
