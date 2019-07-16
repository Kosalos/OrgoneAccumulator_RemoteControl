Boolean handleEvent(int id) //<>//
{
  boolean needToSave = false;

  switch(id) {
  case ID_STARTSTOP :
    isPlaying = !isPlaying;
    controlP5.getController(startStopLegend).setColorBackground(isPlaying ? HIGHLIGHTCOLOR : BLUECOLOR);
    playIndex = 0;
    determinePlaySpeedT();
    break;
  case ID_RESET :
    reset();
    needToSave = true;
    break;
  case ID_RNDPADPLUS :
    randomPadPlus();
    needToSave = true;
    break;
  case ID_RNDPADMINUS :
    randomPadMinus();
    needToSave = true;
    break;
  case ID_RND_CV :
    randomizeCV();
    needToSave = true;
    break;
  case ID_RND_ALL :
    randomizeAll();
    needToSave = true;
    break;
  case ID_EVOLVE :
    evolveFlag = !evolveFlag;
    controlP5.getController(evolveLegend).setColorBackground(evolveFlag ? HIGHLIGHTCOLOR : BLUECOLOR);
    break;
  case ID_SAVESEQ :
    saveSequence();
    break;
  case ID_LOADSEQ :
    loadSequence();
    break;
  case ID_HELP :
    showHelp();
    break;
  case ID_GLISSFLAG :
    glissandoWrapFlag = !glissandoWrapFlag;
    controlP5.getController(glissandoWrapLegend).setColorBackground(glissandoWrapFlag ? HIGHLIGHTCOLOR : BLUECOLOR);
    determineCvEntries();
    break;
  }

  for (int i=0; i<NUM_CV; ++i) {
    if (id == ID_RNDPLUS+i) { 
      randomCvPlus(i); 
      needToSave = true;
    }
    if (id == ID_RNDMINUS+i) { 
      randomCvMinus(i); 
      needToSave = true;
    }
  }

  for (int i=0; i<NUM_TIMING; ++i) {
    if (id == ID_TIMING+i) { 
      alterTiming(i); 
      needToSave = true;
    }
  }

  return needToSave;
}

// ==================================================================

void controlEvent(ControlEvent theEvent) 
{
  if (backDoor) return; // during file load, do not alter storage

  boolean needToSave = false;

  // glissando: checkboxes, sliders -----------------------
  for (int i=0; i<NUM_CV; ++i) {
    if (theEvent.isFrom(glissC[i])) {
      glissandoFlag[i] = glissC[i].getArrayValue()[0] > 0;
      determineCvEntries();
    }
    if (theEvent.isFrom(glissS[i])) {
      glissS[i].setValueLabel("");      
      determineCvEntries();
    }
  }

  // timing sliders ---------------------
  for (int i=0; i<NUM_PAD; ++i) {
    if (theEvent.isFrom(timing[i])) {
      timing[i].setValueLabel("");
      colorizeTimingSlider(i);
    }
  }

  // assignment checkboxes ------------------------------
  boolean debugDisplayFlag = false;

  for (int r=0; r<NUM_ROW; ++r) {
    if (theEvent.isFrom(seq.row[r].assignCB)) {
      debugDisplayFlag = true;
      needToSave = true;
      for (int m=0; m<NUM_CV; ++m) {
        seq.row[r].assign[m] = 0; // assume not assigned
        if (seq.row[r].assignCB.getArrayValue()[m] > 0) {
          seq.row[r].assign[m] = 1;
        }
      }

      determineCvEntries();
    }
  }

  // sequencer -------------------------------------------
  for (int r=0; r<NUM_ROW; ++r) {
    if (theEvent.isFrom(seq.row[r].noteSlider)) {
      seq.row[r].note = (int)seq.row[r].noteSlider.getValue();      
      seq.row[r].noteSlider.setValueLabel(nf(seq.row[r].note));      
      needToSave = true;
    }

    if (theEvent.isFrom(seq.row[r].matrixCB)) {
      needToSave = true;
      for (int c=0; c< NUM_PAD; ++c) {
        seq.row[r].matrix[c] = (byte)seq.row[r].matrixCB.getArrayValue()[c];
      }
    }

    if (needToSave)
      determineCvEntries();
  }

  if (debugDisplayFlag) {
    //println("========================\n");
    //for (int r=0; r<6; ++r) {
    //  for (int m=0; m<NUM_CV; ++m) {
    //    float cb = seq.row[r].assignCB.getArrayValue()[m];
    //    print(int(cb) + "" + seq.row[r].assign[m] + " ");
    //  }

    //  println("");
    //}

    //cvEntryDebug();
  }

  if (theEvent.isController()) { 
    if (theEvent.getController().getName() == speedLegend) {
      playSpeed = (int)theEvent.getController().getValue();
      speed.setValueLabel(""); 
      changeSpeed(0);
      return;
    }
    if (theEvent.getController().getName() == numPadsLegend) {
      padCount = (int)theEvent.getController().getValue();
      numPads.setValueLabel(nf(padCount)); 
      return;
    }

    // defaults -------------------------------------------
    for (int i=0; i<NUM_CV; ++i) {
      if (theEvent.isFrom(defaults[i])) {
        if (i < 9) {
          int v = int(defaults[i].getValue());
          defaults[i].setValueLabel(nf(v));
        } else
          defaults[i].setValueLabel("");

        determineCvEntries();
      }
    }

    int id = theEvent.getId();
    needToSave |= handleEvent(id); // button presses

    if (needToSave) {
      saveToFile(autoSaveFilename);
      determineCvEntries();
    }
  }
}

// ==================================================================

void debug()
{
  println("isPlaying = " + isPlaying);
  for (int r=0; r<NUM_ROW; ++r) {
    print("row:" + r + " note:" + seq.row[r].note + " Assign: ");

    for (int i=0; i<NUM_CV; ++i)
      print(seq.row[r].assign[i] + ",");

    print(" Pad: ");
    for (int i=0; i<NUM_PAD; ++i)
      print(seq.row[r].matrix[i] + ",");

    println();
  }
}

// ==================================================================

Boolean percentChance(int percent)
{
  return random(0, 100) <= percent;
}

void randomPadPlus() 
{
  for (int r=0; r<NUM_ROW; ++r) {
    for (int i=0; i<NUM_PAD; ++i) {
      if (percentChance(5)) {
        seq.row[r].matrix[i] = 1;
        seq.row[r].matrixCB.activate(i);
      }
    }
  }
}

void randomPadMinus() 
{
  for (int r=0; r<NUM_ROW; ++r) {
    for (int i=0; i<NUM_PAD; ++i) {
      if (percentChance(5)) {
        seq.row[r].matrix[i] = 0;
        seq.row[r].matrixCB.deactivate(i);
      }
    }
  }
}

void randomCvPlus(int index) 
{
  for (int r=0; r<NUM_ROW; ++r) {
    if (percentChance(50)) {
      seq.row[r].assign[index] = 1;
      seq.row[r].assignCB.activate(index);
    }
    if (percentChance(50)) {
      seq.row[r].assign[index] = 0;
      seq.row[r].assignCB.deactivate(index);
    }
  }
}

void randomCvMinus(int index) 
{
  for (int r=0; r<NUM_ROW; ++r) {
    seq.row[r].assign[index] = 0;
    seq.row[r].assignCB.deactivate(index);
  }
}

void randomizeCV()
{
  for (int r=0; r<NUM_ROW; ++r) {
    seq.row[r].note = (int)random(0, 7000);
    seq.row[r].noteSlider.setValue(seq.row[r].note);
  }
}

void randomizeAll()
{
  randomPadPlus();
  randomPadMinus();
  randomizeCV();

  for (int r=0; r<NUM_ROW; ++r) {
    for (int i=0; i<NUM_CV; ++i) {
      if (percentChance(60)) {
        seq.row[r].assign[i] = 0;
        seq.row[r].assignCB.deactivate(i);
      } else {
        seq.row[r].assign[i] = 1;
        seq.row[r].assignCB.activate(i);
      }
    }
  }
}

void alterTiming(int index) // 0 = 1/32, 1 = 1/16, 2 = 1/8, 3 = 1/4, 4 = 1/2, 5 = whole onte
{
  if (index == 0) { // whole
    for (int i=0; i<NUM_PAD; ++i)
      timing[i].setValue(5);
  } else {
    for (int i=0; i<NUM_PAD; ++i)
      if (percentChance(10))
        timing[i].setValue(5-index);
  }
}

void determinePlaySpeedT() // playSpeed affected by timing duration for current matrix column
{
  float ratio = 1;
  switch((int)timing[playIndex].getValue()) {
  case 0 : 
    ratio = 1.0/32.0;  
    break;
  case 1 : 
    ratio = 1.0/16.0;  
    break;
  case 2 : 
    ratio = 1.0/8.0;  
    break;
  case 3 : 
    ratio = 1.0/4.0;  
    break;
  case 4 : 
    ratio = 1.0/2.0;  
    break;
  }   

  playSpeedT = (int)(float(playSpeed * playSpeed) * ratio);
  if (playSpeedT < 1) playSpeedT = 1;
}

// =====================================================

boolean toggleG = false;

void toggleAllGlissando()
{
  toggleG = !toggleG;

  if (!toggleG) {
    for (int i=0; i<NUM_CV; ++i) {
      glissC[i].deactivateAll();
      glissandoFlag[i] = false;
    }
  } else {
    for (int i=0; i<NUM_CV; ++i) {
      glissC[i].activateAll();
      glissandoFlag[i] = true;
    }
  }

  determineCvEntries();
}
