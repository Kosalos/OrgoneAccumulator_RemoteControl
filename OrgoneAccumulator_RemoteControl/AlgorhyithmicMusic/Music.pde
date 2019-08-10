// https://www.youtube.com/watch?v=qlrcolumnStringsVorw2Y //<>// //<>//
//value = (t>>6 | t | t >> (t >> 16)) * 10 + ((t >>11) & 7);
//value = (v>>1)+(v>>4)+t*(((t>>16)|(t>>6))&(69&(t>>9)));
//value = (t | (t>>9 | t>>7))*t &(t>>11 |  t>>9);
//value = t*5&(t>>7)|t*3&(t*4>>10);
//value = (t>>7|t|t>>6)*10+4*(t&t>>13|t>>6);
//value = ((t & 4096) > 0 ? ((t*(t^t%255)|(t>>4))>>1) : (t>>3)|((t & 8192) > 0 ?t<<2:t));
//value = ((t*(t>>8|t>>9)&46&t>>8))^(t&t>>13|t>>6);
//value = int( sin(t/20) / cos(t/200) / sin(t/600) /0.3) | int(1-sin(t/50)) | int(1-cos(t/50) );

private int t = 0;

class Music {
  int alteredPaceCount = 0;
  int paceTarget, alteredPaceTarget;
  int pace = 0;
  int value;

  void iterate() {
    if (!widget.getToggle(PAUSE_ID)) {

      paceTarget = widget.getValue(SPEED_ID);

      if (widget.getToggle(PACE_ID)) {
        if (alteredPaceCount == 0) {
          if (percentChance(5)) {
            alteredPaceCount = 20;        
            alteredPaceTarget = percentChance(50) ? paceTarget * 4 / 3 : paceTarget * 3 / 4; 
            if (alteredPaceTarget < 1) alteredPaceTarget = 1;
          }
        }

        if (alteredPaceCount > 0) {
          --alteredPaceCount;
          paceTarget = alteredPaceTarget;
        }
      }

      if (++pace > paceTarget) {
        pace = 0;

        value = (t >> widget.getValue(EQUATIONPARAM_ID+0) | t | t >> (t >> widget.getValue(EQUATIONPARAM_ID+1))) * 
          (1 + widget.getValue(EQUATIONPARAM_ID+2)) + ((t >> widget.getValue(EQUATIONPARAM_ID+3)) % (1 + widget.getValue(EQUATIONPARAM_ID+4)));

        value = (value % widget.getValue(MODULO_ID));
        value = widget.getValue(RANGELOW_ID) + value * (widget.getValue(RANGEHIGH_ID)- widget.getValue(RANGELOW_ID) ) / widget.getValue(MODULO_ID);

        t += 1; 

        if (widget.getToggle(PACE_ID)) {
          //------------------
          if (percentChance(5)) {
            t -= (int)random(10, 200);
            if (t < 0) t = 0;
          }
        }

        receivedCV = constrain(value, CV_MIN, CV_MAX);
        gateStatus = 1;
        requestSendDataset= true;
      }
    }
  }
}
