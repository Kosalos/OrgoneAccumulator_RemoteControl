void settings()
{
  size(WINDOWXS, WINDOWYS);
}

void setup() 
{
  controlP5 = new ControlP5(this);
  cp = new InCVPacket(); 
  font14 = createFont("Arial", 14, true);

  surface.setTitle("Orgone DrumBeat");

  selectSerialPort();

  // band sliders -------------------------------------------------
  int xp = GRP_X + 25;
  int yp = GRP_Y + 10;
  int yhop = 18;

  for (int i=0; i<NUM_BAND; ++i) {
    band[i] = new Band();

    // numeric range display
    band[i].cvRange = controlP5.addTextfield(unique());
    band[i].cvRange.setPosition(xp, yp-2);
    band[i].cvRange.setSize(92, yhop+4);
    band[i].cvRange.setColorForeground(100);
    band[i].cvRange.setColorBackground(color(80, 80, 80));
    band[i].cvRange.setFont(font14);

    // CV setpoint slider
    band[i].slider[CV_ID] = controlP5.addSlider(unique(), CV_MIN, CV_MAX, CV_MIN, xp+100, yp, 120, yhop);
    band[i].slider[CV_ID].setId(i * BASE_ID_PER_ROW + CV_ID);
    band[i].slider[CV_ID].setValueLabel(""); 
    band[i].slider[CV_ID].setSliderMode(Slider.FLEXIBLE);
    band[i].slider[CV_ID].setHandleSize(2);
    band[i].slider[CV_ID].setColorForeground(color(255));

    yp += yhop+5;
  }

  for (int i=0; i<NUM_BAND; ++i) 
    setupBandSlidersforRow(i);

  // evolve checkboxes
  evolve = controlP5.addCheckBox(unique());
  evolve.setId(ID_EVOLVE);
  evolve.setPosition(EVOLVE_X+60, EVOLVE_Y+8);
  evolve.setSize(15, 15);
  evolve.setSpacingColumn(BAND_SLIDER_XS-5);
  evolve.setItemsPerRow(NUM_SLIDER);
  for (int c=0; c<NUM_SLIDER-1; ++c) 
    evolve.addItem(unique(), 0);

  buttonX = WINDOWXS - 100;
  buttonY = EVOLVE_Y + 5;
  button(evolveLegend, 80, ID_EVOLVE_MASTER);

  // buttons along window bottom 
  buttonX = 10;
  buttonY = WINDOWYS - 30;
  button("Load Patch (L)", 80, ID_LOAD);  
  button("Save Patch (S)", 80, ID_SAVE);
  buttonX += 100;
  button("Random (R)", 80, ID_RANDOM);
  buttonX = WINDOWXS - 90;
  button("Help (H)", 80, ID_HELP);

  filter = controlP5.addSlider("Filter", 1, 60, 8, 600, buttonY, 80, 18);

  isInitialized = true;
  randomize();
  updateCVRangeTextAllRows();
}

// ==========================================================

int xp, yp;

void setupBandSliders(int index, int baseID) 
{
  band[index].slider[baseID] = controlP5.addSlider(unique(), CV_MIN, CV_MAX, 0, xp, yp, BAND_SLIDER_XS, 15);
  band[index].slider[baseID].setId(index * BASE_ID_PER_ROW + baseID);
  band[index].slider[baseID].setValueLabel(""); 
  xp += BAND_X_HOP;
}

void setupBandSlidersforRow(int index)
{
  xp = 35;
  yp = BAND_Y+8 + index * (BAND_YS + BAND_YHOP);

  setupBandSliders(index, OFFSET_ID);
  setupBandSliders(index, WAVE1_ID);
  setupBandSliders(index, WAVE2_ID);
  setupBandSliders(index, WAVE3_ID);
  setupBandSliders(index, POSITION_ID);
  setupBandSliders(index, EFFECT_ID);
  setupBandSliders(index, INDEX_ID);
  setupBandSliders(index, FREQ_ID);
  setupBandSliders(index, MOD_ID);

  band[index].cb = controlP5.addCheckBox(unique());
  band[index].cb.setId(index * BASE_ID_PER_ROW + CBOX_ID);
  band[index].cb.setPosition(xp, yp);
  band[index].cb.setSize(15, 15);
  band[index].cb.setSpacingColumn(20);
  band[index].cb.setItemsPerRow(3);
  for (int c=0; c<3; ++c) 
    band[index].cb.addItem(unique(), 0);
}

// ==========================================================

void updateCVRangeText(int index)
{
  int top = CV_MAX;
  int bottom = (int)band[index].slider[CV_ID].getValue();
  if (index > 0) 
    top = (int)band[index-1].slider[CV_ID].getValue();

  if (top < CV_MAX) --top;

  band[index].rangeLow = bottom;
  band[index].rangeHigh = top;
}

void updateCVRangeTextAllRows()
{
  if (!isInitialized) return;

  for (int i=0; i<NUM_BAND; ++i) {
    updateCVRangeText(i);
  }

  // starting at the bottom, find the first band with range.
  // set it's low end to zero.
  for (int i= NUM_BAND-1; i >= 0; --i) {
    if (band[i].rangeHigh - band[i].rangeLow > 1) {
      band[i].rangeLow = 0;
      break;
    }
  }

  for (int i=0; i<NUM_BAND; ++i) {
    String s = "";
    if (band[i].rangeHigh > band[i].rangeLow) 
      s = String.format("  %04d - %04d", band[i].rangeLow, band[i].rangeHigh);
    band[i].cvRange.setText(s);
    band[i].slider[CV_ID].setValueLabel("");
  }
}

// ==================================================================

void ensureBandCVsAreInOrder()
{
  int value = (int)band[0].slider[CV_ID].getValue();

  for (int row=1; row < NUM_BAND; ++row) {
    int v = (int)band[row].slider[CV_ID].getValue();

    if (v > value) { 
      v = value-1;
      if (v < 0) v = 0;

      band[row].slider[CV_ID].setValue(v);
    }

    value = v-1;
    if (value < 0) value = 0;
  }

  updateCVRangeTextAllRows();
}

// ==================================================================

void clearAllSliderValueLabels()
{
  for (int row=0; row<NUM_BAND; ++row) {
    for (int i=0; i<NUM_SLIDER; ++i) {
      band[row].slider[i].setValueLabel("");
    }
  }
}

// ==================================================================
// create Button, bump xCoord

int buttonX, buttonY;

void button(
  String name, // button name 
  int width, // button width
  int id)      // button ID
{
  controlP5.addButton(name)
    .setPosition(buttonX, buttonY)
    .setSize(width, 20)
    .setValue(0)
    .setId(id);

  buttonX += width + 5;
}

// ==================================================================

void showHelp() 
{
  String t = 
    "Drum Beat Sound Controller for the OA  (Orgone Accumulator)\n\n" +
    "Eight Bands are provided, each with a bank of controls for the OA parameters.\n\n" +
    "Which Band is heard is controlled by the CV input voltage of the OA.\n" +
    "The CV voltage ranges from 0 .. 8191, and each band is alloted a section of that range.\n\n" +
    "You specify the range via the blue colored sliders at the upper left.\n" +
    "You can also left mouse button click/drag on the graphic rendition on the upper right.\n\n" +
    "Load/Save Patch (L,S):\n" +
    "    Settings are stored to file in the same folder as the app.\n\n" +
    "Random (R):\n" +
    "    Randomize all settings.\n\n" +
    "Evolve:  (E)\n" +
    "    Whether random changes are made to the settings during play.\n" +
    "    Master On/Off switch, and 'enable' switches for each slider.\n\n" +
    "Filter:\n" +
    "    Controls smoothing of CV voltage received from OA.\n\n" +
    "Note:  Press '1' through '8' to copy that band's settings to the other rows.\n\n" +
    "Note:  Right mouse button click/drag on the graphic panel to define a CV range.\n" +
    "       All the bands will adjust their CV setting to equally share that region.";

  showMessageDialog(null, t, "Help", PLAIN_MESSAGE);
}

// ========================================================================
// controlP5 requires a unique name for every widget.  
// Generate a unique, invisible widget name.

int unValue = 0;
String[] unStr = { "\001", "\002", "\003", "\004" };

String unique() 
{
  String s = "";
  int index, mask = 1;

  for (int i=0; i<8; i+=2) {

    index = 0;
    for (int bit=1; bit<=2; ++bit) {
      if ((unValue & mask) > 0) index += bit;
      mask *= 2;
    }

    s += unStr[index];
  }

  ++unValue;
  return s;
}
