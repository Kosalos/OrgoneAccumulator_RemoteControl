/*=====================================================================*
 *                   Copyright (C) 2011 Paul Mineiro                   *
 * All rights reserved.                                                *
 *                                                                     *
 * Redistribution and use in source and binary forms, with             *
 * or without modification, are permitted provided that the            *
 * following conditions are met:                                       *
 *                                                                     *
 *     * Redistributions of source code must retain the                *
 *     above copyright notice, this list of conditions and             *
 *     the following disclaimer.                                       *
 *                                                                     *
 *     * Redistributions in binary form must reproduce the             *
 *     above copyright notice, this list of conditions and             *
 *     the following disclaimer in the documentation and/or            *
 *     other materials provided with the distribution.                 *
 *                                                                     *
 *     * Neither the name of Paul Mineiro nor the names                *
 *     of other contributors may be used to endorse or promote         *
 *     products derived from this software without specific            *
 *     prior written permission.                                       *
 *                                                                     *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND              *
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,         *
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES               *
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE             *
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER               *
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,                 *
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES            *
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE           *
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR                *
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF          *
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT           *
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY              *
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE             *
 * POSSIBILITY OF SUCH DAMAGE.                                         *
 *                                                                     *
 * Contact: Paul Mineiro <paul@mineiro.com>                            *
 *=====================================================================*/
//this above is for the fastpow2 approximation

inline float
fastpow2 (float p)

{
  float offset = (p < 0) ? 1.0f : 0.0f;
  float clipp = (p < -126) ? -126.0f : p;
  int w = clipp;
  float z = clipp - w + offset;
  union {
    uint32_t i;
    float f;
  } v = { cast_uint32_t ( (1 << 23) *
                          (clipp + 121.2740575f + 27.7280233f / (4.84252568f - z) - 1.49012907f
                           * z) )
        };

  return v.f;
}

// computes ((a[31:0] * b[15:0]) >> 16) from pjrc audio lib
static inline int32_t signed_multiply_32x16b(int32_t a, uint32_t b) __attribute__((always_inline, unused));
static inline int32_t signed_multiply_32x16b(int32_t a, uint32_t b)
{
  int32_t out;
  asm volatile("smulwb %0, %1, %2" : "=r" (out) : "r" (a), "r" (b));
  return out;
}

// computes ((a[31:0] * b[31:16]) >> 16) from pjrc audio lib
static inline int32_t signed_multiply_32x16t(int32_t a, uint32_t b) __attribute__((always_inline, unused));
static inline int32_t signed_multiply_32x16t(int32_t a, uint32_t b)
{
  int32_t out;
  asm volatile("smulwt %0, %1, %2" : "=r" (out) : "r" (a), "r" (b));
  return out;
}

// computes (((int64_t)a[31:0] * (int64_t)b[31:0]) >> 32) from pjrc audio lib
static inline int32_t multiply_32x32_rshift32(int32_t a, int32_t b) __attribute__((always_inline, unused));
static inline int32_t multiply_32x32_rshift32(int32_t a, int32_t b)
{
  int32_t out;
  asm volatile("smmul %0, %1, %2" : "=r" (out) : "r" (a), "r" (b));
  return out;
}

//  signed saturate to 13 bits  
static inline int32_t ssat13(int32_t a) __attribute__((always_inline, unused));
static inline int32_t ssat13(int32_t a)
{
  int32_t out;
  asm volatile("ssat %0, #13, %1" : "=r" (out) : "r" (a));
  return out;
}

//  signed saturate to 15 bits  
static inline int32_t ssat15(int32_t a) __attribute__((always_inline, unused));
static inline int32_t ssat15(int32_t a)
{
  int32_t out;
  asm volatile("ssat %0, #15, %1" : "=r" (out) : "r" (a));
  return out;
}

//// computes (((uint64_t)a[31:0] * (uint64_t)b[31:0]) >> 32) 
//static inline uint32_t unsigned_multiply_32x32_rshift32(uint32_t a, uint32_t b) __attribute__((always_inline, unused));
//static inline uint32_t unsigned_multiply_32x32_rshift32(uint32_t a, uint32_t b)
//{
//  int32_t out;
//  asm volatile("ummul %4 ,%0, %1, %2" : "=r" (out) : "r" (a), "r" (b));
//  return out;
//}

static inline int16_t Interp512(int16_t wave, int16_t wavenext, uint32_t phase) __attribute__((always_inline, unused));
static inline int16_t Interp512(int16_t wave, int16_t wavenext, uint32_t phase) {  
  return wave + ((wavenext - wave) * static_cast<int32_t>((phase << 9) >> 17) >> 15);
}


void inline NOISELIVE0() {

  nosc0.decay  = o1.phase_increment >> 4; //mod on FM, main on cz and puls


  if (nosc0.trig) {
    nosc0.envVal = nosc0.envVal + nosc0.decay;
    if (nosc0.envVal >= nosc0.envBreak) nosc0.trig = 0;
  }
  else {
    nosc0.envVal = nosc0.envVal - nosc0.decay;
  }
  if (nosc0.envVal < 10)
  {
    nosc0.wave = (random(-32767, 32767));
    nosc0.envBreak = (random(0, 32767)) << 10 ;
    nosc0.trig = 1;
  }
  nosc0.nextwave = nosc0.envVal >> 10;
  nosc0.nextwave = (nosc0.nextwave * nosc0.wave) >> 15;
  noiseLive0[1] = noiseLive0[0] =  nosc0.nextwave;
}

void inline NOISELIVE1() {

  nosc1.decay  = o2.phase_increment >> 6; //main on FM, mod on cz and puls


  if (nosc1.trig) {
    nosc1.envVal = nosc1.envVal + nosc1.decay;
    if (nosc1.envVal >= nosc1.envBreak) {
      nosc1.trig = 0; nosc1.envVal = nosc1.envBreak;
    }
  }
  else {
    nosc1.envVal = nosc1.envVal - nosc1.decay;
    if (nosc1.envVal < 0 ) nosc1.envVal = 0;
  }
  if (nosc1.envVal < 10)
  {
    nosc1.wave = (random(-32767, 32767));
    nosc1.envBreak = (random(0, 32767)) << 10 ;
    nosc1.trig = 1;
  }
  nosc1.nextwave = nosc1.envVal >> 10;
  nosc1.nextwave = (nosc1.nextwave * nosc1.wave) >> 15;
  noiseLive1[1] = noiseLive1[0] =  nosc1.nextwave;
}

void inline DECLICK_CHECK() {
if (declickRampOut > 0) declickRampOut = (declickRampOut - declick);
  else declickRampOut = 0;
  declickValue = (declickValue * declickRampOut) >> 12;
  declickRampIn = abs(4095 - declickRampOut);
}

//void inline SUBMULOC() {
//oSQ.phase = oSQ.phase +  (uint32_t)oSQ.phase_increment; //square wave osc
//  digitalWriteFast (oSQout, (oSQ.phase < oSQ.PW)); //pulse out
//}
// zorro replace PWM output with Gate output

void inline SUBMULOC() {
  digitalWriteFast (oSQout,gateOn);
}
