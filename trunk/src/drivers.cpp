/*
 * Author	Thomas Husterer <thus1@t-online.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 This file contains any code to immediatley access the hardware except 
 initialisation and interrupt handling (this is in th9x.cpp).

 */


#include "th9x.h"

#ifndef SIM
#include "avr/interrupt.h"

///opt/cross/avr/include/avr/eeprom.h
static inline void __attribute__ ((always_inline))
eeprom_write_byte_cmp (uint8_t dat, uint16_t pointer_eeprom)
{
  //see /home/thus/work/avr/avrsdk4/avr-libc-1.4.4/libc/misc/eeprom.S:98 143
  while(EECR & (1<<EEWE)) /* make sure EEPROM is ready */
    ;
  //EEARH = (uint8_t)(pointer_eeprom>>8);
  //EEARL = (uint8_t) pointer_eeprom;
  EEAR  = pointer_eeprom;

  EECR |= 1<<EERE;
  if(dat == EEDR) return;

  EEDR  = dat;
  uint8_t flags=SREG;
  cli();
  EECR |= 1<<EEMWE;
  EECR |= 1<<EEWE;
  SREG = flags;
}

void eeWriteBlockCmp(const void *i_pointer_ram, void *i_pointer_eeprom, size_t size)
{
  const char* pointer_ram = (const char*)i_pointer_ram;
  uint16_t    pointer_eeprom = (uint16_t)i_pointer_eeprom;
  while(size){
    eeprom_write_byte_cmp(*pointer_ram++,pointer_eeprom++);
    size--;
  }
}

uint16_t anaIn(uint8_t chan)
{
  ADMUX   = chan | (1<<REFS0);//0x40; 
  ADCSRA  = (1<<ADEN) | (4<<ADPS0); //0x80;
  //ADCSRA |= 1<<ADPS1; // /4
  ADCSRA |= 1<<ADSC;
  while(ADCSRA & (1<<ADSC));
  //return ADCL + (ADCH<<8);
  return ADC;
}

#endif




static uint8_t s_evt;
void putEvent(uint8_t evt)
{
  //#ifdef SIM
  //  printf("putEvent %d %x\n",evt,evt);
  //#endif
  s_evt = evt;
}
uint8_t getEvent()
{
  uint8_t evt = s_evt;
  s_evt=0;
  return evt;
}

class Key
{
#define FFVAL 0x0f
  uint8_t m_vals:4;
  uint8_t m_cnt;
public:
  void input(bool val, EnumKeys enuk);
  bool state();
  void killEvents();
};

Key keys[NUM_KEYS];
void Key::input(bool val, EnumKeys enuk)
{       
  //#ifdef SIM
  //  if(val) printf("Key::input = %d %d m_vals %d m_cnt%d\n",val,enuk,m_vals,m_cnt);
  //#endif
  uint8_t old=m_vals;
  m_vals <<= 1;
  if(val) m_vals |= 1;
  if(old!=m_vals){
    if(m_vals==0){  //break
      if(m_cnt<250) {
        //#ifdef SIM
        //        printf("m_cnt = %d\n",m_cnt);
        //#endif
        putEvent(EVT_KEY_GEN_BREAK(enuk));
      }
    }else if(m_vals==FFVAL){
      m_cnt=0;
    }     
  }
  if(m_vals==FFVAL)
  {
    m_cnt++;
    if(m_cnt>=250){
      m_cnt=250;
    }else if(m_cnt==1){ //1
      putEvent(EVT_KEY_FIRST(enuk));
    }else if(m_cnt==30){
      putEvent(EVT_KEY_LONG(enuk));
    }else if(m_cnt<=48){ //3
      if((m_cnt % 16) == 0)  putEvent(EVT_KEY_REPT(enuk));
    }else if(m_cnt<= 128){ //10
      if(((m_cnt-48) % 8) == 0)  putEvent(EVT_KEY_REPT(enuk));
    }else if(m_cnt<=208){ //20
      if(((m_cnt-128) % 4) == 0)  putEvent(EVT_KEY_REPT(enuk));
      if(m_cnt==208) m_cnt-=2;
    }
  }
  // #ifdef SIM
  //  printf("key %d=%x\n",enuk,m_vals);
  //#endif
}
void Key::killEvents()
{
  // #ifdef SIM
  //   printf("killEvents %d\n",m_cnt);
  // #endif
  m_cnt=250;
}
bool Key::state()
{
  return m_vals==FFVAL;
}

bool keyState(EnumKeys enuk)
{
  if(enuk < (int)DIM(keys))  return keys[enuk].state() ? 1 : 0;
  switch(enuk){
    //case SW_ID     : return PING & (1<<INP_G_ID1)    ? ( PINE & (1<<INP_E_ID2) ? 1 : 2) : 0;
    //case SW_NC     : return true;
    //case SW_ON     : return true;
    case SW_ElevDR : return PINE & (1<<INP_E_ElevDR);
    case SW_AileDR : return PINE & (1<<INP_E_AileDR);
    case SW_RuddDR : return PING & (1<<INP_G_RuddDR);
    case SW_ID0    : return !(PING & (1<<INP_G_ID1));
    case SW_ID1    : return (PING & (1<<INP_G_ID1))&& (PINE & (1<<INP_E_ID2));
    case SW_ID2    : return !(PINE & (1<<INP_E_ID2));
    case SW_Gear   : return PINE & (1<<INP_E_Gear);
    case SW_ThrCt  : return PINE & (1<<INP_E_ThrCt);
    case SW_Trainer: return PINE & (1<<INP_E_Trainer);
    default:;
  }
  return 0;
}

void killEvents(uint8_t event)
{
  event=event & EVT_KEY_MASK;
  if(event < (int)DIM(keys))  keys[event].killEvents();
}




uint16_t g_anaIns[8];
uint8_t  g_vbat100mV;
volatile uint16_t g_tmr10ms;
volatile uint8_t  g_blinkTmr10ms;

void per10ms()
{
  g_tmr10ms++;
  g_blinkTmr10ms++;
  uint8_t enuk = KEY_MENU;
  uint8_t    in = ~PINB;
  for(int i=1; i<7; i++)
  {
    //INP_B_KEY_MEN 1  .. INP_B_KEY_LFT 6
    keys[enuk].input(in & (1<<i),(EnumKeys)enuk);
    ++enuk;
  }
  static  prog_uchar  APM crossTrim[]={
    1<<INP_D_TRM_LH_DWN,
    1<<INP_D_TRM_LH_UP,
    1<<INP_D_TRM_LV_DWN,
    1<<INP_D_TRM_LV_UP,
    1<<INP_D_TRM_RV_DWN,
    1<<INP_D_TRM_RV_UP,
    1<<INP_D_TRM_RH_DWN,
    1<<INP_D_TRM_RH_UP
  };
  in = ~PIND;
  for(int i=0; i<8; i++)
  {
    // INP_D_TRM_RH_UP   0 .. INP_D_TRM_LH_UP   7
    keys[enuk].input(in & pgm_read_byte(crossTrim+i),(EnumKeys)enuk);
    ++enuk;
  }
  static prog_char APM crossAna[]={3,1,2,0,4,5,6,7};
  static uint16_t s_ana[8];
  for(int i=0; i<8; i++)
  {
    //chan=pgm_read_byte(cross+chan);
    //g_anaIns[i] = (g_anaIns[i]*7+anaIn(pgm_read_byte(crossAna+i))+4)/8;
    g_anaIns[i] = s_ana[i]/4;
    s_ana[i]   += anaIn(pgm_read_byte(crossAna+i)) - g_anaIns[i];

  }
  //14.2246465682983   -> 10.7 V  ((2.65+5.07)/2.65*5/1024)*1000  mV
  //0.142246465682983   -> 10.7 V  ((2.65+5.07)/2.65*5/1024)*10    1/10 V
  //0.137176291331963    k=((2.65+5.07)/2.65*5/1024)*10*9.74/10.1
  // g_vbat100mV=g_anaIns[7]*35/256; //34/239;
  // g_vbat100mV += g_vbat100mV*g_eeGeneral.vBatCalib/256;
  g_vbat100mV = (g_anaIns[7]*35+g_anaIns[7]/4*g_eeGeneral.vBatCalib) / 256; 

  static uint8_t s_batCheck;
  s_batCheck++;
  if(s_batCheck==0 && g_vbat100mV < g_eeGeneral.vBatWarn){
    beep();
  }
}
