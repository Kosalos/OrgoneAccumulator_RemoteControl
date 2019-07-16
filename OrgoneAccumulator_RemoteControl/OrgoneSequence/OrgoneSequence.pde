// OrgoneSequence
//
// be sure to download the companion OA code
//
// compile problem:  "No library found for controlP5"  
//  1. select Menu option <Sketch><Import Library><Add Library...>
//  2. type ControlP5 into edit field to narrow the search
//  3. select and install ControlP5 by Andreas Schiegel
//
// This program is a mate to the special OrgoneAccumulator (OA) code that includes serial communication.
//
// please send problems, comments and ideas to Harry:  kosalos@cox.net
// ====================================================================================================

import processing.serial.*;
import controlP5.*;
import static javax.swing.JOptionPane.*;
import java.awt.event.MouseEvent.*;
import javax.sound.midi.*;
import java.util.*;

final int WINDOWXS = 1070;
final int WINDOWYS = 665;

final int S_COUNT = 9; // # 2bytes slider values
final int C_COUNT = 3; // # 1bytes checkboxes
final int NUM_CV = S_COUNT + C_COUNT;

final int NUM_PAD = 32;
final int MIN_PAD = 3;
final int NUM_TIMING = 6;

final int NUM_ROW = 20;
final int SPEED_MIN = 1;
final int SPEED_MAX = 24;

final int BOTTOMY = 5+NUM_ROW*20;

final int RNDX = 10;
final int RNDY = BOTTOMY+5;
final int RNDXS = 400;
final int RNDYS = 80;

final int TIMINGX = RNDX + RNDXS + 5;
final int TIMINGY = RNDY;
final int TIMINGXS = WINDOWXS-TIMINGX-10;
final int TIMINGYS = RNDYS;

final int BUTTON_ROW = BOTTOMY + 95;
final int ASSIGNX = 172;
final int SEQX = 420;

final int DEFAULT_PANEL_X = 10;
final int DEFAULT_PANEL_Y = BUTTON_ROW + 30;
final int DEFAULT_PANEL_XS = 325;
final int DEFAULT_PANEL_YS = 130;
final int DEFAULT_BAR_XS = 120;

final int GLISS_PANEL_X = DEFAULT_PANEL_X + DEFAULT_PANEL_XS + 7;
final int GLISS_PANEL_Y = DEFAULT_PANEL_Y;
final int GLISS_PANEL_XS = 295;
final int GLISS_PANEL_YS = DEFAULT_PANEL_YS;
final int GLISS_MIN_TICK = 2;
final int GLISS_MAX_TICK = 100;

final int STATUS_PANEL_X = GLISS_PANEL_X + GLISS_PANEL_XS + 7;
final int STATUS_PANEL_Y = DEFAULT_PANEL_Y;
final int STATUS_PANEL_XS = 325;
final int STATUS_PANEL_YS = DEFAULT_PANEL_YS;

final color BLUECOLOR = color(19, 52, 82);
final color HIGHLIGHTCOLOR = color(138, 16, 24);  

final int ID_STARTSTOP = 500;
final int ID_RESET = 501;
final int ID_RNDPADPLUS = 502;
final int ID_RNDPADMINUS = 503; 
final int ID_EVOLVE = 504;
final int ID_SAVESEQ = 505;
final int ID_LOADSEQ = 506;
final int ID_GLISSFLAG = 507;
final int ID_RND_CV = 508;
final int ID_RND_ALL = 509;
final int ID_HELP = 510;
final int ID_RNDPLUS = 511;
final int ID_RNDMINUS = ID_RNDPLUS + NUM_CV;
final int ID_TIMING = ID_RNDMINUS + NUM_CV;

class Dataset { 
  int[] cv = new int[NUM_CV];  // sliderData + checkboxData
}

Dataset[] cvEntry = new Dataset[NUM_PAD];
Dataset temp = new Dataset();

class SequenceRow {
  Slider noteSlider;
  CheckBox matrixCB;
  CheckBox assignCB;
  int note;
  byte[] assign = new byte[NUM_CV];
  byte[] matrix = new byte[NUM_PAD];
}

class Sequence {
  SequenceRow[] row = new SequenceRow[NUM_ROW];
}

Sequence seq;

ControlP5 controlP5;
Serial port;
PFont fnt, fnt2;         

Button startStop;
Slider speed;
Slider numPads;

Slider[] defaults = new Slider[NUM_CV];

boolean[] glissandoFlag = new boolean[NUM_CV];
boolean glissandoWrapFlag = false;
CheckBox[] glissC = new CheckBox[NUM_CV];
Slider[] glissS = new Slider[NUM_CV];
Button glissandoWrap;

Slider[] timing = new Slider[NUM_PAD];

boolean isPlaying = false;
boolean backDoor = false;  // set when you want to update widgets without side effects
boolean evolveFlag = false;
byte gateStatus = 0;

int playIndex;
int playSpeed = 5;
int playSpeedT;
int playPace;
int padCount = 32;

final String glissandoWrapLegend = "WrapAround";
final String autoSaveFilename = "OrgoneSequence.seq"; 
final String startStopLegend = "Start/Stop  (Spc)";
final String evolveLegend = "Evolve   (E)";
final String speedLegend = "Speed  (1,2)";
final String numPadsLegend = "#Pads (3,4)";
final String[] checkBoxLegend = {  " V", "W1", "W2", "W3", " P", " E", "  I", " F", "M", " X", "FM", "Fix" };
final String checkBoxLegend2 = "(V: V/Oct;    W1,W2,W3: Waveforms;    P: Position;    E: Effect;   I: Index;    F: Freq;   M : Mod;    X,FM,Fix: Mod switches)";

// ==================================================================

void draw() 
{ 
  background(100);

  int TOPY = 14;
  fill(255);
  textFont(fnt, 10);
  for (int i=0; i<NUM_CV; ++i)
    text(checkBoxLegend[i], ASSIGNX+i*20+2, TOPY);

  textFont(fnt, 12);
  text("CV Input", 10, TOPY);
  text("Sequencer Markers. Check columns where note should be sounded.", 550, TOPY);
  text(checkBoxLegend2, ASSIGNX+240, BUTTON_ROW+15);

  drawDefaultPanel();
  drawGlissandoPanel();
  drawRandomPanel();
  drawTimingPanel();

  if (isPlaying) {
    // dwelled long enough at current matrix index = advance to next column
    if (++playPace >= playSpeedT) {
      playPace = 0;
      if (++playIndex >= padCount)
        playIndex = 0;
      determinePlaySpeedT();

      gateStatus = 1;
      transmitSequencerValues();
    } else {
      gateStatus = 0;
      transmitInterpolatedSequencerValues();
    }
  }

  if (evolveFlag) {
    if (percentChance(50)) {
      if (percentChance(20)) {
        int r = (int)random(0, NUM_ROW-1);
        int n = (int)random(0, 7000);
        seq.row[r].noteSlider.setValue(n);
      }
      if (percentChance(20)) {
        int r = (int)random(0, NUM_ROW-1);
        int n = (int)random(0, NUM_CV);
        if (random(0, 1) < 0.5)
          seq.row[r].assignCB.activate(n);
        else
          seq.row[r].assignCB.deactivate(n);
      }
      if (percentChance(20)) {
        int r = (int)random(0, NUM_ROW-1);
        int n = (int)random(0, NUM_PAD);
        if (random(0, 1) < 0.5)
          seq.row[r].matrixCB.activate(n);
        else
          seq.row[r].matrixCB.deactivate(n);
      }
    }
  }

  drawPlayIndexPipMark();
  drawPadCountLine();
  drawStatusPanel();
  monitorSerialPort();
}

// ==================================================================

void drawPlayIndexPipMark()
{
  int x1 = SEQX;
  int y1 = 306;

  fill(100);
  stroke(100);
  rect(x1, y1, 630, 7);

  fill(255);
  x1 += 3 + playIndex*20;
  rect(x1, y1, 7, 7);
}


// ==================================================================

void drawDefaultPanel()
{
  fill(120);
  stroke(0);
  rect(DEFAULT_PANEL_X, DEFAULT_PANEL_Y, DEFAULT_PANEL_XS, DEFAULT_PANEL_YS);

  int i = 0;
  int xp = DEFAULT_PANEL_X + 10;
  int yp = DEFAULT_PANEL_Y + 30;

  for (; i< 6; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+12);
    yp += 16;
  }

  xp += DEFAULT_BAR_XS + 40;
  yp = DEFAULT_PANEL_Y + 30;

  for (; i< NUM_CV; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+12);
    yp += 16;
  }

  fill(255);
  textFont(fnt, 15);
  text("Default", DEFAULT_PANEL_X + 10, DEFAULT_PANEL_Y + 20);
}

// ==================================================================

void drawGlissandoPanel()
{
  fill(90);
  stroke(0);
  rect(GLISS_PANEL_X, GLISS_PANEL_Y, GLISS_PANEL_XS, GLISS_PANEL_YS);

  int i = 0;
  int xp = GLISS_PANEL_X + 10;
  int yp = GLISS_PANEL_Y + 30;

  textFont(fnt, 12);

  for (; i< 6; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+12);
    yp += 16;
  }

  xp += DEFAULT_BAR_XS + 20;
  yp = GLISS_PANEL_Y + 30;

  for (; i< NUM_CV; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+12);
    yp += 16;
  }

  fill(255);
  textFont(fnt, 15);
  text("Glissando (G)", GLISS_PANEL_X + 10, GLISS_PANEL_Y + 20);
}

// ==================================================================

void drawRandomPanel() 
{
  fill(90);
  stroke(0);
  rect(RNDX, RNDY, RNDXS, RNDYS);

  fill(255);
  textFont(fnt, 12);
  text("Randomize", RNDX+10, RNDY+23);
}

void drawPadCountLine()
{
  if (padCount == NUM_PAD) return;
  fill(255);
  int xp = SEQX + padCount * 20 - 3;
  rect(xp, 19, 3, NUM_ROW * 19 + 5);
}

// ==================================================================

void drawTimingPanel() 
{
  fill(90);
  stroke(0);
  rect(TIMINGX, TIMINGY, TIMINGXS, TIMINGYS);

  //fill(255);
  //textFont(fnt, 12);
  //text("Randomize", RNDX+10, RNDY+23);
}

// ==================================================================

final int STATUS_XP = STATUS_PANEL_X+28;
final int STATUS_BAR_XS = 100;
final int STATUS_BAR_YS = 8;

void drawStatusPanelBar(int xp, int yp, int value, int colorCode, int width)
{
  int xs = width * value / 8191;
  stroke(0);

  xp += 25; // hop past legend text

  if (colorCode == 0)
    fill(30, 144, 255);
  else
    fill(30, 255, 120);
  rect(xp, yp, xs, STATUS_BAR_YS);

  fill(80);
  rect(xp+xs, yp, width-xs, STATUS_BAR_YS);
}

void drawStatusPanel()
{
  fill(90);
  stroke(0);
  rect(STATUS_PANEL_X, STATUS_PANEL_Y, STATUS_PANEL_XS, STATUS_PANEL_YS);

  int i = 0;
  int xp = STATUS_PANEL_X+10;
  int yp = STATUS_PANEL_Y+32;

  for (; i< 6; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+8);
    drawStatusPanelBar(xp, yp, temp.cv[i], 0, STATUS_BAR_XS);
    yp += 16;
  }

  xp += STATUS_BAR_XS + 50;
  yp = STATUS_PANEL_Y+32;

  for (; i< NUM_CV; ++i) { 
    fill(255);
    text(checkBoxLegend[i], xp, yp+8);
    drawStatusPanelBar(xp, yp, temp.cv[i], (i >= S_COUNT) ? 1 : 0, (i >= S_COUNT) ? 20 : STATUS_BAR_XS);
    yp += 16;
  }

  fill(255);
  textFont(fnt, 15);
  text("Status", STATUS_PANEL_X + 10, STATUS_PANEL_Y + 20);
}

// ==================================================================

void changeSpeed(int dir) 
{
  playSpeed = constrain(playSpeed + dir, SPEED_MIN, SPEED_MAX);

  if (speed != null) {
    backDoor = true;
    speed.setValue(playSpeed);
    backDoor = false;
    speed.setValueLabel("");
  }

  determinePlaySpeedT();
}

void changePads(int dir) 
{
  padCount = constrain(padCount + dir, MIN_PAD, NUM_PAD);
  if (numPads != null)
    numPads.setValue(padCount);
}

// ==================================================================

void keyPressed() 
{
  int ch = key;
  if (ch > 'Z') ch -= ('a' - 'A');

  switch(ch) {
  case '1' : 
    changeSpeed(+1); 
    break;
  case '2' : 
    changeSpeed(-1); 
    break;
  case '3' : 
    changePads(-1); 
    break;
  case '4' : 
    changePads(+1); 
    break;
  case ' ' :  // start/stop
    handleEvent(ID_STARTSTOP);
    break;
  case 'A' :
    randomizeAll();
    break;
  case 'C' :
    randomizeCV();
    break;
  case 'S' :  // reset
    handleEvent(ID_RESET);
    break;
  case 'R' :  // random+
    handleEvent(ID_RNDPADPLUS);
    break;
  case 'T' :  // random-
    handleEvent(ID_RNDPADMINUS);
    break;
  case 'E' :  // evolve
    handleEvent(ID_EVOLVE);
    break;
  case 'G' :
    toggleAllGlissando();
    break;
  case 'H' :
    showHelp();
    break;
  case '8' :
    cvEntryDebug();
    break;
  case '9' :
    debug();
    break;
  }
}

// ==================================================================

void transmitSequencerValues()
{
  sendDataset(cvEntry[playIndex]);
}

void transmitInterpolatedSequencerValues()
{
  int index2 = playIndex+1;
  if (index2 >= NUM_PAD) index2 = 0;

  int i;

  for (i=0; i<NUM_CV; ++i) {
    boolean applyGlissando = glissandoFlag[i];

    // 'wrap' is disabled, and no more matrix entries till end of sequence = no more glissando
    if (applyGlissando && index2 == 0 && !glissandoWrapFlag)
      applyGlissando = false;

    if (applyGlissando) {
      // playSpeed = #ticks per sequencer pad
      // playPace = #ticks elapsed so far for current pad
      // gTicks = #ticks for glissando effect for this CV

      int gTicks = (int)glissS[i].getValue();
      float ratio;

      if (playPace >= gTicks) // gliss effect has already finished
        ratio = 1;
      else
        ratio = (float)playPace / (float)gTicks; // gliss effect still executing

      temp.cv[i] = (int)((float)cvEntry[playIndex].cv[i] + (float)(cvEntry[index2].cv[i] - cvEntry[playIndex].cv[i]) * ratio);
    } else
      temp.cv[i] = cvEntry[playIndex].cv[i];

    // last 3 controls are digital
    if (i >= NUM_CV-C_COUNT) {
      temp.cv[i] = temp.cv[i] >= 8192/2 ? 8191 : 0;
    }
  }

  sendDataset(temp);
}

// ==================================================================
// propagate matrix entry from column i1 to i2
// if glissando is active then interpolate intermediate entries, else 
// just copy i1's value to intermediate entries

void glissando(int cvIndex, int i1, int i2)
{
  int iDiff = i2-i1;      // # intermediate entries
  if (iDiff < 2) return;
  // println("CV:" + cvIndex + " i1: " + i1 + " i2:" + i2);

  if (!glissandoFlag[cvIndex]) { // no gliss; just copy i1's value
    for (int i=i1+1; i<i2; ++i) 
      cvEntry[i].cv[cvIndex] = cvEntry[i1].cv[cvIndex];
  } else {
    int vDiff = cvEntry[i2].cv[cvIndex] - cvEntry[i1].cv[cvIndex];  // value difference
    float vHop = (float)vDiff / (float)iDiff;    // amount of value difference per intermediate entry
    float value = (float)cvEntry[i1].cv[cvIndex]; // starting interpolation value = i1's

    for (int i=i1+1; i<i2; ++i) {
      value += vHop;
      cvEntry[i].cv[cvIndex] = (int)value;
    }
  }
}

// wrap around from last note back to iFirst
void glissando2(int cvIndex, int i1, int i2) // i1 is higher than i2
{
  if (i1 == -1) return;
  if (i2 == -1) return;
  //println("first:" + i1 + ", iLast:" + i2);

  int iDiff = (NUM_PAD - i1) + i2;
  if (iDiff < 2) return;

  if (!glissandoFlag[cvIndex]) {
    for (int i=1; i<iDiff; ++i) {
      int index = i1+i;
      if (index >= NUM_PAD) index -= NUM_PAD;
      cvEntry[index].cv[cvIndex] = cvEntry[i1].cv[cvIndex];
    }
  } else {
    int vDiff = cvEntry[i2].cv[cvIndex] - cvEntry[i1].cv[cvIndex];
    float vHop = (float)vDiff / (float)iDiff;
    float value = (float)cvEntry[i1].cv[cvIndex];

    for (int i=1; i<iDiff; ++i) {
      value += vHop;
      int index = i1+i;
      if (index >= NUM_PAD) index -= NUM_PAD;
      cvEntry[index].cv[cvIndex] = (int)value;
    }
  }
}

// copy current glissando values to end of matrix
void glissandoToEnd(int cvIndex, int i1)
{
  if (i1 == -1) return;

  for (int i=i1+1; i<NUM_PAD; ++i) 
    cvEntry[i].cv[cvIndex] = cvEntry[i1].cv[cvIndex];
}

// ==================================================================
// cvEntry[] = calculated CV values for every matrix position

void determineCvEntries()
{
  for (int m=0; m<NUM_CV; ++m) {
    int currentValue = (int)defaults[m].getValue(); // use defauilt setting unless Pad overwrites it

    for (int p=0; p<NUM_PAD; ++p) {
      for (int r=0; r<NUM_ROW; ++r) {
        if ((seq.row[r].matrix[p] > 0) && (seq.row[r].assign[m] > 0)) 
          currentValue = seq.row[r].note;
      }

      cvEntry[p].cv[m] = currentValue;
      if (m >= 9 && cvEntry[p].cv[m] > 8191/2) cvEntry[p].cv[m] = 8191; // toggle switch entries
    }
  }

  // glissando -----------------
  int iFirst=-1, iLast=-1, i1, i2;
  for (int m=0; m<NUM_CV; ++m) {
    i1 = 0;
    iFirst = -1;
    iLast = -1;

    for (;; ) {
      // find 1st entry
      for (; i1<NUM_PAD; ++i1)
        if (cvEntry[i1].cv[m] > 0) break;
      if (i1 == NUM_PAD) break;  // none
      if (iFirst == -1) iFirst = i1;

      // find 2nd entry
      for (i2=i1+1; i2<NUM_PAD; ++i2)
        if (cvEntry[i2].cv[m] > 0) break;
      if (i2 == NUM_PAD) break;  // none
      iLast = i2;

      glissando(m, i1, i2);
      i1 = i2;
    }

    if (glissandoWrapFlag)
      glissando2(m, iLast, iFirst);
    else
      glissandoToEnd(m, iLast);
  }

  //  cvEntryDebug();
}

// ==================================================================

void cvEntryDebug()
{
  println();
  for (int m=0; m<1; ++m) {
    print("CV" + m + ": ");
    for (int p=0; p<NUM_PAD; ++p) 
      print(cvEntry[p].cv[m] + ", ");
    println();
  }
}

// ==================================================================

void receivedTrigger()
{
}
