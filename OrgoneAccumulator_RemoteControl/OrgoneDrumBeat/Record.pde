final String sessionHeader = "Orgone DrumBeat";
final int LINE_COUNT = NUM_BAND + 1;

void errorMsg2() 
{
  javax.swing.JOptionPane.showMessageDialog(frame, "Must select a previously saved Session");
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

void loadSessionFile(String filename)  
{
  String[] data = loadStrings(filename);

  if (data.length != LINE_COUNT) {
    errorMsg2();
    return;
  } 

  if (!data[0].equals(sessionHeader)) {
    errorMsg2();
    return;
  } 

  String t1, t2;

  backDoor = true;

  for (int row=0; row<NUM_BAND; ++row) {
    String trim = data[row+1].trim();
    String[] s2 = split(trim, ',');

    // sliders
    for (int i=0; i<NUM_SLIDER; ++i) {
      t1 = s2[i].trim();
      t2 = toAscii(t1);

      band[row].slider[i].setValue(float(t2.trim()));
    }

    // 3 checkboxes
    band[row].cb.deactivateAll();

    for (int i=0; i<3; ++i) {
      t1 = s2[NUM_SLIDER+i].trim();
      t2 = toAscii(t1);

      if (int(t2.trim()) > 0) band[row].cb.activate(i);
    }
  }
  
  backDoor = false;
}

void sessionSelected(File selection)  // selected file info from popup dialog 
{
  if (selection != null) {
    loadSessionFile(selection.getAbsolutePath());
    updateCVRangeTextAllRows();
    clearAllSliderValueLabels();
  }
}

void loadSession()
{
  selectInput("Select Session file", "sessionSelected");
}

// ==================================================================

void saveSession()
{
  String fName = showInputDialog("Enter name for this Session\n(.session extension will be added)");
  if (fName == null) return; 
  if ("".equals(fName)) return;
  String wName = fName + ".session";

  String[] contents = new String[LINE_COUNT];

  int v, index = 0;
  contents[index++] = sessionHeader;

  for (int row=0; row<NUM_BAND; ++row) {

    contents[index] = "";

    // sliders
    for (int i=0; i<NUM_SLIDER; ++i) {
      v = (int)band[row].slider[i].getValue();
      contents[index] = contents[index] +  nf(v, 1) + ",";
    }

    // 3 checkboxes
    for (int i=0; i<3; ++i) {
      v = (int)band[row].cb.getArrayValue()[i];
      contents[index] = contents[index] +  nf(v, 1) + ",";
    }

    ++index;
  }

  saveStrings(wName, contents);
}
