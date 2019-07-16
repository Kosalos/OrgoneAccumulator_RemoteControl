//neutron orgone accumulator config file. 


#define TUNEMULT 159000 
//#define TUNEMULT 5900000
//this is the base frequency. halving it will lower the entire oscillator by 1 octave 
//real frequency is sent to the broadcast application for tuning

extern const int tuneStep = 1;//this is how many semitones the tuning knob steps in.

#define NOTESIZE 72.0 
// note resolution. lower value will give wider oscillator range, higher will give better resolution
//you will need to recalibrate the v/oct trimmer if you adjust this. decimal is important, even if zero.

#define LED_COMP 1000 //dim the LEDSs higher number = lower brightness. (only for the position LEDs)

//DIY hardware 1.x boards--------------------------------------------------------------------start

#define LED_MODESWITCH_TIME 5000 //time LEDs stay on when effect is switched in main loop cycles, about 2-3000 per second depending on am/fm effects etc.

//LED compensation. adjusts how the LEDs fade across positions

//DIY hardware 1.x boards--------------------------------------------------------------------end
//everyone gets all effects now.

#define FX_SWITCH 0 //dont change for HW2!

//0 = momentary
//1 = toggle

extern const int TUNELOCK_SWITCH = 1;
//0 = tune lock
//1 = pulsar  replaces tune lock with pulsar, reducing FX steps back to 8


#define PWM_SUB 2

//divider to use the PWM as a sub oscillator. DO NOT ENTER ZERO.
//1 = same as main.
//2 = 1 octave down
//4 = 2 octaves etc. 

#define PWM_MINIMUM 4

//128ths of a cycle the thinnest pulse can be. 0 will allow silence to fall.

#define PWM_CONTROL 1

//0 = position control and CV controls PWM across range
//1 = index controls PWM minimum PW to 50%, modified by index CV

// Broadcast ---------------------------
extern int BROADCAST;
// Broadcast ---------------------------

//chord intervals each group of 3 numbers is the triplet. dont change the amount of entries!
extern const int chordTable[] = {
  1, 3, 5,
  1, 4, 7,
  1, 3, 7,
  1, 4, 6,
  1, 3, 6,
  1, 5, 9,
  1, 4, 8,
  1, 3, 8,
  1, 4, 9,
};

#define DECLICK 8
//declicking. 4000 = normal operation
//higher number is faster ramp
//do not change the

// ===========================================================

#define POT_FREQ         analogControls[0]
#define POT_INDEX        analogControls[1]
#define POT_EFFECT       analogControls[2]
#define POT_MOD          analogControls[3]
#define POT_WAVE_HI      analogControls[4]
#define POT_WAVE_MID     analogControls[5]
#define POT_POSITION     analogControls[6]
#define POT_TUNE_FINE    analogControls[7]
#define POT_WAVE_LO      analogControls[8]  
#define POT_TUNE         analogControls[9]

enum {
  S_INCV = 0, // slider indices in packet
  S_WAVE1,
  S_WAVE2,
  S_WAVE3,
  S_POSITION,
  S_EFFECT,
  S_INDEX,
  S_FREQ,
  S_MOD,

  S_COUNT = 9,
  CB_COUNT = 4
};

#pragma pack(1)

typedef struct {
  uint8_t  stx;
  uint8_t  typeCode;
  uint16_t slider[S_COUNT];
  uint8_t  checkbox[CB_COUNT];  // [3] = Gate
  uint8_t  etx;
} DrumBeatPacket;

typedef struct {
  uint8_t  stx;
  uint8_t  typeCode;
  uint16_t cv;
  uint8_t  etx;
} InCVPacket;

#define DRUMBEATPACKET_SIZE sizeof(DrumBeatPacket)
#define CVPACKET_SIZE       sizeof(InCVPacket)

extern DrumBeatPacket drumBeat;  
