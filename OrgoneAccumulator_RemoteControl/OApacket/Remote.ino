// Remote ----------------------------------------------------

enum {
  STX = 2,
  ETX = 3,
  PACKET_DRUMBEAT   = 0x60,
  PACKET_INCV       = 0x61,
  PACKET_TRIGGER    = 0X62,

  STATE_IDLE =  0,
  STATE_TYPECODE,
  STATE_MDATA,
};

InCVPacket ip = { STX, PACKET_INCV, 0, ETX };
DrumBeatPacket drumBeat = { 0 };

static uint8_t  state = STATE_IDLE;
static uint16_t bIndex = 0;
static uint8_t  buffer[32];

void parsePacket()
{
  if (buffer[1] == PACKET_DRUMBEAT) {
    memcpy(&drumBeat, buffer, DRUMBEATPACKET_SIZE);

    // drumBeat.slider[0]  (cv Offset) affects inCV in mainLoop()

    POT_WAVE_LO     = drumBeat.slider[1];
    POT_WAVE_MID    = drumBeat.slider[2];
    POT_WAVE_HI     = drumBeat.slider[3];
    POT_POSITION    = drumBeat.slider[4];
    POT_EFFECT      = drumBeat.slider[5];
    POT_INDEX       = drumBeat.slider[6];
    POT_FREQ        = drumBeat.slider[7];
    POT_MOD         = drumBeat.slider[8];

    xModeOn         = drumBeat.checkbox[0];
    FMmodeOn        = drumBeat.checkbox[1];
    FMFixedOn       = drumBeat.checkbox[2];
    gateOn          = drumBeat.checkbox[3];
    // Serial.print("Received DrumBeat Packet\n"); // text sent this way displays on Processing's console window.
  }
}

// ======================================================

int packetSize = 0;

void monitorSerialReception()
{
  byte ch;

  for (;;) {
    if (Serial.available() <= 0) return;
    ch = Serial.read();

    switch (state) {
      case STATE_IDLE :
        if (ch == STX) {
          state = STATE_TYPECODE;
          bIndex = 0;
          buffer[bIndex++] = ch;
        }
        break;

      case STATE_TYPECODE :
        switch (ch) {
          case PACKET_DRUMBEAT :
            state = STATE_MDATA;
            packetSize = DRUMBEATPACKET_SIZE;
            buffer[bIndex++] = ch;
            break;
          default :
            state = STATE_IDLE;
            break;
        }
        break;

      case STATE_MDATA :
        buffer[bIndex++] = ch;
        if (bIndex >= packetSize) {
          parsePacket();
          state = STATE_IDLE;
        }
        break;

      default :
        state = STATE_IDLE;
        break;
    }
  }
}

// ======================================================

void sendInCV(uint16_t cv)
{
  ip.cv = cv;

  uint8_t *ptr = (uint8_t *)&ip;
  for (uint16_t i = 0; i < CVPACKET_SIZE; ++i)
    Serial.write(ptr[i]);
}

// ======================================================

void sendTriggerPacket()
{
  uint8_t triggerPacket[] = { STX,PACKET_TRIGGER,ETX };
  
  for (uint16_t i = 0; i < 3; ++i)
    Serial.write(triggerPacket[i]);
}
