final byte STX = 2;
final byte ETX = 3;
final byte PACKET_DRUMBEAT = 0x60; // packet type code
final byte PACKET_INCV = 0x61;
final byte PACKET_TRIGGER = 0x62;

// ==================================================================

boolean ASK_FOR_SERIAL = true; // false = automatically select the last listed port

String COMx, COMlist = "";

void selectSerialPort()
{
  try {
    printArray(Serial.list());
    int i = Serial.list().length;

    if (i != 0) {

      if (ASK_FOR_SERIAL) {      
        if (i >= 2) {
          for (int j = 0; j < i; ) {
            COMlist += char(j+'a') + " = " + Serial.list()[j];
            if (++j < i) COMlist += ", \n";
          }
          COMx = showInputDialog("Which COM port connects to Orgone Accumulator? (a,b,..):\n"+COMlist);
          if (COMx == null) exit();
          if (COMx.isEmpty()) exit();
          i = int(COMx.toLowerCase().charAt(0) - 'a') + 1;
        }
      }

      String portName = Serial.list()[i-1];
      println(portName);
      port = new Serial(this, portName, 115200);
      port.buffer(10000);
    } else {
      showMessageDialog(frame, "Device is not connected to the PC");
      exit();
    }
  }
  catch (Exception e)
  { 
    //showMessageDialog(frame, "COM port is not available (maybe in use by another program)");
    //println("Error:", e);
    exit();
  }
}

// ==================================================================
// which slider data is sent over to OA 
final int[] sList = { OFFSET_ID, WAVE1_ID, WAVE2_ID, WAVE3_ID, POSITION_ID, EFFECT_ID, INDEX_ID, FREQ_ID, MOD_ID };
final int S_COUNT = 9;
final int C_COUNT = 3;
final int NUM_CV = S_COUNT + C_COUNT;
final int PACKET_SIZE = S_COUNT*2 + C_COUNT + 4;  // +4 = GateByte, STX, typecode, ETX

byte[] packet = new byte[PACKET_SIZE]; 

void sendDataset()
{
  if (port == null) return;

  int v, sIndex, index = 0;
  packet[index++] = STX;
  packet[index++] = PACKET_DRUMBEAT;

  for (int i=0; i<S_COUNT; ++i) {
    sIndex = sList[i];
    v = (int)band[activeBandIndex].slider[sIndex].getValue();
    packet[index++] = (byte)(v & 255);
    packet[index++] = (byte)(v / 256);
  }

  for (int i=0; i<C_COUNT; ++i) {
    v = (int)band[activeBandIndex].cb.getArrayValue()[i];
    packet[index++] = (byte)v;
  }

  packet[index++] = byte(gateStatus > 0 ? 0 : 1);

  packet[index] = ETX;
  port.write(packet);
}

// ==================================================================
// received input CV packet from OA

class InCVPacket {
  byte  stx;
  byte  typeCode;
  int cv;
  byte  etx;
};

InCVPacket cp;

void cvPacketReceived()
{
  receivedCV = constrain(cp.cv, CV_MIN, CV_MAX);
}

// ==================================================================

byte lowByte, highByte;

int bytesToInt()
{
  int v = (int)lowByte;
  if (v < 0) v = 256+v;

  return v + (int)highByte * 256;
}

// ==================================================================

int state = 0;
int count;

void monitorSerialPort() 
{
  if (port == null) return;

  while (port.available () > 0) {
    int val = port.read();
    byte bval = (byte)val;

    switch(state) {
      // stx ----------------
    case 0 :
      if (bval == STX) {
        cp.stx = bval;
        state = 1;
      } else {
        char c = (char)bval;
        print(c);
      }

      break;

      // typecode -------------
    case 1 :
      if (bval == PACKET_INCV) {
        cp.typeCode = bval;
        state = 2;
        count = 0;
      } else {
        state = 0;
      }
      break;

      // cv ------------------
    case 2 :
      lowByte = bval;
      ++state;
      break;
    case 3 :
      highByte = bval;
      cp.cv = bytesToInt();
      ++state;
      break;

      // etx ------------------
    case 4 :
      if (bval == ETX) 
        cvPacketReceived();
      state = 0;
      break;
    }
  }
}
