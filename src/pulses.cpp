/*
 * Author	Thomas Husterer <thus1@t-online.de>
 * Author	Josef Glatthaar <josef.glatthaar@googlemail.com >
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 */

#include "th9x.h"
/******************************************************************************
  the functions below are from int-level
  the functions below are from int-level
  the functions below are from int-level
******************************************************************************/

uint16_t  pulses2MHz[60];
uint16_t *pulses2MHzPtr;



void setupPulsesPPM()
{
  //http://www.aerodesign.de/peter/2000/PCM/frame_ppm.gif
  //22.5 ges   0.3low 8* (0.7-1.7 high 0.3low) high
  //uint16_t rest=22500u*2;
  uint16_t rest=(22500u-300u*9)*2; //issue 4, 41
  //uint8_t j=0;
  for(uint8_t i=0;i<8;i++){ //NUM_CHNOUT
    int16_t v = g_chans512[i];
    v = 2*v - v/21 + 1200*2; // 24/512 = 3/64 ~ 1/21
    rest-=v;//chans[i];
    *pulses2MHzPtr++ = 300*2 -1;
    *pulses2MHzPtr++ = v     -1;
  }
  *pulses2MHzPtr++ = 300*2   -1;
  *pulses2MHzPtr++ = rest    -1;

}



// _ oder - je 0.6ms  (gemessen 0.7ms)
//
// Achtung !! 0 am Ausgang = sendesignal high
//____-----_-_-_--_--_   -_--__  -_-_-_-_  -_-_-_-_  --__--__-_______
//         trailer        chan     m1         m2      
//
//see /home/thus/txt/silverlit/thus.txt
//m1, m2 most significant bit first |m1-m2| <= 9
//chan: 01=C 10=B
//chk = 0 - chan -m1>>2 -m1 -m2>>2 -m2
//<= 500us Probleme
//>= 650us Probleme
//periode orig: 450ms

#define BITLEN (600u*2)
void _send_hilo(uint16_t hi,uint16_t lo)
{
  *pulses2MHzPtr++=hi; *pulses2MHzPtr++=lo;
}
#define send_hilo_silv( hi, lo) _send_hilo( (hi)*BITLEN-1,(lo)*BITLEN-1 )

void sendBitSilv(uint8_t val)
{
  // 0-Bit: 600us hi +  600us lo
  // 1-Bit:1200us hi + 1200us lo
  send_hilo_silv((val)?2:1,(val)?2:1);
}
void send2BitsSilv(uint8_t val)
{
  sendBitSilv(val&2);sendBitSilv(val&1);
}
void setupPulsesSilver()
{
  int8_t chan=1; //chan 1=C 2=B 0=A?

  switch(g_model.protocol)
  {
    case PROTO_SILV_A: chan=0; break;
    case PROTO_SILV_B: chan=2; break;
    case PROTO_SILV_C: chan=1; break;
  }

  int8_t m1 = (uint16_t)(g_chans512[0]+512)*4 / 256;
  int8_t m2 = (uint16_t)(g_chans512[1]+512)*4 / 256;
  if (m1 < 0)    m1=0;
  if (m2 < 0)    m2=0;
  if (m1 > 15)   m1=15;
  if (m2 > 15)   m2=15;
  if (m2 > m1+9) m1=m2-9;
  if (m1 > m2+9) m2=m1-9;
  //uint8_t i=0;
  send_hilo_silv(5,1); //idx 0 erzeugt pegel=0 am Ausgang, wird  als high gesendet
  send2BitsSilv(0);
  send_hilo_silv(2,1);
  send_hilo_silv(2,1);

  send2BitsSilv(chan); //chan 1=C 2=B 0=A?
  uint8_t sum = 0 - chan;
  
  send2BitsSilv(m1>>2); //m1
  sum-=m1>>2;
  send2BitsSilv(m1);
  sum-=m1;

  send2BitsSilv(m2>>2); //m2
  sum-=m2>>2;
  send2BitsSilv(m2);
  sum-=m2;

  send2BitsSilv(sum); //chk

  // sendBitSilv(0);
  // send_hilo_silv(50,0); //low-impuls (pegel=1) ueberschreiben
  send_hilo_silv(1,50);


}



/*
http://www.sourcinggate.com/ctp-1009-metal-proportional-coaxial-electric-rc-helicopters-mode-p-6725.html
  TRACE CTP-1009  
   - = send 45MHz  
   _ = send nix
    start1       0      1           start2
  -------__     --_    -__         -----__
   7ms   2     .8 .4  .4 .8         5   2 

 frame:
  start1  24Bits_1  start2  24_Bits2 

 24Bits_1:
  7 x Bits  Throttle lsb first
  1 x 0

  6 x Bits  rotate lsb first
  1 x Bit   1=rechts
  1 x 0

  4 x Bits  chk5 = nib2 ^ nib4
  4 x Bits  chk6 = nib1 ^ nib3

 24Bits_2:
  7 x Bits  Vorwaets lsb first 0x3f = mid
  1 x 1

  7 x Bits  0x0e lsb first
  1 x 1

  4 x Bits  chk5 = nib2 ^ nib4
  4 x Bits  chk6 = nib1 ^ nib3

 */

#define BIT_TRA (400u*2)
void sendBitTra(uint8_t val)
{
  if(val) _send_hilo( BIT_TRA*1-1 , BIT_TRA*2-1 );
  else    _send_hilo( BIT_TRA*2-1 , BIT_TRA*1-1 );
}
void sendByteTra(uint8_t val)
{
  for(uint8_t i=0; i<8; i++, val>>=1) sendBitTra(val&1);
}
void setupPulsesTracerCtp1009()
{
  static bool phase;
  if( (phase=!phase) ){
    uint8_t thr = min(127u,(uint16_t)(g_chans512[0]+512+4) /  8u);
    uint8_t rot;
    if (g_chans512[1] >= 0)
    {
      rot = min(63u,(uint16_t)( g_chans512[1]+8) / 16u) | 0x40;
    }else{
      rot = min(63u,(uint16_t)(-g_chans512[1]+8) / 16u);
    }
    printf("thr %02x  rot %02x\n",thr,rot);
    sendByteTra(thr);
    sendByteTra(rot);
    uint8_t chk=thr^rot;
    sendByteTra( (chk>>4) | (chk<<4) );
    _send_hilo( 5000*2-1, 2000*2-1 );
  }else{
    uint8_t fwd = min(127u,(uint16_t)(g_chans512[2]+512) /  8u) | 0x80;
    printf("fwd %02x \n",fwd);
    sendByteTra(fwd);
    sendByteTra(0x8e);
    uint8_t chk=fwd^0x8e;
    sendByteTra( (chk>>4) | (chk<<4) );
    _send_hilo( 7000*2-1, 2000*2-1 );
  }
  //if((pulses2MHzPtr-pulses2MHz) >= (signed)DIM(pulses2MHz)) alert(PSTR("pulse tab overflow"));
}


//dsm2
//http://www.rcgroups.com/forums/showpost.php?p=18554028&postcount=237
///home/thus/txt/flieger/PPMtoDSM.c
/*
  125000 Baud 8n1      _ xxxx xxxx - ---
#define DSM2_CHANNELS      6                // Max number of DSM2 Channels transmitted
#define DSM2_BIT (8*2)  
bind:
  DSM2_Header = 0x80,0
static byte DSM2_Channel[DSM2_CHANNELS*2] = {
                ch
  0x00,0xAA,     0 0aa
  0x05,0xFF,     1 1ff
  0x09,0xFF,     2 1ff
  0x0D,0xFF,     3 1ff
  0x13,0x54,     4 354
  0x14,0xAA      5 0aa 
};

normal:
  DSM2_Header = 0,0;
  DSM2_Channel[i*2]   = (byte)(i<<2) | highByte(pulse);
  DSM2_Channel[i*2+1] = lowByte(pulse);


 */

#define BITLEN_DSM2 (8*2) //125000 Baud
void sendByteDsm2(uint8_t b) //max 10changes 0 10 10 10 10 1
{
  bool    lev = 0;
  uint8_t len = BITLEN_DSM2; //max val: 9*16 < 256
  for( uint8_t i=0; i<=8; i++){ //8Bits + Stop=1
    bool nlev = b & 0x80;
    if(lev == nlev){
      len += BITLEN_DSM2;
    }else{
      *pulses2MHzPtr++ = len -1;
      len  = BITLEN_DSM2;
      lev  = nlev;
    }
    b = (b<<1) + 1; //shift in stop bit
  }
  *pulses2MHzPtr++ = len + 10*BITLEN_DSM2 -1; //some more space-time for security
}


void setupPulsesDsm2()
{
  static uint8_t state = 0;

  ++state;
  if(state==1){
    //DSM2_Header = 0,0;
    sendByteDsm2(0);
    sendByteDsm2(0);
  }else if(state<=9){ //2..9
    uint8_t      i = state-2;
    uint16_t pulse = limit(0, g_chans512[i]+512,1023);
    sendByteDsm2((i<<2) | ((pulse>>8)&0x03));
    sendByteDsm2(pulse&0xff);
    if(state==9){
      pulses2MHzPtr[-1] += 20000u*2 -1;
      state = 0; 
    }
  }
}


// infrarot heli
// http://dangerousprototypes.com/forum/viewtopic.php?f=56&t=1822
/*
Example frame captured during the initial analysis. 
It begins with a preamble ( high level for 3,6ms then low level for 1ms),
then 32 data bits each taking 1ms and coded by pulse length 
"1" - 0,3ms high & 0,7ms low, a 
"0" - 0,7ms high & 0,3ms low). 
The last bit is the stop bit "1".

MSB transmitted first
--|--B3--------------
31| 0 fixed
30| MSB throttle
29| ...
28| ...
27| ...
26| ...
25| ...
24| LSB throttle
--|--B2--------------
23| MSB rudder
22| ...
21| ...
20| LSB rudder
19| MSB forward/backward
18| ...
17| ...
16| LSB forward/backward
--|--B1--------------
15| FLAG 1 - rudder left, 0 - rudder right
14| FLAG 1 - backward, 0 - forward
13| FLAG 1 - trim left, 0 - trim right
12| MSB trim
11| ...
10| ...
09| ...
08| LSB trim
--|--B0--------------
07| MSB CHANNEL, A - 11
06| LSB CHANNEL
05| MSB CRC
04| ...
03| ... CRC = (0x0F + B3 + B2 + B1) & 0x3F
02| ...
01| ...
00| LSB CRC
--|------------------
*/
void setupPulsesHeliIR()
{
}



//picco z
///home/thus/txt/flieger/protokolle/m168fb_ufo_v08/picooz.c
//
#define PICOOZ_IR_PERIODE (26*2)
#define PICOOZ_START_1900	 1900/PICOOZ_IR_PERIODE
#define PICOOZ_START_1226	 1226/PICOOZ_IR_PERIODE
#define PICOOZ_START_650	 650/PICOOZ_IR_PERIODE

#define PICOOZ_RC_HIGH	 1226/PICOOZ_IR_PERIODE
#define PICOOZ_RC_LOW	 650/PICOOZ_IR_PERIODE

#define PICOOZ_STOP	 650/PICOOZ_IR_PERIODE

void setupPulsesPiccoZ()
{
  //pulses2MHzPtr=pulses2MHz;
  //  int16_t direction = minmax(g_chans512[0]+512,-3,3);
  //  int16_t power     = minmax((g_chans512[1]+512)/(1024/8),0,7);
  //  int16_t trim      =  minmax(g_chans512[2]+512,0,2);
    
}






bool setupPulses() 
{
  pulses2MHzPtr = pulses2MHz;
  switch(g_model.protocol)
  {
    case PROTO_PPM:
      setupPulsesPPM();
      break;
    case PROTO_SILV_A:         // Achtung !! 0 am Ausgang = sendesignal high
    case PROTO_SILV_B:
    case PROTO_SILV_C:
      setupPulsesSilver();
      break;
    case PROTO_TRACER_CTP1009: // Achtung !! 0 am Ausgang = sendesignal high
      setupPulsesTracerCtp1009();
      break;
    case PROTO_SILV_PICCOZA:
    case PROTO_SILV_PICCOZB:
    case PROTO_SILV_PICCOZC:
      setupPulsesPiccoZ();
      break;
    case PROTO_HELI_IR:
      setupPulsesHeliIR();
      break;
    case PROTO_DSM2:
      setupPulsesDsm2();
      break;
  }
  uint16_t n=pulses2MHzPtr-pulses2MHz;
  if( n & 1 ) alert(PSTR("pulse tab odd length"));
  if( n >= DIM(pulses2MHz)) alert(PSTR("pulse tab overflow"));
  *pulses2MHzPtr = 0;
  return 0;
}








