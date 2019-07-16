int currentCV = 0;      // filtered CV received from OA //<>//
int receivedCV = 0;     // most recent CV from OA.
int activeBandIndex;    // currently active band index

boolean backDoor = false; // set this to prevent recursive controller callbacks during alteration session
boolean isInitialized = false; // coldstart: have all widgets been defined?

void controlEvent(ControlEvent theEvent) 
{
  if (backDoor) return;    // not during randomize(),evolve() calls

  int id = theEvent.getId();
  int row = id/BASE_ID_PER_ROW;
  int widgetIndex = id % BASE_ID_PER_ROW;

  // sliders -------------------------------------
  if (theEvent.isController()) {

    // CV slider controls range of CV input values mapped to particular band
    if (widgetIndex == CV_ID && isInitialized) {
      int value = (int)theEvent.getController().getValue();

      for (int r=0; r<NUM_BAND; ++r) {
        if (r < row) pushCVHigher(r, value); 
        else
          if (r > row) pushCVLower(r, value);
      }

      updateCVRangeTextAllRows();
    } else { // all other sliders
      if (widgetIndex >= OFFSET_ID && widgetIndex <= CBOX_ID) {
        requestSendDataset = true;
        //println("widgetIndex = " + widgetIndex);
      }
    }

    if (isInitialized)
      clearAllSliderValueLabels();
  }

  // checkbox -----------------------------
  if (id == row*BASE_ID_PER_ROW + CBOX_ID) 
    requestSendDataset = true;

  // buttons ------------------------------
  switch(theEvent.getId()) {
  case ID_LOAD :
    loadSession();
    break;
  case ID_SAVE :
    saveSession();
    break;
  case ID_RANDOM :
    randomize();
    break;
  case ID_EVOLVE_MASTER :
    toggleEvolve();
    break;
  case ID_HELP :
    showHelp();
    break;
  }
}

void toggleEvolve()
{
  evolveFlag = !evolveFlag;
  controlP5.getController(evolveLegend).setColorBackground(evolveFlag ? HIGHLIGHTCOLOR : BLUECOLOR);
}

// --------------------------------------------
// ensure band ranges are stacked correctly, and don't cross over each other

void pushCVHigher(int row, int value)
{
  if (band[row].slider[CV_ID].getValue() < value) 
    band[row].slider[CV_ID].setValue(value);
}

void pushCVLower(int row, int value)
{
  int v = (int)band[row].slider[CV_ID].getValue();

  if (v > value) 
    band[row].slider[CV_ID].setValue(value);
}

// --------------------------------------------
// on-going filtering of receivedCV -> currentCV 

int oldRowIndex = -1;
int oldCurrentCV = -1;

void filterCV()
{
  float f = filter.getValue();
  currentCV = int( (float(currentCV) * f + float(receivedCV)) / (f+1));  

  // determine corresponding band
  int bottomOfRange;
  int topOfRange = CV_MAX;

  for (int r=0; r<NUM_BAND; ++r) {
    bottomOfRange = (int)band[r].slider[CV_ID].getValue();
    if (currentCV >= bottomOfRange && currentCV < topOfRange) {
      activeBandIndex = r;
      break;
    }

    topOfRange = bottomOfRange;
  }

  // CV or band assignment changed: send to OA
  if (oldRowIndex != activeBandIndex || oldCurrentCV != currentCV) {
    oldCurrentCV = currentCV;
    oldRowIndex = activeBandIndex;
    requestSendDataset = true;
  }
}

// ==================================================================

Boolean percentChance(int percent)
{
  return (int)random(0, 100) < percent;
}

void randomize() 
{
  backDoor = true;

  int cv = 4000 + (int)random(0, 4100);

  for (int r=0; r<NUM_BAND; ++r) {
    for (int s=0; s<NUM_SLIDER; ++s) {

      // special handling for CV slider
      if (s == CV_ID) {
        band[r].slider[s].setValue(cv);
        cv -= (int)random(50, 1000);
        if (cv < 0) cv = 0;
      } else {
        if (percentChance(30)) 
          band[r].slider[s].setValue(random(CV_MIN, CV_MAX));
      }

      for (int i=0; i<3; ++i) {
        if (percentChance(10)) {
          if (percentChance(50)) 
            band[r].cb.activate(i); 
          else 
          band[r].cb.deactivate(i);
        }
      }
    }

    ensureBandCVsAreInOrder();
    clearAllSliderValueLabels();
  }

  backDoor = false;
}

// ==================================================================

void evolveSliderValue(int row, int column)
{
  float amount = (float)random(1, 100);
  if (percentChance(50)) amount = -amount;

  float v = constrain(band[row].slider[column].getValue() + amount, CV_MIN, CV_MAX);
  band[row].slider[column].setValue(v);
}

void performEvolve() 
{
  if (percentChance(50)) return;
  
  backDoor = true;

  for (int r=0; r<NUM_BAND; ++r) {
    for (int s=0; s<NUM_SLIDER-1; ++s) { 
      if (evolve.getArrayValue()[s] > 0) {
        if (percentChance(10)) 
          evolveSliderValue(r, s+1);
      }
    }
  }

  clearAllSliderValueLabels();

  backDoor = false;
}
