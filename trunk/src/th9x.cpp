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

bugs:
+ bug mixer end
+ watchdog in write-file
+ freelist-bug   consequent chain-out,chain-in EeFsSetLink EeFsFree EeFsAlloc
- dont use trim-keys when re-sorting models 
+ save data befor load
+ menu-taste in mixer 
+ overflow in mixer
+ no-trim in pos-neg beruecksichtigen?
+ submenu in calib
+ timer_table progmem
todo
- prüfung des Schülersignals vor 
+ curves mit -100..100, cache
+ thr-warning
+ mode in general
+ key-beep off/ thr- switch- memory- warnings off
+ low memory alert
- format eeprom
- pcm 
- light auto off
- stat mit times
- fast multiply 8*16 > 32
+ doku einschaltverhalten, trainermode, curves  
- doku light-pin B7 pin17
done
+ timer with 0, timer beep stop
+ fast vline/hline
+ display modes graf/numeric.. in general
+ filesystem check
+ copy/del model
+ move file-based code from drivers.cpp to new file
+ switch handling: zwei varianten: ALTERNATIVE oder  ACTIVATE
+ delay algo rework delay 0???
+ 2-stuf mixer?, mixer with intermediates
+ 5-pkt-curve? curves 5+9
+ model with def 1 mixer
+ limit def==0
+ curves def==0
+ dynamisches eeprom/ free-anzeige/size anzeige bei models
+ curve+mode in einem parameter
+ curve modellspec
+ trim func as polynom
+ trainer persistent
+ move
+ silverlit
+ bat spanng. calib
+ timer stop/start mit switch
+ timer beep
+ pos-neg-abs, in mixer anzeigen
+ light schalten
+ vers num, date
+ exit fuer beenden von subsub..
+ INV as revert, - as don't cares
+ optimierte eeprom-writes
+ edit model name
+ menu lang reduzieren, seitl. move mit <->
+ limits
+ model  mode?  THR RUD ELE AIL
+ bug: ch1 verschwindet in mixall, csr laeuft hinter ch8 
+ expo dr algo
+ icons?
+ mix mit weight
+ delete line in mix
+ alphanum skip signs
+ plus-minus mixers mit flag
+ scr, dst je 4 bit 
+ src const 100
+ menus mit nummerierung 1/4 > m
+ trim mit >, <clear
+ mix mit kombizeile
+ negativ switches, constant switch, 
+ trim def algo
+ mixer algo
+ beep
+ vBat limit + warning
+ eeprom
+ trim val unit , hidden quadrat
+ mix list CH1 += LH +100  assym?
+ drSwitches als funktion
+ philosophie: Menuselect=Menu Lang,  Chain=Menu kurz, Pop=Exit kurz, Back=Exit Lang
+ model names
+ expo/dr exp1,exp2,dr-sw  3bytes
+ blink
+ switches as key
+ killEvents
+ calib menu
+ contrast
 */

#include "th9x.h"

/*
mode1 rud ele thr ail
mode2 rud thr ele ail
mode3 ail ele thr rud
mode4 ail thr ele rud
*/



EEGeneral g_eeGeneral;
ModelData g_model;




const prog_char APM modi12x3[]="RUDELETHRAILRUDTHRELEAILAILELETHRRUDAILTHRELERUD";


void putsTime(uint8_t x,uint8_t y,int16_t tme,uint8_t att,uint8_t att2)
{
  //uint8_t fw=FWNUM; //FW-1;
  //if(att&DBLSIZE) fw+=fw;
  
  lcd_putcAtt(   x,    y, tme<0 ?'-':' ',att);
  x += (att&DBLSIZE) ? FWNUM*5 : FWNUM*3+2;
  lcd_putcAtt(   x, y, ':',att);
  lcd_outdezNAtt(x, y, abs(tme)/60,LEADING0+att,2);
  x += (att&DBLSIZE) ? FWNUM*5-1 : FWNUM*4-2;
  lcd_outdezNAtt(x, y, abs(tme)%60,LEADING0+att2,2);
}
void putsVBat(uint8_t x,uint8_t y,uint8_t att)
{
  att |= g_vbat100mV < g_eeGeneral.vBatWarn ? BLINK : 0;
  lcd_putcAtt(   x+ 4*FW,   y,    'V',att);
  lcd_outdezAtt( x+ 4*FW,   y,    g_vbat100mV,att|PREC1);
}
void putsChnRaw(uint8_t x,uint8_t y,uint8_t idx1,uint8_t att)
{
  if((idx1>=1) && (idx1 <=4)) 
  {
    lcd_putsnAtt(x,y,modi12x3+g_eeGeneral.stickMode*12+3*(idx1-1),3,att);  
  }else{
    lcd_putsnAtt(x,y,PSTR(" P1 P2 P3MAXFUL X1 X2 X3 X4")+3*(idx1-5),3,att);
  }
}
void putsChn(uint8_t x,uint8_t y,uint8_t idx1,uint8_t att)
{
  // !! todo NUM_CHN !!
  lcd_putsnAtt(x,y,PSTR("   CH1CH2CH3CH4CH5CH6CH7CH8 X1 X2 X3 X4")+3*idx1,3,att);  
}


#define SWITCHES_STR "THR""RUD""ELE""ID0""ID1""ID2""AIL""GEA""TRN"


void putsDrSwitches(uint8_t x,uint8_t y,int8_t idx1,uint8_t att)//, bool nc)
{
  switch(idx1){
    case  0:            lcd_putsAtt(x+FW,y,PSTR("  -"),att);return; 
    case  MAX_DRSWITCH: lcd_putsAtt(x+FW,y,PSTR(" ON"),att);return; 
    case -MAX_DRSWITCH: lcd_putsAtt(x+FW,y,PSTR("OFF"),att);return; 
  }
  lcd_putcAtt(x,y, idx1<0 ? '!' : ' ',att);  
  lcd_putsnAtt(x+FW,y,PSTR(SWITCHES_STR)+3*(abs(idx1)-1),3,att);  
}
bool getSwitch(int8_t swtch, bool nc)
{
  switch(swtch){
    case  0:            return nc; 
    case  MAX_DRSWITCH: return true; 
    case -MAX_DRSWITCH: return false; 
  }
  if(swtch<0) return ! keyState((EnumKeys)(SW_BASE-swtch+1));
  return               keyState((EnumKeys)(SW_BASE+swtch-1));
}

void checkMem()
{
  if(! WARN_MEM) return;
  if(EeFsGetFree() < 200)  
  {
    alert(PSTR("EEPROM low mem"));
  }
  
}
void checkTHR()
{
  if(! WARN_THR) return;
  for(uint8_t i=0; i<20; i++) per10ms(); //read anas
  int thrchn=(2-(g_eeGeneral.stickMode&1));//stickMode=0123 -> thr=2121
  int16_t v= g_anaIns[thrchn];
  v -= g_eeGeneral.calibMid[thrchn];
  v  = v * (512/8) / (max(40,g_eeGeneral.calibSpan[thrchn]/8));

  if(v > -500)  
  {
    alert(PSTR("THR not idle"));
  }
}

void checkSwitches()
{
  if(! WARN_SW) return;
  uint8_t i;
  for(i=SW_BASE_DIAG; i< SW_Trainer; i++)
  {
    if(i==SW_ID0) continue;
    //if(getSwitch(i-SW_BASE,0)) break;
    if(keyState((EnumKeys)i)) break;
  }
  if(i==SW_Trainer) return;
  beepErr();
  pushMenu(menuProcDiagKeys);
}



MenuFuncP g_menuStack[5]
#ifdef SIM
 = {menuProc0};
#endif
;
uint8_t  g_menuStackPtr = 0;
// uint8_t  g_menuStackSub[5];
uint8_t  g_beepCnt;

void alert(const prog_char * s)
{
  lcd_clear();
  lcd_putsAtt(64-5*FW,0*FH,PSTR("ALERT"),DBLSIZE);  
  lcd_puts_P(0,4*FW,s);  
  lcd_puts_P(64-6*FW,7*FH,PSTR("press any Key"));  
  refreshDiplay();
  beepErr();
  //bool keyPressed=false;
  while(1)
  {
    if(IS_KEY_BREAK(getEvent()))   return;  //wait for key release
    //if(keyPressed){
    //  if((~PINB & 0x7e) == 0)   return;  //wait for key release
    //}else{
    //  if(~PINB & 0x7e)          keyPressed=true;
    //}
#ifdef SIM
void doFxEvents();
//printf("pinb %x\n",PINB);
    doFxEvents();
#endif    
  }
}
uint8_t checkTrim(uint8_t event)
{
  int8_t k = (event & EVT_KEY_MASK) - TRM_BASE;
  if((k>=0) && (k<8) && (event & _MSK_KEY_REPT))
  {
    //LH_DWN LH_UP LV_DWN LV_UP RV_DWN RV_UP RH_DWN RH_UP
    uint8_t idx = k/2;
    bool    up  = k&1;
    //if(idx==3) dwn=!dwn;
    if(!up){
      if(g_model.trimData[idx].trim > -31){
        g_model.trimData[idx].trim--;
        STORE_MODELVARS;
        beepKey();
      }
    }else{
      if(g_model.trimData[idx].trim < 31){
        g_model.trimData[idx].trim++;
        STORE_MODELVARS;
        beepKey();
      }
    }
    if(g_model.trimData[idx].trim==0) {
      killEvents(event);
      beepWarn();
    }
    return 0;
  }
  return event;
}


bool checkIncDecGen2(uint8_t event, void *i_pval, int16_t i_min, int16_t i_max, uint8_t i_flags)
{
  int16_t val = i_flags & _FL_SIZE2 ? *(int16_t*)i_pval : *(int8_t*)i_pval ;
  int16_t newval = val;
  if(i_flags&_FL_VERT)
    switch(event)
    {
      case  EVT_KEY_FIRST(KEY_UP):
      case  EVT_KEY_REPT(KEY_UP):    newval++; beepKey();     break;
      case  EVT_KEY_FIRST(KEY_DOWN):
      case  EVT_KEY_REPT(KEY_DOWN):  newval--; beepKey();     break;
    }
  else  
    switch(event)
    {
      case  EVT_KEY_FIRST(KEY_RIGHT):
      case  EVT_KEY_REPT(KEY_RIGHT): newval++; beepKey();     break;
      case  EVT_KEY_FIRST(KEY_LEFT):
      case  EVT_KEY_REPT(KEY_LEFT):  newval--; beepKey();     break;
    }

  if(newval>i_max)
  {
     newval = i_max;
     killEvents(event);
     beepWarn();
  }
  if(newval < i_min)
  {
     newval = i_min;
     killEvents(event);
     beepWarn();
  }
  if(newval != val){
    if(newval==0) {
      killEvents(event);
      beepWarn();
    }
    if(i_flags & _FL_SIZE2 ) *(int16_t*)i_pval = newval;
    else                     *( int8_t*)i_pval = newval;
    eeDirty(i_flags & (EE_GENERAL|EE_MODEL));
    return true;
  }
  return false;
}

int16_t checkIncDec_hm(uint8_t event, int16_t i_val, int16_t i_min, int16_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_SIZE2|EE_MODEL);
  return i_val;
}
int16_t checkIncDec_vm(uint8_t event, int16_t i_val, int16_t i_min, int16_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_SIZE2|_FL_VERT|EE_MODEL);
  return i_val;
}
int16_t checkIncDec_hg(uint8_t event, int16_t i_val, int16_t i_min, int16_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_SIZE2|EE_GENERAL);
  return i_val;
}
int16_t checkIncDec_vg(uint8_t event, int16_t i_val, int16_t i_min, int16_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_SIZE2|_FL_VERT|EE_GENERAL);
  return i_val;
}

uint8_t checkSubGen(uint8_t event,uint8_t num, uint8_t sub, bool vert)
{
  uint8_t subOld=sub;
  uint8_t inc = vert ?  KEY_DOWN : KEY_RIGHT;
  uint8_t dec = vert ?  KEY_UP   : KEY_LEFT;
  
  if(event==EVT_KEY_REPT(inc) || event==EVT_KEY_FIRST(inc))
  {
    beepKey();
    if(sub < (num-1)) {
      (sub)++;
    }else{
      if(event==EVT_KEY_REPT(inc))
      {
        beepWarn();
        killEvents(event);
      }else{
        (sub)=0;
      }
    }
  }
  else if(event==EVT_KEY_REPT(dec) || event==EVT_KEY_FIRST(dec))
  {
    beepKey();
    if(sub > 0) {
      (sub)--;
    }else{
      if(event==EVT_KEY_REPT(dec))
      {
        beepWarn();
        killEvents(event);
      }else{
        (sub)=(num-1);
      }
    }
  }
  else if(event==EVT_ENTRY)
  {
    sub = 0;
  }
  if(subOld!=sub) BLINK_SYNC;
  return sub;//false;
}
void popMenu(bool uppermost)
{
  if(g_menuStackPtr>0){
    g_menuStackPtr = uppermost ? 0 : g_menuStackPtr-1;
    beepKey();  
    (*g_menuStack[g_menuStackPtr])(EVT_ENTRY_UP);
  }else{
    alert(PSTR("menuStack underflow"));
  }
}
void chainMenu(MenuFuncP newMenu)
{
  g_menuStack[g_menuStackPtr] = newMenu;
  (*newMenu)(EVT_ENTRY);
  beepKey();
}
void pushMenu(MenuFuncP newMenu)
{
  g_menuStackPtr++;
  if(g_menuStackPtr >= DIM(g_menuStack))
  {
    g_menuStackPtr--;
    alert(PSTR("menuStack overflow"));
    return;
  }
  beepKey();
  g_menuStack[g_menuStackPtr] = newMenu;
  (*newMenu)(EVT_ENTRY);
}





void evalCaptures();

void perMain()
{
  perOut();
  eeCheck();
  //if(! g_menuStack[0]) g_menuStack[0] =  menuProc0;

  lcd_clear();
  uint8_t evt=getEvent();
  evt = checkTrim(evt);
  g_menuStack[g_menuStackPtr](evt);
  refreshDiplay();
  if(PING & (1<<INP_G_RF_POW)) { //no power -> only phone jack = slave mode
    PORTG &= ~(1<<OUT_G_SIM_CTL); // 0=ppm out
  }else{
    PORTG |=  (1<<OUT_G_SIM_CTL); // 1=ppm-in
#ifndef SIM
    evalCaptures();
#endif
  }
}
volatile uint16_t captureRing[16];
volatile uint8_t  captureWr;
volatile uint8_t  captureRd;
int16_t g_ppmIns[8];
uint8_t ppmInState; //0=unsync 1..8= wait for value i-1

#ifndef SIM
#include <avr/interrupt.h>
//#include <avr/wdt.h>
#define HEART_TIMER2Mhz 1;
#define HEART_TIMER10ms 2;

uint8_t heartbeat;

extern uint16_t g_tmr1Latency;
//ISR(TIMER1_OVF_vect)
ISR(TIMER1_COMPA_vect) //2MHz pulse generation
{
  static uint8_t   pulsePol;
  static uint16_t *pulsePtr = pulses2MHz;
  uint16_t dt=TCNT1;//-OCR1A;
  g_tmr1Latency = max(dt,g_tmr1Latency);

  if(pulsePol)
  {
    PORTB |=  (1<<OUT_B_PPM);
    pulsePol = 0;
  }else{
    PORTB &= ~(1<<OUT_B_PPM);
    pulsePol = 1;
  }

  OCR1A  = *pulsePtr++;

  if( *pulsePtr == 0) {
    //currpulse=0;
    pulsePtr = pulses2MHz;
    pulsePol = 0;

    TIMSK &= ~(1<<OCIE1A); //stop reentrance 
    sei();
    setupPulses();
    cli();
    TIMSK |= (1<<OCIE1A);
  }
  heartbeat |= HEART_TIMER2Mhz;
}

volatile uint8_t g_tmr16KHz;

ISR(TIMER0_OVF_vect) //continuous timer 16ms (16MHz/1024)
{
  g_tmr16KHz++;
}
uint16_t getTmr16KHz()
{
  while(1){
    uint8_t hb  = g_tmr16KHz;
    uint8_t lb  = TCNT0;
    if(hb-g_tmr16KHz==0) return (hb<<8)|lb;
  }
}
ISR(TIMER0_COMP_vect) //10ms timer
{
  TIMSK &= ~(1<<OCIE0); //stop reentrance 
  OCR0 = OCR0 + 156;
  sei();
  if(g_beepCnt){
    g_beepCnt--;
    PORTE |=  (1<<OUT_E_BUZZER);
  }else{
    PORTE &= ~(1<<OUT_E_BUZZER);
  }
  per10ms();
  cli();
  TIMSK |= (1<<OCIE0);
  heartbeat |= HEART_TIMER10ms;
}



ISR(TIMER3_CAPT_vect) //capture ppm in 16MHz / 8 = 2MHz
{
  uint16_t capture=ICR3;
  ETIMSK &= ~(1<<TICIE3); //stop reentrance 
  sei();
  
  static uint16_t lastCapt;
  uint8_t nWr = (captureWr+1) % DIM(captureRing);
  if(nWr == captureRd) //overflow
  {
    captureRing[(captureWr+DIM(captureRing)-1) % DIM(captureRing)] = 0; //distroy last value
    beepErr();
  }else{
    captureRing[captureWr] = capture - lastCapt;
    captureWr              = nWr;
  }
  lastCapt = capture;

  cli();
  ETIMSK |= (1<<TICIE3);
}

void evalCaptures()
{
  while(captureRd != captureWr)
  {
    uint16_t val = captureRing[captureRd] / 2; // us
    captureRd = (captureRd + 1)  % DIM(captureRing); //next read
    if(ppmInState && ppmInState<=8){
      if(val>800 && val <2200){
        g_ppmIns[ppmInState++ - 1] = val - 1500; //+-500 != 512, Fehler ignoriert
      }else{
        ppmInState=0; //not triggered
      }
    }else{
      if(val>4000 && val < 16000)
      {
        ppmInState=1; //triggered
      }
    }
  }
}


extern uint16_t g_timeMain;
int main()
{
  DDRA = 0xff;  PORTA = 0x00;
  DDRB = 0x81;  PORTB = 0x7e; //pullups keys+nc
  DDRC = 0x3e;  PORTC = 0xc1; //pullups nc
  DDRD = 0x00;  PORTD = 0xff; //pullups keys
  DDRE = 0x08;  PORTE = 0xff-(1<<OUT_E_BUZZER); //pullups + buzzer 0
  DDRF = 0x00;  PORTF = 0xff; //anain
  DDRG = 0x10;  PORTG = 0xff; //pullups + SIM_CTL=1 = phonejack = ppm_in
  lcd_init();

  // TCNT0         10ms = 16MHz/160000
  //TCCR0  = (1<<WGM01)|(7 << CS00);//  CTC mode, clk/1024
  TCCR0  = (7 << CS00);//  Norm mode, clk/1024
  OCR0   = 156;
  TIMSK |= (1<<OCIE0) |  (1<<TOIE0);

  // TCNT1 2MHz
  TCCR1A = (0<<WGM10);
  TCCR1B = (1 << WGM12) | (2<<CS10); // CTC OCR1A, 16MHz / 8
  TIMSK |= (1<<OCIE1A);
  //OCR1AH = (300*2-1)>>8;
  //OCR1AL = (300*2-1);

  TCCR3A  = 0;
  TCCR3B  = (1<<ICNC3) | (2<<CS30);      //ICNC3 16MHz / 8
  ETIMSK |= (1<<TICIE3);

  sei(); //damit alert in eeReadGeneral() nicht haengt
  g_menuStack[0] =  menuProc0;
  eeReadAll();

  uint16_t old10ms;
  checkMem();
  checkTHR();
  checkSwitches();
  setupPulses();
  wdt_enable(WDTO_500MS);
  while(1){
    old10ms=g_tmr10ms;
    uint16_t t0 = getTmr16KHz();
    perMain();
    t0 = getTmr16KHz() - t0;
    g_timeMain = max(g_timeMain,t0);
    while(g_tmr10ms==old10ms) sleep_mode();
    //while(g_tmr10ms==old10ms) sleep_mode();
    if(heartbeat == 0x3)
    {
      wdt_reset();
      heartbeat = 0;
    }
  }
}
#endif
