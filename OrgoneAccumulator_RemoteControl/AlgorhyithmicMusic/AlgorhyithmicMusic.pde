// Algorhyithmic Music
// Be sure to download the companion OA code
//
// Please send problems, comments and ideas to Harry:  kosalos@cox.net
// ====================================================================================================

import processing.serial.*;
import static javax.swing.JOptionPane.*;
import java.awt.event.MouseEvent.*;
import java.util.*;

final color BLUECOLOR = color(19, 52, 82);
final color HIGHLIGHTCOLOR = color(80, 120, 80);

final int WINDOWXS = 970;
final int WINDOWYS = 888;

final int NUM_BAND = 8;
final int NUM_BAND_VALUE = 10;
final int BASE_ID_PER_ROW = 100;

final int HIST_X = 10;
final int HIST_Y = 140;
final int HIST_XS = WINDOWXS - 20;
final int HIST_YS = 200;

final int GRP_X = HIST_X;
final int GRP_Y = HIST_Y+HIST_YS+5;
final int GRP_XS = WINDOWXS - 20;
final int GRP_YS = 200;
final int GRP_BAR_X = 136;
final int GRP_BAR_Y = GRP_Y + 9;
final int GRP_BAR_XS = GRP_XS-GRP_BAR_X;
final int GRP_BAR_YS = NUM_BAND * 23;
final int BAND_X = HIST_X;
final int BAND_Y = GRP_Y + 225;
final int BAND_XS = WINDOWXS - 20;
final int BAND_YS = 30;
final int BAND_YHOP = 5;
final int BAND_SLIDER_XS = 80;
final int BAND_X_HOP = BAND_SLIDER_XS+10;
final int EVOLVE_X = HIST_X;
final int EVOLVE_Y = BAND_Y + (BAND_YS + 5) * NUM_BAND;
final int EVOLVE_XS = GRP_XS;
final int EVOLVE_YS = 30;

final int CV_ID = 0;      // indices of sliders in each band
final int OFFSET_ID = 1;
final int WAVE1_ID = 2;
final int WAVE2_ID = 3;
final int WAVE3_ID = 4;
final int POSITION_ID = 5;
final int EFFECT_ID = 6;
final int INDEX_ID = 7;
final int FREQ_ID = 8;
final int MOD_ID = 9;

final int CBOX_ID1 = 10;    // check boxes (x,fm,fix) in each band
final int CBOX_ID2 = 11;
final int CBOX_ID3 = 12;
final int LEGEND_ID = 13;

final int FRAME_ID = 14;
final int EVOLVECHECK_ID = 15;
final int EVOLVEMASTER_ID = 16;
final int CVRANGE_ID = 17;    // 8 ids
final int SMOOTHING_ID = 25;
final int LOADSESSION_ID = 26;
final int SAVESESSION_ID = 27;
final int RANDOMIZE_ID = 28;
final int HELP_ID = 29;
final int SENDGATE_ID = 30;
final int EQUATIONPARAM_ID = 31; // MAX_EQUATION_PARAM entries
final int SPEED_ID = 39;
final int MODULO_ID = 40;
final int RANGELOW_ID = 41;
final int RANGEHIGH_ID = 42;
final int PAUSE_ID = 43;
final int REPEAT_ID = 44;
final int PACE_ID = 45;

final int RANDOMIZE2_ID = 1000;

final int MAX_EQUATION_PARAM = 8;

final int CV_MIN = 0;
final int CV_MAX = 8191;
final int CV_CENTER = 4096;

boolean requestSendDataset = false;
int paceSerialTransmission = 0;
byte gateStatus = 0;

Music music = new Music();
Widget widget = new Widget();

Serial port;
PFont fontSmall, fontLarge;

boolean isRightMouseButtonPressed = false;
int rightMouseButtonX1, rightMouseButtonX2;

final int CURSORMEMORY = 80;
int cursorIndex = 0;
int[] cMemory = new int[CURSORMEMORY];

// ==================================================================

void drawBorder(int x, int y, int xs, int ys) {
  rect(x, y, xs, ys);

  stroke(color(60, 60, 60));
  line(x, y, x+xs, y);
  line(x, y, x, y+ys);

  stroke(color(200, 200, 200));
  line(x+xs, y+ys, x+xs, y);
  line(x+xs, y+ys, x, y+ys);
}

// ==================================================================

void draw() { 
  background(80, 80, 80);

  music.iterate();

  // equation
  String eStr = "value = (t >> A) | t | t >> (t >> B) * (1 + C) + ((t >> D) % (1 + E));       t = t + 1;";
  fill(255);
  textFont(fontLarge);
  text(eStr, 10, 25);
  textFont(fontSmall);

  // history panel -------------------------------
  fill(110);
  stroke(0);
  drawBorder(HIST_X, HIST_Y, HIST_XS, HIST_YS);
  drawHistory();

  // group panel -------------------------------
  fill(110);
  stroke(0);
  drawBorder(GRP_X, GRP_Y, GRP_XS, GRP_YS);

  fill(80);
  drawBorder(GRP_BAR_X-1, GRP_BAR_Y, GRP_BAR_XS+2, GRP_BAR_YS);

  int yy1 = GRP_BAR_Y+1;
  int yys = GRP_BAR_YS-2;

  // algo range --------------------
  fill(50, 50, 190);
  stroke(50, 50, 190);
  int x1 = GRP_BAR_X + widget.getValue(RANGELOW_ID) * GRP_BAR_XS / 8192;
  int x2 = GRP_BAR_X + widget.getValue(RANGEHIGH_ID) * GRP_BAR_XS / 8192;
  int xxs = x2-x1;  
  rect(x1, yy1, xxs, yys);

  // right Mouse session -------------
  if (isRightMouseButtonPressed) {
    fill(50, 200, 50);
    rect(rightMouseButtonX1, GRP_BAR_Y+20, rightMouseButtonX2 - rightMouseButtonX1, GRP_BAR_YS-40);
  }

  // group cursor memory --------------------
  int x = GRP_BAR_X + int( float(currentCV * GRP_BAR_XS) / float(CV_MAX+1));
  cMemory[cursorIndex] = x;
  if (++cursorIndex >= CURSORMEMORY) cursorIndex = 0;

  int fillColor = 220;
  int index = cursorIndex;
  for (int i=0; i<CURSORMEMORY; ++i) {
    if (--index < 0) index = CURSORMEMORY-1;
    fill(fillColor);
    stroke(fillColor);
    rect(cMemory[index]-1, yy1, 2, yys);
    fillColor -= 2;
    if (fillColor < 80) fillColor = 80;
  }

  // current CV position ------
  fill(color(255, 0, 0));
  stroke(color(255, 0, 0));
  rect(x-1, GRP_BAR_Y+1, 2, GRP_BAR_YS-2);

  // group bands -------------------------------
  for (int i=0; i<NUM_BAND; ++i) {
    color c = (i == activeBandIndex) ? HIGHLIGHTCOLOR : BLUECOLOR;
    fill(c);
    stroke(c);

    x = GRP_BAR_X + int( float(widget.rangeLow[i] * GRP_BAR_XS) / float(CV_MAX));
    int xs = int( float((widget.rangeHigh[i] - widget.rangeLow[i]) * GRP_BAR_XS) / float(CV_MAX)) - 1;
    if (xs > 0)
      rect(x, GRP_BAR_Y + 2  + i * 23, xs, 18);
  }

  // band legends -------------------------------
  fill(255);
  final String[] legend = { "  CV Offset", " Waveform 1", " Waveform 2", " Waveform 3", "   Position", "    Effect", "    Index", 
    "  Frequency", "     Mod", " X      FM     Fix" };

  for (int i=0; i<10; ++i) 
    text(legend[i], 42+ i*BAND_X_HOP, BAND_Y-6);

  fill(color(255));
  text(nf(currentCV, 1), GRP_BAR_X+GRP_BAR_XS-40, GRP_BAR_Y+GRP_BAR_YS-5);

  widget.performEvolve();

  monitorSerialPort();
  smoothCV();

  // -------------------------------
  if (++paceSerialTransmission > 2) paceSerialTransmission = 0;

  if (requestSendDataset && paceSerialTransmission == 0) {
    requestSendDataset = false;
    sendDataset();

    if (gateStatus == 1) {
      gateStatus = 0;
      requestSendDataset = true;
    }
  }

  widget.draw();
}

// =============================================================

final int HX = HIST_X+10;
final int HY = HIST_Y+10;
final int HXS = HIST_XS-20;
final int HYS = HIST_YS-20;
final int XHOP = 1;
int[] hMem1 = new int[HXS];
int[] hMem2 = new int[HXS];
int hHead = 0;

void drawHistory(int[] data) {
  int oldY, newY = HY+HYS;
  int oldX = HX + HXS-1, newX = oldX;
  int index = hHead;

  for (int x=0; x<HXS; ++x) {
    if (--index < 0) index = HXS-1;
    oldY = newY;
    newY = data[index];
    if (x > 0 && newY != 0)
      line(oldX, oldY, newX, newY);

    oldX = newX;
    newX -= XHOP;
  }
}

void drawHistory() {
  fill(60);
  stroke(0);
  drawBorder(HX, HY, HXS, HYS);

  stroke(color(255,0,0));  // before active Band CVoffset
  fill(color(255,0,0));
  drawHistory(hMem1);

  stroke(255);            // after CV offset
  fill(255);
  drawHistory(hMem2);
}

void addHistory(int v1,int v2) {
  int yp = HY + HYS -1 - v1 * (HYS-4) / CV_MAX;
  hMem1[hHead] = yp;
  
  yp = HY + HYS -1 - v2 * (HYS-4) / CV_MAX;
  hMem2[hHead] = yp;
  
  if (++hHead >= HXS) hHead = 0;
}

// =============================================================
// on-going smoothing of receivedCV -> currentCV 

int currentCV = 0;      // smoothed CV
int receivedCV = 0;     // most recent CV from OA.
int activeBandIndex;    // currently active band index

int oldRowIndex = -1;
int oldCurrentCV = -1;

void smoothCV() {
  float f = float(widget.getValue(SMOOTHING_ID));

  if (f < 2)  // no smoothing
    currentCV = receivedCV;
  else
    currentCV = int((float(currentCV) * f + float(receivedCV)) / (f+1));  

  // determine corresponding band
  for (int i=0; i<NUM_BAND; ++i) {
    if (currentCV >= widget.rangeLow[i] && currentCV <= widget.rangeHigh[i]) {
      activeBandIndex = i;
      break;
    }
  }

  // CV or band assignment changed: send to OA
  if (oldRowIndex != activeBandIndex || oldCurrentCV != currentCV) {
    oldCurrentCV = currentCV;
    oldRowIndex = activeBandIndex;
    requestSendDataset = true;
  }

  finalCV = currentCV + widget.getValue(activeBandIndex*100 + 1) - CV_CENTER;
  finalCV = constrain(finalCV, CV_MIN, CV_MAX);

  addHistory(currentCV,finalCV);
}

// =============================================================

void keyPressed() {
  int ch = key;

  if (key == CODED) {
    switch(keyCode) {
    case UP : 
      widget.moveFocus(-1); 
      return;
    case DOWN : 
      widget.moveFocus(+1); 
      return;
    case LEFT : 
      widget.alterFocusedSlider(-1); 
      return;
    case RIGHT : 
      widget.alterFocusedSlider(+1); 
      return;
    }
  }

  if (ch > 'Z') ch -= ('a' - 'A');

  if (ch >= '1' && ch <= '8') {
    widget.cloneBandSettings(ch - '1');
    return;
  }

  switch(ch) {
  case 'L' : 
    buttonPressed(LOADSESSION_ID);
    return;
  case 'S' : 
    buttonPressed(SAVESESSION_ID);
    return;
  case 'T' :
    buttonPressed(RANDOMIZE2_ID);
    return;
  case 'R' : 
    buttonPressed(RANDOMIZE_ID);
    return;
  case 'E' : 
    buttonPressed(EVOLVEMASTER_ID);
    return;
  case 'G' : 
    buttonPressed(SENDGATE_ID);
    return;
  case 'H' :
    buttonPressed(HELP_ID);
    return;
  case 'P' :
    buttonPressed(PAUSE_ID);
    return;
  case 'Q' :
    alterSpeed(-1);
    return;
  case 'W' :
    alterSpeed(+1);
    return;
  }
}

void alterSpeed(int amt) {
  int v = widget.getValue(SPEED_ID) + amt;
  if (v < 0) v = 0;
  widget.setValue(SPEED_ID, v);
}

void buttonPressed(int id) {
  //println("Button Pressed: " + id);

  switch(id) {
  case LOADSESSION_ID :
    widget.loadSession();
    return;
  case SAVESESSION_ID :
    widget.saveSession();
    return;
  case RANDOMIZE_ID :
    widget.randomize();
    return;
  case HELP_ID :
    showHelp();
    return;
  case SENDGATE_ID :
    widget.flipToggle(id);
    return;
  case EVOLVEMASTER_ID :     
    widget.flipToggle(id);
    return;
  case PAUSE_ID :
    widget.flipToggle(id);
    return;
  case RANDOMIZE2_ID :
    widget.randomize2();
    return;
  }
}

// ==================================================================

int rtMouse1, rtMouse2;

// X coord -> 0 .. MAX_CV
int mapMousePosition(int xCoord) { 
  return int(float(xCoord - GRP_BAR_X) * 8192.0 / float(GRP_BAR_XS));
}

void mousePressedOrDragged(boolean clicked) {
  if (mouseX < GRP_BAR_X || mouseX > GRP_BAR_X+GRP_BAR_XS) return;
  if (mouseY < GRP_BAR_Y || mouseY > GRP_BAR_Y+GRP_BAR_YS) return;

  if (mouseButton == LEFT) {
    int index = int(float(mouseY - GRP_BAR_Y) / 23.0);
    if (index < 0 || index >= NUM_BAND) return;

    widget.setValue(index*100 + 0, mapMousePosition(mouseX));

    widget.ensureBandCVsAreInOrder();
    return;
  } 

  if (clicked) {
    isRightMouseButtonPressed = (mouseButton == RIGHT);
    rightMouseButtonX1 = mouseX;
    rightMouseButtonX2 = mouseX;
  } else
    rightMouseButtonX2 = mouseX;
}

void mousePressed() { 
  mousePressedOrDragged(true);
  widget.mousePressed();
}

void mouseDragged() { 
  mousePressedOrDragged(false);
  widget.mouseDragged();
}

void mouseReleased() { 
  if (isRightMouseButtonPressed) {
    isRightMouseButtonPressed = false;

    // ensure x1 < x2
    if (rightMouseButtonX1 == rightMouseButtonX2) return;

    if (rightMouseButtonX2 < rightMouseButtonX1) {
      int temp = rightMouseButtonX1;
      rightMouseButtonX1 = rightMouseButtonX2;
      rightMouseButtonX2 = temp;
    }

    float v1 = mapMousePosition(rightMouseButtonX1);
    float v2 = mapMousePosition(rightMouseButtonX2);
    float diff = (v2-v1) / float(NUM_BAND-1);

    for (int i=0; i<NUM_BAND; ++i) 
      widget.setValue(i*100 + 0, int(v2 - diff * float(i)));

    widget.ensureBandCVsAreInOrder();
  }
}

void dispose() {
  widget.saveCurrentSettings();
} 
