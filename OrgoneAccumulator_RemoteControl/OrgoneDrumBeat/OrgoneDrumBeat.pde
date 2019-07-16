// Drumbeat //<>// //<>//
//
// be sure to download the companion OA code
//
// compile problem:  "No library found for controlP5"  
//  1. select Menu option <Sketch><Import Library><Add Library...>
//  2. type ControlP5 into edit field to narrow the search
//  3. select and install ControlP5 by Andreas Schiegel
//
// please send problems, comments and ideas to Harry:  kosalos@cox.net
// ====================================================================================================

import processing.serial.*;
import controlP5.*;
import static javax.swing.JOptionPane.*;
import java.awt.event.MouseEvent.*;
import java.util.*;

final color BLUECOLOR = color(19, 52, 82);
final color HIGHLIGHTCOLOR = color(80, 120, 80);

final int WINDOWXS = 970;
final int WINDOWYS = 580;

final int NUM_BAND = 8;
final int NUM_SLIDER = 10;
final int BASE_ID_PER_ROW = 100;

final int GRP_X = 10;
final int GRP_Y = 10;
final int GRP_XS = WINDOWXS - 20;
final int GRP_YS = 200;
final int GRP_BAR_X = 262;
final int GRP_BAR_Y = GRP_Y + 9;
final int GRP_BAR_XS = 700;
final int GRP_BAR_YS = NUM_BAND * 23;
final int BAND_X = GRP_X;
final int BAND_Y = 235;
final int BAND_XS = WINDOWXS - 20;
final int BAND_YS = 30;
final int BAND_YHOP = 5;
final int BAND_SLIDER_XS = 80;
final int BAND_X_HOP = BAND_SLIDER_XS+10;
final int EVOLVE_X = GRP_X;
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
final int CBOX_ID = 10;    // check box (x,fm,fix) in each band

final int CV_MIN = 0;
final int CV_MAX = 8191;
final int CV_CENTER = 4096;

final int ID_LOAD = 1000;  // button IDs
final int ID_SAVE = 1001;
final int ID_RANDOM = 1002;
final int ID_HELP = 1003;
final int ID_EVOLVE_MASTER = 1004;
final int ID_EVOLVE = 1005;

final String evolveLegend = "Evolve (E)";
boolean evolveFlag = false;
boolean requestSendDataset = false;

class Band {
  Textfield cvRange;
  Slider[] slider = new Slider[NUM_SLIDER];
  CheckBox cb;
  int rangeLow, rangeHigh;
}

Band[] band = new Band[NUM_BAND];
Slider filter;
CheckBox evolve;

byte gateStatus = 0;

ControlP5 controlP5;
Serial port;
PFont font14;

boolean isRightMouseButtonPressed = false;
int rightMouseButtonX1, rightMouseButtonX2;

final int CURSORMEMORY = 80;
int cursorIndex = 0;
int[] cMemory = new int[CURSORMEMORY];

// ==================================================================

void draw() 
{ 
  background(80, 80, 80);

  // group panel -------------------------------
  fill(90);
  rect(GRP_X, GRP_Y, GRP_XS, GRP_YS);

  fill(80);
  stroke(255);
  rect(GRP_BAR_X-1, GRP_BAR_Y, GRP_BAR_XS+2, GRP_BAR_YS);

  // right Mouse session -------------
  if (isRightMouseButtonPressed) {
    fill(50, 200, 50);
    rect(rightMouseButtonX1, GRP_BAR_Y, rightMouseButtonX2 - rightMouseButtonX1, GRP_BAR_YS);
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
    rect(cMemory[index]-1, GRP_BAR_Y+1, 2, GRP_BAR_YS-2);
    fillColor -= 2;
    if (fillColor < 80) fillColor = 80;
  }

  // current CV position ------
  fill(color(255, 0, 0));
  stroke(color(255, 0, 0));
  rect(x-1, GRP_BAR_Y+1, 2, GRP_BAR_YS-2);

  // band number legends --------
  int xp = GRP_X + 10;
  int yp = GRP_Y + 23;
  int yhop = 18+5;
  fill(255);
  textFont(font14);
  for (int i=0; i<NUM_BAND; ++i) {
    text(nf(i+1), xp, yp);
    yp += yhop;
  }

  // group bands -------------------------------
  for (int i=0; i<NUM_BAND; ++i) {
    color c = (i == activeBandIndex) ? HIGHLIGHTCOLOR : BLUECOLOR;
    fill(c);
    stroke(c);

    x = GRP_BAR_X + int( float(band[i].rangeLow * GRP_BAR_XS) / float(CV_MAX));
    int xs = int( float((band[i].rangeHigh - band[i].rangeLow) * GRP_BAR_XS) / float(CV_MAX)) - 1;
    if (xs > 0)
      rect(x, GRP_BAR_Y + 2  + i * 23, xs, 18);
  }

  // band panels --------------------------------
  yp = BAND_Y;
  for (int i=0; i<NUM_BAND; ++i) {
    fill(isActiveband(i) ? 100 : 70);
    if (i == activeBandIndex) fill(HIGHLIGHTCOLOR);
    rect(BAND_X, yp, BAND_XS, BAND_YS);

    fill(255);
    text(nf(i+1), xp, yp + 20);

    yp += BAND_YS+BAND_YHOP;
  }

  // band legends -------------------------------
  fill(255);
  String legend = "CV Offset      Waveform 1    Waveform 2    Waveform 3" +
    "       Position            Effect              Index" +
    "          Frequency           Mod          X     FM    Fix";
  text(legend, 42, BAND_Y-6);

  // evolve panel -------------------------------
  fill(90);
  rect(EVOLVE_X, EVOLVE_Y, EVOLVE_XS, EVOLVE_YS);

  fill(color(255));
  text(nf(activeBandIndex+1), GRP_BAR_X+GRP_BAR_XS-20, GRP_BAR_Y+GRP_BAR_YS-25);
  text(nf(currentCV), GRP_BAR_X+GRP_BAR_XS-40, GRP_BAR_Y+GRP_BAR_YS-5);

  if (evolveFlag)
    performEvolve();

  monitorSerialPort();
  filterCV();

  if (++pace > 5) pace = 0;

  if (requestSendDataset && pace == 0) {
    requestSendDataset = false;
    sendDataset();
  }
}

int pace = 0;

// ==================================================================

void keyPressed() 
{
  int ch = key;
  if (ch > 'Z') ch -= ('a' - 'A');

  if (ch >= '1' && ch <= '8') {
    cloneBandSettings(ch - '1');
    return;
  }

  switch(ch) {
  case 'L' : 
    loadSession();
    break;
  case 'S' : 
    saveSession();
    break;
  case 'R' : 
    randomize();
    break;
  case 'E' : 
    toggleEvolve();
    break;
  case 'H' :
    showHelp();
    break;
  }
}

// ==================================================================

void cloneBandSettings(int src) {
  backDoor = true;

  for (int dest=0; dest<NUM_BAND; ++dest) {
    if (dest == src) continue;
    for (int i=1; i<NUM_SLIDER; ++i)     // skip 0 : don't alter CV slider
      band[dest].slider[i].setValue(band[src].slider[i].getValue());

    for (int i=0; i<3; ++i) {
      if (band[src].cb.getArrayValue()[i] > 0) 
        band[dest].cb.activate(i); 
      else 
      band[dest].cb.deactivate(i);
    }
  }

  clearAllSliderValueLabels();
  backDoor = false;
}

// ==================================================================

int rtMouse1, rtMouse2;

// X coord -> 0 .. MAX_CV
int mapMousePosition(int xCoord) { 
  return int(float(xCoord - GRP_BAR_X) * 8192.0 / float(GRP_BAR_XS));
}

void mousePressedOrDragged(boolean clicked)
{
  if (mouseX < GRP_BAR_X || mouseX > GRP_BAR_X+GRP_BAR_XS) return;
  if (mouseY < GRP_BAR_Y || mouseY > GRP_BAR_Y+GRP_BAR_YS) return;

  if (mouseButton == LEFT) {
    int index = int(float(mouseY - GRP_BAR_Y) / 23.0);
    band[index].slider[CV_ID].setValue(mapMousePosition(mouseX));
    ensureBandCVsAreInOrder();
  } else {  
    if (clicked) {
      isRightMouseButtonPressed = (mouseButton == RIGHT);
      rightMouseButtonX1 = mouseX;
      rightMouseButtonX2 = mouseX;
    } else
      rightMouseButtonX2 = mouseX;
  }
}

void mousePressed() { 
  mousePressedOrDragged(true);
}

void mouseDragged() { 
  mousePressedOrDragged(false);
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
      band[i].slider[CV_ID].setValue(v2 - diff * float(i));

    ensureBandCVsAreInOrder();
  }
}

// ==================================================================
// does specified band control a range of input CV values?

boolean isActiveband(int row)
{
  int top = CV_MAX;
  int bottom = (int)band[row].slider[CV_ID].getValue();
  if (row > 0) 
    top = (int)band[row-1].slider[CV_ID].getValue();

  if (top > 0) --top; 

  return top-bottom > 1;
}
