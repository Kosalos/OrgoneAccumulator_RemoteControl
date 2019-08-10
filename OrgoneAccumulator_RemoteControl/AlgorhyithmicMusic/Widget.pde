final int NUM_ENTRY = 160;
final int K_SLIDER = 1;
final int K_CHECK = 2;
final int K_BUTTON = 3;
final int K_TEXT = 4;
final int K_TOGGLE = 5;
final int K_FRAME = 6;

final color cFrame = color(90, 90, 90);
final color cNormal = color(100, 100, 100);
final color cHighlight = color(0, 120, 250);
final color cFrameHighlight = color(50, 120, 50);

// =============================================================

class WidgetEntry {
  int id, kind;
  int x, y, xs, ys, xhop;
  int min, max, value;
  int justify; // 0 = left, 1 = center, 2 = right
  String str; 
  boolean highlight;
  boolean showValue = false;
  boolean[] cb;

  WidgetEntry() {
    str = "";
    highlight = false;
    justify = 1;
  }

  void idKind(int pid, int pkind, int pcbCount) {
    id = pid;
    kind = pkind;

    if (kind == K_CHECK) {
      cb = new boolean[pcbCount];
      for (int i=0; i<pcbCount; ++i)
        cb[i] = false;
    }
  }

  void posSize(int px, int py, int pxs, int pys, int pxhop) {
    x = px;
    y = py;
    xs = pxs;
    ys = pys;
    xhop = pxhop;
  }

  void range(int pmin, int pmax) {
    min = pmin;
    max = pmax;
    value = (min + max)/2;
  }

  void justifyStr() {
    if (str.length() > 0) {
      fill(255);
      switch(justify) {
      case 0 : 
        xp = x+5; 
        break;
      default :
        xp = x+xs/2 - str.length()*4;
        break;
      }

      text(str, xp, y+ys- 5);
    }
  }

  void draw(boolean hasFocus) {
    int xp;

    switch(kind) {
    case K_CHECK :
      xp = x;
      for (int i=0; i<cb.length; ++i) {
        fill(cb[i] ? cHighlight : cNormal);
        bevelledBorder(xp, y, xs, ys, false);
        xp += xs + xhop;
      }
      break;

    case K_SLIDER :    
      fill(cNormal);
      bevelledBorder(x, y, xs, ys, hasFocus);

      xp = (xs-2) * (value - min) / (max - min);
      if (hasFocus) {
        color fc = color(200, 128, 0);
        fill(fc);
        stroke(fc);
      } else {
        fill(cHighlight);
        stroke(cHighlight);
      }
      rect(x+1, y+1, xp, ys-2);

      if (str.length() > 0) {
        fill(255);
        text(str, x+xs+10, y+13);
      }

      if (showValue) { // value text
        fill(255);
        text(nf(value, 1), x+10, y+12);
      }
      break;

    case K_BUTTON :
    case K_TEXT :
      fill(highlight ? cFrameHighlight : cNormal);
      bevelledBorder(x, y, xs, ys, false);
      justifyStr();
      break;

    case K_TOGGLE :
      fill(highlight ? cHighlight : cNormal);
      bevelledBorder(x, y, xs, ys, false);
      justifyStr();
      break;

    case K_FRAME :    
      fill(highlight ? cFrameHighlight : cFrame);
      bevelledBorder(x, y, xs, ys, false);
    }
  }

  boolean mouseInside() {
    if (mouseX < x || mouseX > x + xs) return false;
    if (mouseY < y || mouseY > y + ys) return false;
    return true;
  }

  boolean mousePressed() {
    int xp, old;

    switch(kind) {
    case K_CHECK :
      if (mouseY < y || mouseY > y + ys) return false;
      xp = x;
      for (int i=0; i<cb.length; ++i) {
        if (mouseX >= xp && mouseX < xp + xs) {
          cb[i] = !cb[i];
          return true;
        }

        xp += xs + xhop;
      }
      return false;

    case K_SLIDER :    
      if (!mouseInside()) return false;
      xp = mouseX - x;
      old = value;
      value = min + (max - min) * xp / xs;
      return (old != value);

    case K_BUTTON :    
      if (mouseInside()) {
        buttonPressed(id);
        return true;
      }
      return false;

    case K_TOGGLE :    
      if (mouseInside()) {
        highlight = !highlight;
        return true;
      }
      return false;
    }

    return false;
  }

  boolean mouseDragged() {
    if (kind == K_SLIDER)
      return mousePressed();

    return false;
  }
}

// =============================================================
// =============================================================

class Widget {
  WidgetEntry[] w;
  int[] rangeLow = new int[NUM_BAND];
  int[] rangeHigh = new int[NUM_BAND];
  int count;
  int focus;

  Widget() {
    count = 0;
    w = new WidgetEntry[NUM_ENTRY];
    for (int i=0; i<NUM_ENTRY; ++i) 
      w[i] = new WidgetEntry();
  }

  void commonInit(int id, int kind, int x, int y, int xs, int ys, String legend) {
    w[count].idKind(id, kind, 0);
    w[count].posSize(x, y, xs, ys, 0);
    w[count].str = legend;
  }

  void addSlider(int id, int x, int y, int xs, int ys, int min, int max, String legend) {
    commonInit(id, K_SLIDER, x, y, xs, ys, legend);
    w[count].range(min, max);
    ++count;
  }

  void addCheck(int id, int x, int y, int xs, int ys, int xhop, int cbCount) {
    w[count].idKind(id, K_CHECK, cbCount);
    w[count].posSize(x, y, xs, ys, xhop);
    ++count;
  }

  void addButton(int id, int x, int y, int xs, int ys, String legend) {
    commonInit(id, K_BUTTON, x, y, xs, ys, legend);
    w[count].justify = 0;
    ++count;
  }

  void addToggle(int id, int x, int y, int xs, int ys, String legend) {
    commonInit(id, K_TOGGLE, x, y, xs, ys, legend);
    w[count].justify = 0;
    ++count;
  }

  void addText(int id, int x, int y, int xs, int ys, String legend) {
    commonInit(id, K_TEXT, x, y, xs, ys, legend);
    ++count;
  }

  void addFrame(int id, int x, int y, int xs, int ys) {
    commonInit(id, K_FRAME, x, y, xs, ys, "");
    ++count;
  }

  // =============================================================

  void draw() {
    // highlight active frame
    for (int i=0; i<NUM_BAND; ++i) {
      boolean hh = i == activeBandIndex;
      setHighlight(i * BASE_ID_PER_ROW + FRAME_ID, hh);
      setHighlight(CVRANGE_ID+i, hh);
    }    

    for (int i=0; i<count; ++i) 
      w[i].draw(i == focus);
  }

  // =============================================================

  int getIndex(int id) {
    for (int i=0; i<count; ++i)
      if (w[i].id == id) return i;

    println("\nWidget Error. No such ID: " + id + "\n");
    new Error().printStackTrace();
    System.exit(-1);

    return -1;
  }

  int getValue(int id) {
    return w[getIndex(id)].value;
  }

  void setValue(int id, int v) {
    w[getIndex(id)].value = v;
  }

  boolean getCheck(int id, int cIndex) {
    int index = getIndex(id);
    if (cIndex < 0 || cIndex >= w[index].cb.length) {
      println("\nWidget Error. No such checkBox index ID: " + id + " cIndex: " + cIndex + "\n");
      System.exit(-1);
      return false;
    }

    return w[index].cb[cIndex];
  }

  void setCheck(int id, int cIndex, boolean onoff) {
    int index = getIndex(id);

    if (cIndex < 0 || cIndex >= w[index].cb.length) {
      println("\nWidget Error. No such checkBox index.   ID: " + id + " cIndex: " + cIndex + "\n");
      System.exit(-1);
      return;
    }

    w[index].cb[cIndex] = onoff;
  }

  boolean getToggle(int id) {
    int index = getIndex(id);
    return w[index].highlight;
  }

  void setToggle(int id, boolean onoff) {
    int index = getIndex(id);
    w[index].highlight = onoff;
  }

  void flipToggle(int id) {
    int index = getIndex(id);
    w[index].highlight = !w[index].highlight;
  }

  void setLegend(int id, String s) {
    w[getIndex(id)].str = s;
  }

  void setHighlight(int id, boolean onoff) {
    w[getIndex(id)].highlight = onoff;
  }

  // =============================================================

  void checkRangeSlider(int bossIndex) {
    int low = getValue(RANGELOW_ID);
    int high = getValue(RANGEHIGH_ID); 

    if (bossIndex == 0) {
      if (high < low + MIN_RANGE_GAP) 
        high = low + MIN_RANGE_GAP;
    } else {
      if (low > high - MIN_RANGE_GAP) 
        low = high - MIN_RANGE_GAP;
    }

    setValue(RANGELOW_ID, low);
    setValue(RANGEHIGH_ID, high);
  }

  void checkRangeSliders(int index) {
    if (w[index].id == RANGELOW_ID) 
      checkRangeSlider(0);
    if (w[index].id == RANGEHIGH_ID) 
      checkRangeSlider(1);
  }

  // =============================================================
  // rought mouse drag on band sliders affect wgle column
  
  void checkRightMousePressed(int index) {
    if (mouseButton != RIGHT) return;
    
    int id = w[index].id;
    int column = id % 100;
    int row = id / 100;
    if(row >= NUM_BAND) return;
    if(column > MOD_ID) return;
    
    int v = w[index].value;
    for(int i=0;i<NUM_BAND;++i) 
      setValue(i * 100 + column,v);
  }
  
  // =============================================================

  void mousePressed() { 
    for (int i=0; i<count; ++i) 
      if (w[i].mousePressed()) {
        checkRangeSliders(i);
        checkRightMousePressed(i);
        sendChangesIfPaused();
        break;
      }
  }

  void mouseDragged() { 
    for (int i=0; i<count; ++i) 
      if (w[i].mouseDragged()) {
        if (w[i].kind == K_SLIDER) {
          checkRangeSliders(i);
          checkRightMousePressed(i);
          sendChangesIfPaused();
        } else
          break;
      }
  }

  // =============================================================

  void sendChangesIfPaused() {
    if (getToggle(PAUSE_ID))
      requestSendDataset = true;
  }

  // =============================================================

  void initFocus() {
    for (int i=0; i<count; ++i)
      if (w[i].kind == K_SLIDER && w[i].x > 0) {  // Not an offscreen slider
        focus = i;
        break;
      }
  }

  void moveFocus(int amt) {
    for (;; ) {
      focus += amt;
      if (focus < 0) focus = count-1; 
      else
        if (focus >= count) focus = 0;
      if (w[focus].kind == K_SLIDER && w[focus].x > 0) break;
    }
  }

  // =============================================================

  void alterFocusedSlider(int amt) {
    int delta = (w[focus].max - w[focus].min) / 100;
    if (delta < 1) delta = 1;

    w[focus].value = constrain(w[focus].value + amt * delta, w[focus].min, w[focus].max);
    checkRangeSliders(focus);
  }

  // =============================================================

  void cloneBandSettings(int src) {
    for (int dest=0; dest<NUM_BAND; ++dest) {
      if (dest == src) continue;
      int sIndex, dIndex;

      for (int i=1; i<NUM_BAND_VALUE; ++i) {     // skip 0 : don't alter CV slider
        sIndex = src * 100 + i;
        dIndex = dest * 100 + i;

        widget.setValue(dIndex, getValue(sIndex));
      }

      for (int i=0; i<3; ++i) {
        sIndex = src * 100 + CBOX_ID1 + i;
        dIndex = dest * 100 + CBOX_ID1 + i;

        widget.setToggle(dIndex, getToggle(sIndex));
      }
    }
  }

  // =============================================================

  void randomize() {
    int cv = 4000 + (int)random(0, 4100);

    for (int r=0; r<NUM_BAND; ++r) {
      for (int s=0; s<NUM_BAND_VALUE; ++s) {

        // special handling for CV slider
        if (s == CV_ID) {
          setValue(r*100+s, cv);
          cv -= (int)random(50, 1000);
          if (cv < 0) cv = 0;
        } else {
          if (percentChance(30)) 
            setValue(r*100+s, int(random(CV_MIN, CV_MAX)));
        }

        for (int i=0; i<3; ++i) 
          if (percentChance(10)) 
            setToggle(activeBandIndex*100 + CBOX_ID1 + i, percentChance(50));
      }
    }

    ensureBandCVsAreInOrder();
  }

  void randomize2() {
    for (int i=0; i<6; ++i) {
      //int v = getValue(EQUATIONPARAM_ID+i) + (percentChance(50) ? 1 : -1);
      widget.setValue(EQUATIONPARAM_ID+i, (int)random(0, 15)); // constrain(v, 0, 15));
    }
  }

  void initialize() {
    String fname = "currentSettings.session";
    File file = new File(sketchPath(fname));

    if (file.exists())
      performLoad(fname);
    else {
      setValue(SMOOTHING_ID, 0);
      setValue(SPEED_ID, 20);
      setValue(MODULO_ID, 256);
      setValue(RANGELOW_ID, 4000);
      setValue(RANGEHIGH_ID, 7000);
      randomize();
    }

    ensureBandCVsAreInOrder();
    initFocus();
  }

  // =============================================================

  boolean evolveSliderValue(int row, int column) {
    int amount = (int)random(5, 100);
    if (percentChance(50)) amount = -amount;

    int index = row*100 + column;
    int v = getValue(index);
    int nv = int(constrain(v + amount, CV_MIN, CV_MAX));
    setValue(index, nv);

    return v != nv;
  }

  void performEvolve() {
    if (!getToggle(EVOLVEMASTER_ID) || percentChance(50)) return;

    for (int r=0; r<NUM_BAND; ++r) 
      for (int s=0; s<NUM_BAND_VALUE-1; ++s)  
        if (getCheck(EVOLVECHECK_ID, s) && percentChance(10)) 
          if (evolveSliderValue(r, s+1)) {
            //gateStatus = 1;
            requestSendDataset = true;
          }

    ensureBandCVsAreInOrder();
  }

  // =============================================================

  void updateCVRangeText(int index) {
    int top = CV_MAX;
    int bottom = getValue(index*100);
    if (index > 0) 
      top = getValue((index-1)*100);

    if (top < CV_MAX) --top;

    rangeLow[index] = bottom;
    rangeHigh[index] = top;
  }

  void updateCVRangeTextAllRows() {
    for (int i=0; i<NUM_BAND; ++i) 
      updateCVRangeText(i);

    // starting at the bottom, find the first band with range.
    // set it's low end to zero.
    for (int i= NUM_BAND-1; i >= 0; --i) {
      if (rangeHigh[i] - rangeLow[i] > 1) {
        rangeLow[i] = 0;
        break;
      }
    }
  }

  // =============================================================

  void ensureBandCVsAreInOrder() {
    int currentValue = getValue(0);

    for (int row=1; row < NUM_BAND; ++row) {
      int rowValue = getValue(row*100);

      if (rowValue > currentValue) 
        setValue(row*100, currentValue);

      currentValue = rowValue;
    }

    updateCVRangeTextAllRows();

    for (int i=0; i<NUM_BAND; ++i) {
      String s = "";
      if (rangeHigh[i] > rangeLow[i]) 
        s = String.format("%d  %04d - %04d", i+1, rangeLow[i], rangeHigh[i]);
      w[getIndex(CVRANGE_ID+i)].str = s;
    }
  }

  // =============================================================
  // does specified band control a range of input CV values?

  boolean isActiveband(int row) {
    int top = CV_MAX;
    int bottom = getValue(row*100);
    if (row > 0) 
      top = getValue((row-1)*100);

    if (top > 0) --top; 

    return top-bottom > 1;
  }

  // =============================================================
  // Load file

  final int LINE_COUNT = 160; 
  private String[] fieldString;
  private int column;

  void errorMsg2() { 
    javax.swing.JOptionPane.showMessageDialog(frame, "Must select a previously saved Session");
  }

  String toAscii (String unicode) {
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

  int readNextField() {
    String t1 = fieldString[column++].trim(); 
    String t2 = toAscii(t1); 
    return int(t2.trim());
  }

  boolean parseFieldString() {
    column = 0;
    int id = readNextField();
    if (id < 0) return false; // EOF marker

    int index = getIndex(id);

    switch(w[index].kind) {
    case K_SLIDER :
      w[index].value = readNextField();
      break;
    case K_BUTTON :
    case K_TOGGLE :
      w[index].highlight = readNextField() > 0;
      break;
    case K_CHECK :
      for (int i=0; i<w[index].cb.length; ++i) 
        w[index].cb[i] = readNextField() > 0;
      break;
    }

    return true;
  }

  void performLoad(String filename) {
    String[] fileData = loadStrings(filename);

    if (fileData.length != LINE_COUNT) {
      errorMsg2();
      return;
    } 

    for (int i=0; i<fileData.length; ++i) {
      String trim = fileData[i].trim();
      fieldString = split(trim, ',');

      if (!parseFieldString())
        break;
    }
  }

  void loadSession() {
    selectInput("Select Session file", "sessionSelected");
  }

  // =============================================================
  // Save file

  String createFileSaveString(int index) {
    String s = "";

    switch(w[index].kind) {
    case K_SLIDER :
      s = nf(w[index].id, 1) + "," + nf(w[index].value, 1);
      break;
    case K_BUTTON :
    case K_TOGGLE :
      s = nf(w[index].id, 1) + (w[index].highlight ? ",1" : ",0");
      break;
    case K_CHECK :
      s = nf(w[index].id, 1);
      for (int i=0; i<w[index].cb.length; ++i) 
        s += (w[index].cb[i] ? ",1" : ",0");
      break;
    }

    return s;
  }

  void performSave(String filename) {
    String[] outputFileData = new String[LINE_COUNT];
    int fileLineIndex;
    String s;

    for (int i=0; i<LINE_COUNT; ++i)
      outputFileData[i] = "";

    fileLineIndex = 0;

    for (int i=0; i<count; ++i) {
      s = createFileSaveString(i);
      if (s.length() > 0) 
        outputFileData[fileLineIndex++] = s;
    }

    outputFileData[fileLineIndex++] = "-1";  // EOF marker

    saveStrings(filename, outputFileData);
  }

  void saveSession() {
    String fName = showInputDialog("Enter name for this Session\n(.session extension will be added)");
    if (fName == null) return; 
    if ("".equals(fName)) return;

    performSave(fName + ".session");
  }

  // called when app closes
  void saveCurrentSettings() {
    performSave("currentSettings.session");
  }
} // Class widget

// =============================================================

void sessionSelected(File selection) { // selected file info from popup dialog 
  if (selection != null) {
    widget.performLoad(selection.getAbsolutePath());
    widget.updateCVRangeTextAllRows();
  }
}

Boolean percentChance(int percent) {
  return (int)random(0, 100) < percent;
}

// =============================================================

final color border1 = color(60, 60, 60);
final color border2 = color(200, 200, 200);
final color borderf = color(200, 200, 0);

void bevelledBorder(int x, int y, int xs, int ys, boolean hasFocus) {
  rect(x, y, xs, ys);

  stroke(hasFocus ? borderf : border1);
  line(x, y, x+xs, y);
  line(x, y, x, y+ys);

  stroke(hasFocus ? borderf : border2);
  line(x+xs, y+ys, x+xs, y);
  line(x+xs, y+ys, x, y+ys);
}
