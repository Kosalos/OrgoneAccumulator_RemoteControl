void reset()
{
  backDoor = true;

  for (int r=0; r<NUM_ROW; ++r) {
    seq.row[r].noteSlider.setValue(0);
    seq.row[r].assignCB.deactivateAll();
    seq.row[r].matrixCB.deactivateAll();

    seq.row[r].note = 0;
    for (int i=0; i<NUM_CV; ++i)
      seq.row[r].assign[i] = 0;
    for (int i=0; i<NUM_PAD; ++i)
      seq.row[r].matrix[i] = 0;
  }

  determineCvEntries(); // so defaults are used
  backDoor = false;
}

// ==================================================================

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

void settings()
{
  size(WINDOWXS, WINDOWYS);
}

void setup() 
{
  surface.setTitle("Orgone Sequence");
  controlP5 = new ControlP5(this);
  seq = new Sequence();
  fnt = createFont("Arial", 12, true);
  fnt2 = createFont("Arial", 11, true);

  for (int i=0; i<NUM_PAD; ++i)
    cvEntry[i] = new Dataset();

  selectSerialPort();
  backDoor = true;

  int yCoord = 22;

  for (int r=0; r<NUM_ROW; ++r) {

    // CV input note sliders -------------------
    seq.row[r] = new SequenceRow();
    seq.row[r].noteSlider = controlP5.addSlider(unique(), 0, 8191, 0, 10, yCoord, 150, 15);
    seq.row[r].noteSlider.getCaptionLabel().setFont(fnt2);
    seq.row[r].noteSlider.setColorValueLabel(color(255));

    // CV assignment buttons --------------------
    seq.row[r].assignCB = controlP5.addCheckBox(unique());
    seq.row[r].assignCB.setPosition(ASSIGNX, yCoord);
    seq.row[r].assignCB.setColorActive(color(200, 200, 10));
    seq.row[r].assignCB.setSize(15, 15);
    seq.row[r].assignCB.setSpacingColumn(5);
    seq.row[r].assignCB.setItemsPerRow(NUM_PAD);
    for (int c=0; c<NUM_CV; ++c) 
      seq.row[r].assignCB.addItem(unique(), 0);

    // sequencer matrix ----------------------
    seq.row[r].matrixCB = controlP5.addCheckBox(unique());
    seq.row[r].matrixCB.setPosition(SEQX, yCoord);
    seq.row[r].matrixCB.setColorActive(color(10, 230, 10));
    seq.row[r].matrixCB.setSize(15, 15);
    seq.row[r].matrixCB.setSpacingColumn(5);
    seq.row[r].matrixCB.setItemsPerRow(NUM_PAD);
    for (int c=0; c<NUM_PAD; ++c) 
      seq.row[r].matrixCB.addItem(unique(), 0);

    yCoord+=18;
    if (r>0 && (r % 5)==4)
      yCoord += 8;
  }

  // randomize plus/minus buttons below assignment columns ---
  for (int i=0; i<NUM_CV; ++i) {
    buttonX = ASSIGNX + i*20;
    buttonY = RNDY + 5;

    controlP5.addButton(unique())
      .setPosition(buttonX, buttonY)
      .setSize(15, 10)
      .setValue(0)
      .setId(ID_RNDPLUS+i);

    controlP5.addButton(unique())
      .setPosition(buttonX, buttonY + 15)
      .setSize(15, 10)
      .setValue(0)
      .setId(ID_RNDMINUS+i);
  }

  // randomize panel buttons ---------------
  buttonX = 20;
  buttonY = RNDY + 50;
  button("CV (C)", 50, ID_RND_CV);
  buttonX += 50;
  button("Matrix Plus (R)", 90, ID_RNDPADPLUS);
  button("matrix Minus (T)", 90, ID_RNDPADMINUS);
  buttonX += 40;
  button("ALL (A)", 50, ID_RND_ALL);

  // timing sliders ---------------------
  for (int i=0; i<NUM_PAD; ++i) {
    timing[i] = controlP5.addSlider(unique(), 0, 5, 0, 10, yCoord, 15, 50);
    timing[i].setPosition(SEQX + i * 20, RNDY + 5);
    timing[i].setNumberOfTickMarks(6);
    timing[i].showTickMarks(false); 
    timing[i].snapToTickMarks(true); 
    timing[i].setValue(5);
    timing[i].setValueLabel("");
    colorizeTimingSlider(i);
  }

  // timing buttons ----------------------
  final String[] timingName = { "Whole", "1/2", "1/4", "1/8", "1/16", "1/32" };
  buttonX = TIMINGX + 5;
  buttonY = TIMINGY + 60;
  for (int i=0; i<NUM_TIMING; ++i) {   
    controlP5.addButton(timingName[i])
      .setPosition(buttonX, buttonY)
      .setSize(60, 15)
      .setValue(5)
      .setId(ID_TIMING+i)
      .setColorBackground(tColors[5-i])
      .setColorLabel(color(0));
    buttonX += 70;
  }

  // speed control slider ------------------
  speed = controlP5.addSlider(speedLegend, SPEED_MAX, SPEED_MIN, SPEED_MIN, TIMINGX+475, TIMINGY + 60, 80, 15);
  speed.getCaptionLabel().setFont(fnt);
  speed.getValueLabel().setFont(fnt); 
  speed.setValue(20);
  speed.setColorLabel(color(255));

  // start/stop button  ----------
  buttonX = 10;
  buttonY = BUTTON_ROW;
  button(startStopLegend, 90, ID_STARTSTOP);

  //------------------------------
  int xxx = WINDOWXS-90;
  buttonX = xxx;
  buttonY = DEFAULT_PANEL_Y;
  button("Reset   (S)", 80, ID_RESET);
  buttonX = xxx;
  buttonY += 25;
  button(evolveLegend, 80, ID_EVOLVE);
  buttonX = xxx;
  buttonY += 30;
  button("Save Sequence", 80, ID_SAVESEQ);
  buttonX = xxx;
  buttonY += 25;
  button("Load Sequence", 80, ID_LOADSEQ);
  buttonX = xxx;
  buttonY = WINDOWYS-25;
  button("Help (H)", 80, ID_HELP);

  // glissando ---------------------
  int i = 0;
  int xp = GLISS_PANEL_X + 35;
  int yp = GLISS_PANEL_Y + 32;
  int xs = DEFAULT_BAR_XS-30;

  for (; i< 6; ++i) { 
    setupGlissCheckBoxAndSlider(i, xp, yp);
    yp += 16;
  }

  xp += xs + 50;
  yp = GLISS_PANEL_Y + 32;

  for (; i< NUM_CV; ++i) { 
    setupGlissCheckBoxAndSlider(i, xp, yp);
    yp += 16;
  }

  buttonX = GLISS_PANEL_X + 209;
  buttonY = GLISS_PANEL_Y + 5;
  button(glissandoWrapLegend, 75, ID_GLISSFLAG);

  numPads = controlP5.addSlider(numPadsLegend, MIN_PAD, NUM_PAD, NUM_PAD, 190, BUTTON_ROW, 80, 18);
  numPads.getCaptionLabel().setFont(fnt);
  numPads.getValueLabel().setFont(fnt); 
  numPads.setColorLabel(color(255));
  numPads.setNumberOfTickMarks(NUM_PAD-2);
  numPads.showTickMarks(false); 
  numPads.snapToTickMarks(true); 
  numPads.setValueLabel("32"); 

  // default sliders --------------------------------------
  i = 0;
  xp = DEFAULT_PANEL_X + 35;
  yp = DEFAULT_PANEL_Y + 32;

  for (; i< 6; ++i) { 
    defaults[i] = controlP5.addSlider(unique(), 0, 8191, 0, xp, yp, DEFAULT_BAR_XS, 12);
    defaults[i].setColorValueLabel(color(255));
    yp += 16;
  }

  xp += DEFAULT_BAR_XS + 40;
  yp = DEFAULT_PANEL_Y + 32;
  xs = DEFAULT_BAR_XS;
  int vMax = 8191;

  for (; i< NUM_CV; ++i) { 
    if (i >= 9) {
      xs = 30;
      vMax = 1;
    }

    defaults[i] = controlP5.addSlider(unique(), 0, vMax, 0, xp, yp, xs, 12);
    defaults[i].setColorValueLabel(color(255));

    if (i >= 9) {
      defaults[i].setNumberOfTickMarks(2);
      defaults[i].showTickMarks(false); 
      defaults[i].snapToTickMarks(true);
      defaults[i].setColorForeground(color(0, 220, 0));
      defaults[i].setColorActive(color(0, 220, 0));
      defaults[i].setValueLabel("");
    }

    yp += 16;
  }

  // ---------------------------------------------------------
  changeSpeed(0); // so widget draws current value
  backDoor = false;


  for (i=0; i<4; ++i)
    randomizeAll();
  loadFromFile(autoSaveFilename);
  determineCvEntries();

  for (int r=0; r<NUM_ROW; ++r) {
    seq.row[r].noteSlider.setValueLabel(nf(seq.row[r].note));
  }

  for (i=0; i<NUM_CV; ++i) {
    defaults[i].setValueLabel(i < 9 ? nf(defaults[i].getValue()) : "");
  }
}

// ==================================================================

void setupGlissCheckBoxAndSlider(int i, int xp, int yp) 
{
  glissC[i] = controlP5.addCheckBox(unique());    
  glissC[i].setPosition(xp, yp);  
  glissC[i].setSize(15, 12);
  glissC[i].addItem(unique(), 0);

  glissS[i] = controlP5.addSlider(unique(), GLISS_MAX_TICK, GLISS_MIN_TICK, GLISS_MAX_TICK/2, xp+20, yp, DEFAULT_BAR_XS-30, 12);
  glissS[i].setColorValueLabel(color(255));
  glissS[i].setValueLabel("");
}

// ==================================================================

final color[] tColors = { 
  color(150), 
  color(120, 0, 180), 
  color(0, 180, 255), 
  color(0, 160, 130), 
  color(160, 130, 0), 
  color(255, 255, 0), }; // whole

void colorizeTimingSlider(int index) {
  int v = (int)timing[index].getValue();
  timing[index].setColorForeground(tColors[v]);
  timing[index].setColorActive(tColors[v]);
}

// ==================================================================

static String toAscii (
  String unicode)   
{
  String output = "";
  char[] charArray = unicode.toCharArray();

  for (int i = 0; i < charArray.length; i++) {
    char a = charArray[i];
    if (a=='-' || (a >='0' && a<='9')) {
      output += a;
    }
  }      

  return output;
}

// ==================================================================

String seqHeader = "OrgoneSequence";
final int NUM_FILE_LINES = NUM_ROW + 3; // +2 = header, glissando, defaults

void loadFromFile(String filename)
{
  String[] data = loadStrings(filename);
  String trim, t1, t2;
  String[] s2;
  int index = 0;
  int lineNumber = 1;

  reset();

  if (data == null) return;
  //println("lf data len = " + data.length);
  if (data.length != NUM_FILE_LINES) 
    return;

  if (!data[0].equals(seqHeader)) 
    return;

  // glissando
  trim = data[lineNumber].trim();
  s2 = split(trim, ',');
  for (int i=0; i<NUM_CV; ++i) {
    t1 = s2[index++].trim();
    t2 = toAscii(t1);
    glissandoFlag[i] = (boolean)(int(t2.trim()) > 0);
  }
  lineNumber++;

  // defaults line
  trim = data[lineNumber].trim();
  s2 = split(trim, ',');
  index = 0;
  for (int i=0; i<NUM_CV; ++i) {
    t1 = s2[index++].trim();
    t2 = toAscii(t1);
    defaults[i].setValue(int(t2.trim()));
  }
  lineNumber++;

  // matrix
  for (int r=0; r<NUM_ROW; ++r) {
    trim = data[lineNumber].trim();
    s2 = split(trim, ',');

    index = 0;   
    t1 = s2[index++].trim();
    t2 = toAscii(t1);
    seq.row[r].note = (int)int(t2.trim());
    seq.row[r].noteSlider.setValueLabel(nf(seq.row[r].note));      

    for (int i=0; i<NUM_CV; ++i) {
      t1 = s2[index++].trim();
      t2 = toAscii(t1);
      seq.row[r].assign[i] = (byte)int(t2.trim());
    }

    for (int i=0; i<NUM_PAD; ++i) {
      t1 = s2[index++].trim();
      t2 = toAscii(t1);
      seq.row[r].matrix[i] = (byte)int(t2.trim());
    }

    lineNumber++;
  }

  //debug();

  // update widgets to match -----------------------------
  backDoor = true;

  for (int i=0; i<NUM_CV; ++i) {
    glissC[i].deactivateAll();
    if (glissandoFlag[i]) 
      glissC[i].activate(0);
  }

  for (int r=0; r<NUM_ROW; ++r) {
    seq.row[r].noteSlider.setValue(seq.row[r].note);

    seq.row[r].assignCB.deactivateAll();
    for (int i=0; i<NUM_CV; ++i) {
      if (seq.row[r].assign[i] != 0) {
        seq.row[r].assignCB.activate(i);
      }
    }

    seq.row[r].matrixCB.deactivateAll();
    for (int i=0; i<NUM_PAD; ++i) {
      if (seq.row[r].matrix[i] != 0)
        seq.row[r].matrixCB.activate(i);
    }
  }

  determineCvEntries();
  backDoor = false;
}

// ==================================================================

void saveToFile(String filename)
{
  String[] contents = new String[NUM_FILE_LINES]; 

  int index = 0;
  contents[index++] = seqHeader;

  // glissando line
  contents[index] = "";
  for (int i=0; i<NUM_CV; ++i) {
    int v = glissandoFlag[i] ? 1 : 0;
    contents[index] = contents[index] +  nf(v, 1) + ",";
  }
  ++index;

  // defaults line
  contents[index] = "";
  for (int i=0; i<NUM_CV; ++i) {
    int v = (int)defaults[i].getValue();
    contents[index] = contents[index] +  nf(v, 1) + ",";
  }
  ++index;

  // matrix lines
  for (int r=0; r<NUM_ROW; ++r) {
    contents[index] = nf(seq.row[r].note, 1) + ",  ";

    for (int i=0; i<NUM_CV; ++i) 
      contents[index] = contents[index] +  nf(seq.row[r].assign[i], 1) + ",";
    contents[index] = contents[index] + "  ";
    for (int i=0; i<NUM_PAD; ++i) 
      contents[index] = contents[index] +  nf(seq.row[r].matrix[i], 1) + ",";

    ++index;
  }

  saveStrings(filename, contents);
}

// ==================================================================

void sequenceSelected(File selection)  // selected file info from popup dialog 
{
  if (selection != null)
    loadFromFile(selection.getAbsolutePath());
}

void loadSequence()
{
  selectInput("Select Sequence file", "sequenceSelected");
}

// ==================================================================

void saveSequence()
{
  String fName = showInputDialog("Enter name for this Sequence\n(.seq extension will be added)");
  if (fName == null) return; 
  if ("".equals(fName)) return;
  String wName = fName + ".seq";

  saveToFile(wName);
}

// ==================================================================

void showHelp() 
{
  String t = 
    "20 Channel, 32 step sequencer for the OA  (Orgone Accumulator)\n\n" +
    "Each channel has 3 sections:\n" +
    "    1. CV (control voltage) setting\n" +
    "    2. Assignments, to set which OA parameter(s) are affected\n" +
    "    3. Sequencer, to set when CV updates are made.\n\n" +
    "    For CVs: click anywhere on the slider bar to set the CV from 0..8191\n" +
    "    For Assignments and Sequencer: click on pads to toggle their status.\n\n" +
    "    Note: when multiple Sequencer pads have the same assignment,\n" +
    "          the highest row's CV is used.\n\n" +
    "Randomize:\n" +
    "    Buttons to select which sections of the sequencer are altered.\n\n" +
    "Timing:\n" +
    "    The panel below the matrix sets the relative duration for each column.\n" +
    "    Here you also set the sequencer speed.\n\n" +
    "Default:\n" +
    "    Here you set the default value for each CV setting.\n" +
    "    This value will be used until a sequencer entry sets a new setting.\n\n" +
    "Glissando: (G, and clicks)\n" +
    "    Set whether CV changes are abrupt or smooth.\n\n" +
    "Evolve:  (E)\n" +
    "    Whether random changes are made to the settings during play.\n\n" +
    "Speed:  (1,2 and clicks)\n" +
    "    Set the sequencer step rate.\n\n" + 
    "#Pads:  (3,4 and clicks)\n" +
    "    Set how many Sequencer steps are active (3 .. 32)\n\n" + 
    "Start/Stop: (Space)\n" +
    "    Note:  the OA's  PWM output is a Trigger that fires on each step.";

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

  for (int i=0; i<11; i+=2) {

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
