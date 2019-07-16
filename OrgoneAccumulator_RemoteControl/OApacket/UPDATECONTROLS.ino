void UPDATECONTROLS_CZ() {


  switch (ARC + 1) {

    case 8:
//Serial.print(CRUSHBITS);
//Serial.print("     ");
//Serial.println(CRUSH_Remain);
      break;

    case 10:

      
      //outputs the frequency on USB serial. tune lock, FM and X must be off


      break;

    case 3:

      EffectAmountCont = POT_EFFECT;
      

      break;

    case 4:

      TUNELOCK_TOGGLE();

      waveTableMidLink = CZWTselMid[POT_WAVE_MID >> 9];

      break;

    case 5:

      waveTableLoLink = CZWTselLo[POT_WAVE_LO >> 9];


      break;

    case 6: //select hi wave

      waveTableHiLink = CZWTselHi[POT_WAVE_HI >> 9];

      if ((POT_WAVE_HI >> 9) == 15) WTShiftHi = 31;
      else WTShiftHi = 23;

      break;

    case 1:
      mixPos = (POT_POSITION >> 1);

      OSC_MODE_TOGGLES();
     

      break;

    case 7:
      FX_TOGGLES();


      break;

    case 2:
      totalratio = totalratio - readingsratio[controlAveragingIndex];
      readingsratio[controlAveragingIndex] = POT_FREQ;
      totalratio = totalratio + readingsratio[controlAveragingIndex];
      controlAveragingIndex = controlAveragingIndex + 1;
      if (controlAveragingIndex >= numreadingsratio) controlAveragingIndex = 0;
      averageratio = totalratio / numreadingsratio;
      break;

    case 9:
      FMIndexCont = (int)(POT_INDEX >> 2);
      FMTable = CZWTselFM[POT_MOD >> 9];

      break;


  }
}
//--------------------------------------------------------------------CZ-ALT--------------------------------------------------
void UPDATECONTROLS_CZALT() {

  switch (ARC + 1) {

    case 8:

      break;

    case 10:


      break;

    case 3:
      TUNELOCK_TOGGLE();
      EffectAmountCont = POT_EFFECT;
     
      break;

    case 4:

      waveTableMidLink = CZAltWTselMid[POT_WAVE_MID >> 9];

      if ((POT_WAVE_MID >> 9) == 15) WTShiftMid = 31;
      else WTShiftMid = 23;


      break;

    case 5:

      waveTableLoLink = CZAltWTselLo[POT_WAVE_LO >> 9];

      break;

    case 6: //no hi wave in alt(x) mode

      FMX_HiOffsetContCub = (POT_WAVE_HI >> 3) - 512;
      FMX_HiOffsetCont = (float)(FMX_HiOffsetContCub * FMX_HiOffsetContCub * FMX_HiOffsetContCub) / 1073741824.0;
    

    case 1:
      mixPos = POT_POSITION>>1;

      OSC_MODE_TOGGLES();
    


      break;

    case 7:
      FX_TOGGLES();


      break;

    case 2:
      totalratio = totalratio - readingsratio[controlAveragingIndex];
      readingsratio[controlAveragingIndex] = POT_FREQ;
      totalratio = totalratio + readingsratio[controlAveragingIndex];
      controlAveragingIndex = controlAveragingIndex + 1;
      if (controlAveragingIndex >= numreadingsratio) controlAveragingIndex = 0;
      averageratio = totalratio / numreadingsratio;
      break;

    case 9:
      FMIndexCont = (int)(POT_INDEX >> 2);

      FMTable = CZAltWTselFM[POT_MOD >> 9];
      FMTableAMX = CZAltWTselFMAMX[POT_MOD >> 9]; //am mod on hi position

      if ((POT_MOD >> 9) == 15) WTShiftFM = 31;
      else WTShiftFM = 23;


      break;


  }
}


//----------------------------------------------------------------FM--------------------------------------------------------
void UPDATECONTROLS_FM() {

  switch (ARC + 1) {
    case 8: //8 and 10 are skipped when tune lock is on, do not use.
      break;
    case 10:
      break;

    case 3:
      TUNELOCK_TOGGLE();
      EffectAmountCont = POT_EFFECT;
          
      break;

    case 4: //mid wave
      waveTableMidLink = FMWTselMid[POT_WAVE_MID >> 9];
      break;

    case 5:  //lo wave
      waveTableLoLink = FMWTselLo[POT_WAVE_LO >> 9];
      break;

    case 6: //select hi wave
      waveTableHiLink = FMWTselHi[POT_WAVE_HI >> 9];
      
      if ((POT_WAVE_HI >> 9) == 15) WTShiftHi = 31;
      else WTShiftHi = 23;

      break;

    case 1:
      mixPos = (POT_POSITION >> 1);

      OSC_MODE_TOGGLES();

      break;

    case 7:

      FX_TOGGLES();

      break;

    case 2:
      totalratio = totalratio - readingsratio[controlAveragingIndex];
      readingsratio[controlAveragingIndex] = POT_FREQ; //fm ratio control smoothing in FM
      totalratio = totalratio + readingsratio[controlAveragingIndex];
      controlAveragingIndex = controlAveragingIndex + 1;
      if (controlAveragingIndex >= numreadingsratio) controlAveragingIndex = 0;
      averageratio = totalratio / numreadingsratio;
      break;

    case 9:
      FMIndexCont = (int)(POT_INDEX >> 2);     

      FMTable = FMWTselFM[POT_MOD >> 9];
      if ((POT_MOD >> 9) == 15) WTShiftFM = 31;
      else WTShiftFM = 23;


      break;


  }
}
//--------------------------------------------------------------------------FMALT--------------------------------------------------------------

void UPDATECONTROLS_FMALT() {

  switch (ARC + 1) {

    case 8: //7 and 9 are skipped when tune lock is on, do not use.
      break;
      case 10:
      break;

    case 3:
      TUNELOCK_TOGGLE();
      EffectAmountCont = POT_EFFECT;
     
      break;

    case 4:
      waveTableMidLink = FMAltWTselMid[POT_WAVE_MID >> 9];

       if ((POT_WAVE_MID >> 9) == 15) WTShiftMid = 31;
      else WTShiftMid = 23;
      break;

    case 5:
      waveTableLoLink = FMAltWTselLo[POT_WAVE_LO >> 9];
      break;

    case 6: //select hi pitch offset
     FMX_HiOffsetContCub = (POT_WAVE_HI >> 3) - 512;
      FMX_HiOffsetCont = (float)(FMX_HiOffsetContCub * FMX_HiOffsetContCub * FMX_HiOffsetContCub) / 134217728.0;
      break;

    case 1:
      mixPos = (POT_POSITION >> 1);

      OSC_MODE_TOGGLES();
     

      break;

    case 7:

      FX_TOGGLES();

      break;

    case 2:
      totalratio = totalratio - readingsratio[controlAveragingIndex];
      readingsratio[controlAveragingIndex] = POT_FREQ; //fm ratio control smoothing in FM
      totalratio = totalratio + readingsratio[controlAveragingIndex];
      controlAveragingIndex = controlAveragingIndex + 1;
      if (controlAveragingIndex >= numreadingsratio) controlAveragingIndex = 0;
      averageratio = totalratio / numreadingsratio;
      break;

    case 9:
      FMIndexCont = (int)(POT_INDEX >> 2);     

      FMTable = FMAltWTselFM[POT_MOD >> 9];
      if ((POT_MOD >> 9) == 15) WTShiftFM = 31;
      else WTShiftFM = 23;

      break;


  }
}

void UPDATECONTROLS_DRUM() {


  switch (ARC + 1) {

    case 8:

      break;

    case 10:




      break;

    case 3:

      EffectAmountCont = POT_EFFECT;

      break;

    case 4:

      TUNELOCK_TOGGLE();
     
      
      //((((drum_d * drum_d)>>16)+1)*drum_d)>>2;drum_d
      //drum decay

      break;

    case 5:
      
      //waveTableMidLink = drumWT[POT_WAVE_LO >> 9];

      break;

    case 6: //select hi wave

      

      break;

    case 1:
      mixPos = (POT_POSITION >> 1); //this is drum wave mix

      OSC_MODE_TOGGLES();
     

      break;

    case 7:
      FX_TOGGLES();


      break;

    case 2:
      

      break;

    case 9:
      FMIndexCont = (int)(POT_INDEX >> 2);

      //waveTableHiLink = drumWT2[POT_WAVE_HI >> 9]; //drum uses mid wave from fm
       //drum uses mid wave from fm
//      if ((POT_MOD >> 9) == 15) WTShiftMid = 31;
//      else WTShiftMid = 23;

      break;


  }
}


