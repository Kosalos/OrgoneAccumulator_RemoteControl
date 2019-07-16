void WRITE2EEPROM() { //only write if it is different
  if (FX != EEPROM.read(0))EEPROM.write(0, FX);
  if (IsHW2) {
    if (EffectEnOn_A != EEPROM.read(1))EEPROM.write(1, EffectEnOn_A);
    if (EffectEnOn_B != EEPROM.read(2))EEPROM.write(2, EffectEnOn_B);
    if (EffectEnOn_C != EEPROM.read(3))EEPROM.write(3, EffectEnOn_C);
    if (xModeOn != EEPROM.read(4))EEPROM.write(4, xModeOn);
    if (FMmodeOn != EEPROM.read(5))EEPROM.write(5, FMmodeOn);
    if (FMFixedOn != EEPROM.read(6))EEPROM.write(6, FMFixedOn);
    if (pulsarOn != EEPROM.read(7))EEPROM.write(7, pulsarOn);
  }
}

void ARMED_FX() {
  if (effectEnButton_A.update()) {
    if (effectEnButton_A.fallingEdge()) {
      FX = 0;
      SELECT_ISRS();
    }
  }
  if (pulsarButton.update()) {
    if (pulsarButton.fallingEdge()) {
      FX = 1;

      SELECT_ISRS();
    }
  }
  if (effectEnButton_B.update()) {
    if (effectEnButton_B.fallingEdge()) {
      FX = 2;

      SELECT_ISRS();
    }
  }
  if (FXCycleButton.update()) {
    if (FXCycleButton.fallingEdge()) {
      FX = 3;
      SELECT_ISRS();
    }
  }
  if (effectEnButton_C.update()) {
    if (effectEnButton_C.fallingEdge()) {
      FX = 4;
      SELECT_ISRS();
    }
  }
  if (xModeButton.update()) {
    if (xModeButton.fallingEdge()) {
      FX = 5;
      SELECT_ISRS();
    }
  }
  if (FMmodeButton.update()) {
    if (FMmodeButton.fallingEdge()) {
      FX = 6;
      SELECT_ISRS();
    }
  }
  if (FMFixedButton.update()) {
    if (FMFixedButton.fallingEdge()) {
      FX = 7;
      SELECT_ISRS();
    }
  }
}

//#define POT_FREQ         analogControls[0]
//#define POT_INDEX        analogControls[1]
//#define POT_EFFECT       analogControls[2]
//#define POT_MOD          analogControls[3]
//#define POT_WAVE_HI      analogControls[4]
//#define POT_WAVE_MID     analogControls[5]
//#define POT_POSITION     analogControls[6]
//#define POT_TUNE_FINE    analogControls[7]
//#define POT_WAVE_LO      analogControls[8]  
//#define POT_TUNE         analogControls[9]

void READ_POTS() {

    // DRUMBEAT $$$$$$$$$$$$$$$$$$$$$$
    // only tune & fineTune are read from hardware. Rest come from DrumBeat app
    if(!(ARC == 7 || ARC == 9)) return;
    // DRUMBEAT $$$$$$$$$$$$$$$$$$$$$$

  if (IsHW2 == 0) {
    analogControls[ARC] = analogRead(potPinTable_DIY[ARC]);
  }//step through control knob readings one per cycle, humans are slow
  else
  {
    analogControls[ARC] = analogRead(potPinTable_ret[ARC]);
  }
}


void TUNELOCK_TOGGLE()
{
  if (IsHW2 == 0) {

    buh = digitalReadFast(tuneLockSwitch);
    if (TUNELOCK_SWITCH == 0) {
      if (tuneLockOn != buh) {
        tuneLockOn = buh;
        digitalWriteFast(LED_TuneLock, tuneLockOn);
        
      }
    }
    else {
      if (pulsarOn != buh) {
        pulsarOn = buh;
        digitalWriteFast(LED_TuneLock, pulsarOn);
        SELECT_ISRS();
      }
    }
  }

  else {
    if (tuneLockButton.update()) {
      if (tuneLockButton.fallingEdge()) {
        tuneLockOn = !tuneLockOn;

      }
    }
  }

}

void FX_TOGGLES() {
  if (IsHW2 == 0) {
    EffectEnOn_A = digitalReadFast(effectSwitch_A);
    EffectEnOn_B = !digitalReadFast(effectSwitch_B);
    EffectEnOn_C = !digitalReadFast(effectSwitch_C);
  }
  else if (FXSelArmed[0] == 0) {

    if (effectEnButton_A.update()) {
      if (effectEnButton_A.fallingEdge()) {
        EffectEnOn_A = !EffectEnOn_A;
        QUIET_MCD = QUIET_MST;
      }
    }

    if (effectEnButton_B.update()) {
      if (effectEnButton_B.fallingEdge()) {
        EffectEnOn_B = !EffectEnOn_B;
        QUIET_MCD = QUIET_MST;
      }
    }

    if (effectEnButton_C.update()) {
      if (effectEnButton_C.fallingEdge()) {
        EffectEnOn_C = !EffectEnOn_C;
        QUIET_MCD = QUIET_MST;
      }
    }

    if (pulsarButton.update()) {
      if (pulsarButton.fallingEdge()) {
        pulsarOn = ! pulsarOn;
        QUIET_MCD = QUIET_MST;
        SELECT_ISRS();
      }
    }

  }
}

void OSC_MODE_TOGGLES() {

    // DRUMBEAT $$$$$$$$$$$$$$$$$$$$$$$$
    // 3 mode toggles are received from DrumBeat app
    
//  if (IsHW2 == 0) {
//    FMFixedOn = digitalReadFast(FMFixedSwitch);
//    xModeOn = !(digitalReadFast(xModeSwitch));
//    FMmodeOn = !(digitalReadFast(FMmodeSwitch));
//  }
//
//  else if (FXSelArmed[0] == 0) {
//    if (FMFixedButton.update()) {
//      if (FMFixedButton.fallingEdge()) {
//        FMFixedOn = !FMFixedOn;
//        QUIET_MCD = QUIET_MST;
//      }
//    }
//
//    if (FMmodeButton.update()) {
//      if (FMmodeButton.fallingEdge()) {
//        FMmodeOn = !FMmodeOn;
//        QUIET_MCD = QUIET_MST;
//      }
//    }
//
//    if (xModeButton.update()) {
//      if (xModeButton.fallingEdge()) {
//        xModeOn = !xModeOn;
//        QUIET_MCD = QUIET_MST;
//      }
//    }
//
//    
//  }
    // DRUMBEAT $$$$$$$$$$$$$$$$$$$$$$$$

  oscMode = ((xModeOn) << 1) + (!FMmodeOn);
}

void SELECT_ISRS() {

  if (IsHW2 == 0) {
    LED_MCD = LED_MST;
  }

  FXSelArmed[0] = 0;
  FXchangedSAVE = 1;
  chord[0] = chord[1] = chord[2] = chord[3] = 1.0;
  detune[0] = detune[1] = detune[2] = detune[3] = 0;

  if (!pulsarOn) {
    switch (FX) {
      case 0:
        outUpdateTimer.end();
        o3.phaseOffset = o1.phaseOffset = 0;
        outUpdateTimer.begin(outUpdateISR_MAIN, ISRrate);

        break;
      case 1:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_WAVE_TWIN, ISRrate);

        break;
      case 2:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_DISTS, ISRrate);
        break;
      case 3:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_DISTS, ISRrate);
        break;
      case 4:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_MAIN, ISRrate);
        break;
      case 5:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_SPECTRUM, ISRrate);
        break;
      case 6:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_WAVE_DELAY, ISRrate);
        break;
      case 7:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_DRUM, ISRrate);
        break;
    }
  }
  else
    switch (FX) {
      case 0:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_CHORD, ISRrate);
        break;
      case 1:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_TWIN, ISRrate);
        break;
      case 2:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_DISTS, ISRrate);
        break;
      case 3:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_DISTS, ISRrate);
        break;
      case 4:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_CHORD, ISRrate);//under isr detune
        break;
      case 5:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_SPECTRUM, ISRrate);
        break;
      case 6:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_PULSAR_DELAY, ISRrate);
        break;
      case 7:
        outUpdateTimer.end();
        outUpdateTimer.begin(outUpdateISR_DRUM, ISRrate);
        break;


    }

}


void GRADUALWAVE_D() {
 GremLo = (uint32_t)(map((POT_WAVE_LO%546),0,545,0,511)); //get remainder for mix amount
 GremHi = (uint32_t)(map((POT_WAVE_HI%546),0,545,0,511));
      GWTlo1 = drumWT[POT_WAVE_LO/ 546];
      GWTlo2 = drumWT[((POT_WAVE_LO/ 546) + 1)];      

      GWThi1 = drumWT2[POT_WAVE_HI/ 546];
      GWThi2 = drumWT2[((POT_WAVE_HI/ 546) + 1)];   
}


void GRADUALWAVE() {

 GremLo = (uint32_t)(map((POT_WAVE_LO%546),0,545,0,511)); //get remainder for mix amount
 GremMid = (uint32_t)(map((POT_WAVE_MID%546),0,545,0,511));
 GremHi = (uint32_t)(map((POT_WAVE_HI%546),0,545,0,511));

  
  switch (oscMode) {
    case 0:
      GWTlo1 = FMWTselLo[POT_WAVE_LO/ 546]; //select "from" wave /546 gives 15 steps
      GWTlo2 = FMWTselLo[((POT_WAVE_LO/ 546) + 1) ]; //select "to"     

      GWTmid1 = FMWTselMid[POT_WAVE_MID/ 546];
      GWTmid2 = FMWTselMid[((POT_WAVE_MID/ 546) + 1)];      

      GWThi1 = FMWTselHi[POT_WAVE_HI/ 546];
      GWThi2 = FMWTselHi[((POT_WAVE_HI/ 546) + 1)];            
      break;
      
    case 2:
      GWTlo1 = FMAltWTselLo[POT_WAVE_LO/ 546];
      GWTlo2 = FMAltWTselLo[((POT_WAVE_LO/ 546) + 1)];      

      GWTmid1 = FMAltWTselMid[POT_WAVE_MID/ 546];
      GWTmid2 = FMAltWTselMid[((POT_WAVE_MID/ 546) + 1)];      
      break;

    case 1:
      GWTlo1 = CZWTselLo[POT_WAVE_LO/ 546];
      GWTlo2 = CZWTselLo[((POT_WAVE_LO/ 546) + 1) ];      

      GWTmid1 = CZWTselMid[POT_WAVE_MID/ 546];
      GWTmid2 = CZWTselMid[((POT_WAVE_MID/ 546) + 1)];     

      GWThi1 = CZWTselHi[POT_WAVE_HI/ 546];
      GWThi2 = CZWTselHi[((POT_WAVE_HI/ 546) + 1)];     

      break;
    case 3:
      GWTlo1 = CZAltWTselLo[POT_WAVE_LO/ 546];
      GWTlo2 = CZAltWTselLo[((POT_WAVE_LO/ 546) + 1)];
      
      GWTmid1 = CZAltWTselMid[POT_WAVE_MID/ 546];
      GWTmid2 = CZAltWTselMid[((POT_WAVE_MID/ 546) + 1) ];
      

      break;
  }
}

