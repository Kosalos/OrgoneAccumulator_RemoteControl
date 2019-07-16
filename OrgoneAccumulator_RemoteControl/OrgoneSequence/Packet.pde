final byte STX = 2;
final byte ETX = 3;
final byte PACKET_DRUMBEAT = 0x60; // packet type code
final byte PACKET_TRIGGER = 0x62;

// ==================================================================

String COMx, COMlist = "";

Boolean askForPort = true; // false = automatically select last listed port

void selectSerialPort()
{
  try {
    printArray(Serial.list());
    int i = Serial.list().length;
    if (i != 0) {
      if (askForPort) {
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

final int PACKET_SIZE = S_COUNT*2 + C_COUNT + 4;  // +4 = GateByte, STX, typecode, ETX

byte[] packet = new byte[PACKET_SIZE]; 
boolean packetSent = false;

void sendDataset(Dataset pp)
{
  if (port == null) return;

  int index = 0;
  packet[index++] = STX;
  packet[index++] = PACKET_DRUMBEAT;

  int i;

  // slider values ------------------------
  for (i=0; i<S_COUNT; ++i) {
    packet[index++] = (byte)(pp.cv[i] & 255);
    packet[index++] = (byte)(pp.cv[i] / 256);
  }

  // checkboxes for mode switches ------
  for (; i< NUM_CV; ++i) {
    packet[index++] = (byte)(pp.cv[i] > 8192/2 ? 1 : 0);
  }

  packet[index++] = byte(gateStatus > 0 ? 0 : 1);

  packet[index] = ETX;
  port.write(packet);
}

// ==================================================================

int state = 0;

void monitorSerialPort() 
{
  if (port == null) return;

  while (port.available () > 0) {
    int val = port.read();
    byte bval = (byte)val;

    switch(state) {
    case 0 :
      if (bval == STX) {
        state = 1;
      } else {
        print((char)bval);
      }
      break;
    case 1 :
      if (bval == PACKET_TRIGGER) {
        state = 2;
        receivedTrigger();
      }
      break;

    case 2 :
      if (bval == ETX) 
        state = 0;
      break;
    }
  }
}
