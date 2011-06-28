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
+ contrast in alarm?
+ thr error wenn invert
+ trim entschaerfen i35,39
+ frame length 22.5 statt 25,2 i4,41
+ subtrim wenn invert i40
+ ad-conversion jitter
+ thr-error overflow
+ cv4 geht nicht
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
+ instant trim issue63 par:switch,t1,t2
- ensure load-save combi
- fast slopes after load
+ show foldedlist lines number
- show curves ref count, curve type
- issue 59 more output chans, soft switches
- outputs as inputs? calc sequence
- issue 57 chan recursion
- subtrim before limits? issue 61
+ dual rate interface issue62
- serial communication
- timer mit thr-switch
- standard mixer in slave mode (virtual model number?)
+ switch mode off -1 0 +1 
+ mixline mode + * =
+ chain src
+ potis FUL/HALF
+ trainer 1-8 as src 
+ neg curves,
- fast multiply 8*16 > 32
- format eeprom
- more curves with parameters?
- prc-werte dynamisch 64 werte 1-150
- curr event global var saves 340Bytes
- pcm 
doku
- doku switch select
- doku dblklick fast menu jump
- doku dblklick fast inc/dec
- doku subtrim
- doku light port/ prog beisp. delta/nuri, fahrwerk, sondercurves? /- _/
done
+ beep on list overflow
+ expo menu multiline
+ limit scaling/cutoff issue 55
+ timer beep mit vorwarnung issue 65
+ thr curve statt expo
+ thr trim nur am neg ende

+ vbat blinks issue 60
+ move,dup mixerlines/mixergroups
+ THR alarm off with throttle
+ speed-werte in sec
+ trim repeat slow
+ inc/dec nicevals with doubleclick
+ inc/dec repeat less fast
+ menunavigation ++
+ template type NONE
+ pruefung des Schuelersignals
+ file-version anzeige
+ light auto off
+ sim calib template
+ trainer slave activity sign
+ inactivity warning
+ pruefung des Schuelersignals
+ Pi mit switch full
+ alte standard kurven als defaults _/ /- \/ 
+ p1-3 calib 
+ autom switch erkennung bei betaetigung
+ trimbase entfernen
+ input invert für querruderdiff mit einer kurve
+ sonderfunc als 3pkt userfunc
+ default acro/heli120
+ trim ohne repeat (nur richtung null) i35,39
+ column select mit long click? 
+ trim -> limitoffset (subtrim)
+ select zero beep/store beep
+ no! select zero stop/ 2-stage mixer?
+ stat mit times
+ calibration pos + neg
+ more mixer ->25
+ standard curves after delay
+ negativ student weight
+ sinnvoller default 4ch
+ doku light-pin B7 pin17
+ dualrate expo+weight+differentialweight
+ limit + offset
+ curves mit -100..100, cache
+ thr-warning
+ mode in general
+ key-beep off/ thr- switch- memory- warnings off
+ low memory alert
+ doku einschaltverhalten, trainermode, curves  
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



EEGeneral_TOP g_eeGeneral;
ModelData_TOP g_model;
uint16_t       s_trainerLast10ms;
uint8_t        g_trainerSlaveActive;
uint16_t  g_badAdc,g_allAdc;
#ifdef WITH_ADC_STAT
uint16_t  g_rawVals[7];
uint8_t   g_rawPos;
uint8_t   g_rawChan;
#endif



const prog_char APM modn12x3[]=
  "\x0" "\x1" "\x2" "\x3"
  "\x0" "\x2" "\x1" "\x3"
  "\x3" "\x1" "\x2" "\x0"
  "\x3" "\x2" "\x1" "\x0";


uint8_t convertMode(uint8_t srcChn)
{
  if(srcChn>=4) return srcChn;
  return   pgm_read_byte(modn12x3+(uint8_t)(g_eeGeneral.stickMode*4+srcChn));
}


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
  //att |= g_vbat100mV < g_eeGeneral.vBatWarn ? BLINK : 0;
  lcd_putcAtt(   x+ 4*FW,   y,    'V',att);
  lcd_outdezAtt( x+ 4*FW,   y,    g_vbat100mV,att|PREC1);
}
void putsChnRaw(uint8_t x,uint8_t y,uint8_t idx1,uint8_t att)
{
  if((idx1 < NUM_XCHNRAW)) 
    //    lcd_putsmAtt(x,y,PSTR("RUD\t""ELE\t""THR\t""AIL\t"
    //                          " P1\t"" P2\t"" P3\t""MAX\t""FUL\t"
    //                          " X1\t"" X2\t"" X3\t"" X4"),idx1,att);
    lcd_putsmAtt(x,y,PSTR(SRC_STR),idx1,att);
}
void putsChn(uint8_t x,uint8_t y,uint8_t idx1,uint8_t att)
{
  // !! todo NUM_CHN !!
  lcd_putsnAtt(x,y,PSTR("   ""CH1""CH2""CH3""CH4""CH5""CH6""CH7""CH8"" X1"" X2"" X3"" X4")+3*idx1,3,att);  
}


#define SWITCHES_STR "THR""RUD""ELE""ID0""ID1""ID2""AIL""GEA""TRN"


void putsDrSwitches(uint8_t x,uint8_t y,int8_t idx1,uint8_t att)//, bool nc)
{
  switch(idx1){
    case  0:            lcd_putsAtt(x+FW,y,PSTR("   "),att);return; 
    case  MAX_DRSWITCH: lcd_putsAtt(x+FW,y,PSTR(" ON"),att);return; 
    case -MAX_DRSWITCH: lcd_putsAtt(x+FW,y,PSTR("OFF"),att);return; 
  }
  lcd_putcAtt(x+2,y, idx1<0 ? '!' : ' ',att);  
  lcd_putsnAtt(x+FW,y,PSTR(SWITCHES_STR)+3*(abs(idx1)-1),3,att);  
}
bool getSwitch(int8_t swtch, bool nc)
{
  switch(swtch){
    case  0:            return nc; 
    case  MAX_DRSWITCH: return true; 
    case -MAX_DRSWITCH: return false; 
  }
  if(swtch<0) return ! keyState((EnumKeys)(SW_BASE-swtch-1));
  return               keyState((EnumKeys)(SW_BASE+swtch-1));
}
uint8_t checkLastSwitch(uint8_t sw,uint8_t flg)
{
  static bool lastState[SW_Trainer-SW_BASE+1];
  uint8_t newSw = sw;
  for( uint8_t i=0; i< (SW_Trainer-SW_BASE+1); i++)
  {
    EnumKeys key = (EnumKeys)(i+SW_BASE);
    bool st= keyState(key);
    if(st != lastState[i]) {
      lastState[i] = st;
      if(key<SW_ID0 || key>SW_ID2 || st==true){
	newSw = i+1;
	if((flg&_FL_POSNEG) && !st) newSw=-newSw;
      }
    }
  }

  if(sw==newSw) return sw;
  if(flg&(EE_MODEL|EE_GENERAL)) eeDirty(flg&(EE_MODEL|EE_GENERAL));
  return newSw;
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


void checkMem()
{
  if(! WARN_MEM) return;
  if(EeFsGetFree() < 200)  
  {
    alert(PSTR("EEPROM low mem"));
  }
  
}
void setTHR0pos()
{
  g_eeGeneral.thr0pos = anaIn(THRCHN)>>6; //leave 4 bits
  eeDirty(EE_GENERAL);
}
void checkTHR()
{
  if(! WARN_THR) return;
#ifdef SIM
  for(uint8_t i=0; i<20; i++) per10ms(); //read anas
#else
  while(g_tmr10ms<20){} //wait for some ana in
#endif
  uint8_t mode=1;
  while(abs( (int8_t) ((anaIn(THRCHN)>>6)-g_eeGeneral.thr0pos) ) > 1)  
  {
    if(! alert(PSTR("THR not idle"),mode) ) break;
    mode=2;
  }
}



MenuFuncP g_menuStack[5];
uint8_t  g_menuStackPtr = 0;
//uint8_t  g_beepCnt;
//uint8_t  g_beepVal[4];

bool alert(const prog_char * s, uint8_t mode )
{
  if(mode<=1){
    lcd_clear();
    lcd_putsAtt(64-5*FW,0*FH,PSTR("ALERT"),DBLSIZE);  
    lcd_puts_P(0,4*FW,s);  
    lcd_puts_P(64-6*FW,7*FH,PSTR("press any Key"));  
    refreshDiplay();
    beepErr();
  }
  do {
    perChecks(); //check light switch in timerint, issue 51

    if(IS_KEY_BREAK(getEvent()))   return false;  //wait for key release
#ifdef SIM
void doFxEvents();
    doFxEvents();
#endif    
  } while(mode==0);
  return true;
}
uint8_t checkTrim(uint8_t event)
{
  int8_t k = (event & EVT_KEY_MASK) - TRM_BASE;
  if((k>=0) && (k<8) && IS_KEY_REPT(event))
  {
    //LH_DWN LH_UP LV_DWN LV_UP RV_DWN RV_UP RH_DWN RH_UP
    uint8_t idx = k/2;
    bool    up  = k&1;
    int8_t *ptrim = &g_model.trimData[convertMode(idx)].trim;
    if(up){
      //      if( (*ptrim < 0) ||
      //          ((*ptrim < 31) &&  IS_KEY_FIRST(event))  //issue 35, 39
      if(*ptrim >= 0){
        slowEvents(event);
      }
      if(*ptrim < 31){
        (*ptrim)++;
        STORE_MODELVARS;
        beepTrim();
      }
    }else{
      //if( (*ptrim > 0) ||
      //          ((*ptrim > -31) &&  IS_KEY_FIRST(event))
      if(*ptrim <= 0){
        slowEvents(event);
      }
      if(*ptrim > -31){
        (*ptrim)--;
        STORE_MODELVARS;
        beepTrim();
      }
    }
    if(*ptrim==0) {
      //killEvents(event);
      pauseEvents(event);
      beepWarn(); //mid trim value reached
    }
    return 0;
  }
  return event;
}

//global helper vars
bool    checkIncDec_Ret;

bool checkIncDecGen2(uint8_t event, void *i_pval, int16_t i_min, int16_t i_max, uint8_t i_flags)
{
  int16_t val = i_flags & _FL_SIZE2 ? *(int16_t*)i_pval : *(int8_t*)i_pval ;
  int16_t newval = val;
  uint8_t kpl=KEY_RIGHT, kmi=KEY_LEFT, kother = -1;

  if(i_flags&_FL_VERT){
    kpl=KEY_UP; kmi=KEY_DOWN;
  }
  //  kurz-lang-kombi plus
  if(event==EVT_KEY_LONG(kpl) && getEventDbl(event)==2){
    int niceVal=-150;
    while(1){
      if(newval < niceVal){
        newval = niceVal;
        break;
      }
      if(niceVal>=i_max) break;
      niceVal += 50;
    }
    killEvents(event);
    //  kurz-lang-kombi minus
  }else if(event==EVT_KEY_LONG(kmi) && getEventDbl(event)==2){
    int niceVal=150;
    while(1){
      if(newval > niceVal){
        newval = niceVal;
        break;
      }
      if(niceVal<=i_min) break;
      niceVal -= 50;
    }
    killEvents(event);
    //normal plus
  }else if(event==EVT_KEY_FIRST(kpl) || event== EVT_KEY_REPT(kpl)) {
    newval++; 
    kother=kmi;
    //normal minus
  }else if(event==EVT_KEY_FIRST(kmi) || event== EVT_KEY_REPT(kmi)) {
    newval--; 
    kother=kpl;
  }
  //gleichzeitig plus und minus
  if((kother != (uint8_t)-1) && keyState((EnumKeys)kother)){
    newval=-val;
    killEvents(kmi);
    killEvents(kpl);
  }

  if(newval != val) beepKey();     

  if(newval > i_max)
  {
    newval = i_max;
    killEvents(event);
    beepWarn(); //incdec max limit reached 
  }
  if(newval < i_min)
  {
    newval = i_min;
    killEvents(event);
    beepWarn(); //incdec min limit reached 
  }
  if(newval != val){
    if((newval%20)==0) {
      pauseEvents(event);
      beepKey(); //beepWarn();
    }
    if(i_flags & _FL_SIZE2 ) *(int16_t*)i_pval = newval;
    else                     *( int8_t*)i_pval = newval;
    eeDirty(i_flags & (EE_GENERAL|EE_MODEL));
    return checkIncDec_Ret=true;
  }
  return checkIncDec_Ret=false;
}

int8_t checkIncDec_hm(uint8_t event, int8_t i_val, int8_t i_min, int8_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,EE_MODEL);
  return i_val;
}
int8_t checkIncDec_vm(uint8_t event, int8_t i_val, int8_t i_min, int8_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_VERT|EE_MODEL);
  return i_val;
}
int8_t checkIncDec_hg(uint8_t event, int8_t i_val, int8_t i_min, int8_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,EE_GENERAL);
  return i_val;
}
int8_t checkIncDec_vg(uint8_t event, int8_t i_val, int8_t i_min, int8_t i_max)
{
  checkIncDecGen2(event,&i_val,i_min,i_max,_FL_VERT|EE_GENERAL);
  return i_val;
}


MenuFuncP lastPopMenu()
{
  return  g_menuStack[g_menuStackPtr+1];
}
void popMenu(bool uppermost)
{
  if(g_menuStackPtr>0){
    if(g_menuStack[g_menuStackPtr]) g_menuStack[g_menuStackPtr](EVT_EXIT);
    g_menuStackPtr = uppermost ? 0 : g_menuStackPtr-1;
    beepKey();  
    (*g_menuStack[g_menuStackPtr])(EVT_ENTRY_UP);
  }else{
    alert(PSTR("menuStack underflow"));
  }
}
void chainMenu(MenuFuncP newMenu)
{
  if(g_menuStack[g_menuStackPtr]) g_menuStack[g_menuStackPtr](EVT_EXIT);
  g_menuStack[g_menuStackPtr] = newMenu;
  (*newMenu)(EVT_ENTRY);
  beepKey();
}
void pushMenu(MenuFuncP newMenu)
{
  if(g_menuStack[g_menuStackPtr]) g_menuStack[g_menuStackPtr](EVT_EXIT);
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





uint8_t  g_vbat100mV;
void evalCaptures();
extern uint16_t g_timeMain;
extern uint16_t g_timePerOut;

void perMain()
{
  perChecks();
#ifndef SIM
  uint16_t t0 = getTmr16KHz();
#endif
  perOut(g_chans512);
#ifndef SIM
  t0 = getTmr16KHz() - t0;
  g_timePerOut = max(g_timePerOut,t0);
#endif
  eeCheck();

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
void   perChecks() //ca 10ms
{
  static uint8_t s_rnd;
  s_rnd++;
  switch( s_rnd & 0xf ) { //16*10ms = 160ms
    case 0:
      {
        static uint8_t  s_sumAnaLast;
        if( abs(g_sumAna - s_sumAnaLast) > 50)
        {
          s_sumAnaLast = g_sumAna;
          g_lightAct1s  = g_tmr1s; //retrigger light
          g_actTime1s  = g_tmr1s; //retrigger inativity alarm
        }
        if(g_eeGeneral.inactivityMin)
        {
          if((uint16_t)(g_tmr1s - g_actTime1s) > g_eeGeneral.inactivityMin*60u){
            beepWarn(); //inactivity warning
            g_actTime1s+=1;
          }
        }
      }
      break;
    case 1:
      {
        int8_t mins = g_eeGeneral.lightSw-MAX_DRSWITCH;
        if(mins <= 0){
          if( getSwitch(g_eeGeneral.lightSw,0)) PORTB |=  (1<<OUT_B_LIGHT);
          else                                  PORTB &= ~(1<<OUT_B_LIGHT);
        }else{
          if((g_tmr1s-g_lightAct1s) < (uint16_t)30*mins) {
            PORTB |=  (1<<OUT_B_LIGHT);
          }else{
            PORTB &= ~(1<<OUT_B_LIGHT);
            g_lightAct1s = g_tmr1s-30*mins;
          }
        }
        break;
      }
    case 2:
      {
//         static prog_uint8_t APM beepTab[]= {
//           0,0, 0,  0, //quiet
//           0,1,30,100, //silent
//           1,1,30,100, //normal
//           4,4,50,150, //for motor
//         };
//         memcpy_P(g_beepVal,beepTab+4*BEEP_VAL,4);
//           //g_beepVal = BEEP_VAL;
      }
      break;
    case 3:
      if((g_tmr10ms - s_trainerLast10ms) > 50 ){
        g_trainerSlaveActive = 0;
      }
      break;
    case 4:
      {
        static uint8_t s_batCheck;
        if(s_batCheck!=g_tmr1s && g_vbat100mV < g_eeGeneral.vBatWarn){
          beepBat();
          s_batCheck=g_tmr1s;
        }
      }
      break;
    case 15:
      switch( (s_rnd>>4) & 0xf ) { //256*10ms = 2.5s
        case 0: 
          {
            //check v-bat
            //14.2246465682983   -> 10.7 V  ((2.65+5.07)/2.65*5/1024)*1000  mV
            //0.142246465682983   -> 10.7 V  ((2.65+5.07)/2.65*5/1024)*10    1/10 V
            //0.137176291331963    k=((2.65+5.07)/2.65*5/1024)*10*9.74/10.1
            // g_vbat100mV=g_anaIns[7]*35/256; //34/239;
            // g_vbat100mV += g_vbat100mV*g_eeGeneral.vBatCalib/256;
            //g_vbat100mV = (g_anaIns[7]*35+g_anaIns[7]/4*g_eeGeneral.vBatCalib) / 256; 
            uint16_t ab = anaIn(7);
            g_vbat100mV = (ab*35 + ab / 4 * g_eeGeneral.vBatCalib) / 256; 
            break;
          }     
      } //2.5s
  } //160ms
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

extern uint16_t g_tmr1Latency_max;
extern uint16_t g_tmr1Latency_min;

//ISR(TIMER1_OVF_vect)
ISR(TIMER1_COMPA_vect) //2MHz pulse generation
{
  static uint8_t   pulsePol;
  static uint16_t *pulsePtr = pulses2MHz;

  uint8_t i = 0;
  while((TCNT1L < 10) && (++i < 50))  // Timer zu schnell auslesen funktioniert nicht, deshalb i
    ;
  uint16_t dt=TCNT1;//-OCR1A;

  if(pulsePol)
  {
    PORTB |=  (1<<OUT_B_PPM);
    pulsePol = 0;
  }else{
    PORTB &= ~(1<<OUT_B_PPM);
    pulsePol = 1;
  }
  g_tmr1Latency_max = max(dt,g_tmr1Latency_max);    // max hat Sprung, deshalb unterschiedlich lang
  g_tmr1Latency_min = min(dt,g_tmr1Latency_min);    // min hat Sprung, deshalb unterschiedlich lang

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

class AutoLock
{
  uint8_t m_saveFlags;
public:
  AutoLock(){
    m_saveFlags = SREG;
    cli();
  };
  ~AutoLock(){
    if(m_saveFlags & (1<<SREG_I)) sei();
    //SREG = m_saveFlags;// & (1<<SREG_I)) sei();
  };
};

#define STARTADCONV (ADCSRA  = (1<<ADEN) | (1<<ADPS0) | (1<<ADPS1) | (1<<ADPS2) | (1<<ADSC) | (1 << ADIE))
static uint16_t s_anaFilt[8];
uint16_t anaIn(uint8_t chan)
{
  //                     ana-in:   3 1 2 0 4 5 6 7          
  //static prog_char APM crossAna[]={4,2,3,1,5,6,7,0}; // wenn schon Tabelle, dann muss sich auch lohnen
  static prog_char APM crossAna[]={3,1,2,0,4,5,6,7};
  volatile uint16_t *p = &s_anaFilt[pgm_read_byte(crossAna+chan)];
  AutoLock autoLock;
  return *p;
}


ISR(ADC_vect, ISR_NOBLOCK)
{
  static uint16_t lastVal[8];
  static uint8_t  chan;
  //static uint16_t s_ana[8];
  static uint8_t s_filtBuf[8*4*2];

  ADCSRA  = 0; //reset adconv, 13>25 cycles

  // s_anaFilt[chan] = s_ana[chan] / 16;
  // s_ana[chan]    += ADC - s_anaFilt[chan]; //

  uint16_t v=ADC;
#ifdef WITH_ADC_STAT
  if(g_rawPos<DIM(g_rawVals)){
    if(chan==g_rawChan){ g_rawVals[g_rawPos++] = v;}
  }
#endif
  g_allAdc++;
  if( (v-lastVal[chan]+1)<=2 ){
    lastVal[chan]=v;
    
    uint16_t *filt = (uint16_t*)(s_filtBuf + (uint8_t)(chan*4*2));
    for(uint8_t i=g_eeGeneral.adcFilt; i>0; i--,filt++){
      uint16_t vn = *filt / 4; //0,16,23,28 vals to 99%
      *filt += v - vn; // *3/4
      v=vn;
    }
    asm("":::"memory"); //barrier saves 6 asm-instructions
    s_anaFilt[chan] = v;
    chan    = (chan + 1) & 0x7;
  }else{
    lastVal[chan]=v;
    g_badAdc++;
  }
  ADMUX   =  chan | (1<<REFS0);  // Multiplexer stellen
  STARTADCONV;                  //16MHz/128/25 = 5000 Conv/sec
}

void setupAdc(void)
{
  ADMUX = (1<<REFS0);      //start with ch0
  STARTADCONV;
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
    if((uint8_t)(hb-g_tmr16KHz)==0) return (hb<<8)|lb;
  }
}

ISR(TIMER0_COMP_vect, ISR_NOBLOCK) //10ms timer
{
  cli();
  TIMSK &= ~(1<<OCIE0); //stop reentrance 
  sei();
  OCR0 = OCR0 + 156;
  per10ms();
  heartbeat |= HEART_TIMER10ms;
  cli();
  TIMSK |= (1<<OCIE0);
  sei();
}



ISR(TIMER3_CAPT_vect, ISR_NOBLOCK) //capture ppm in 16MHz / 8 = 2MHz
{
  uint16_t capture=ICR3;
  cli();
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
  sei();
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
        if(ppmInState==8){
          s_trainerLast10ms = g_tmr10ms;
          g_trainerSlaveActive  = 1;
        }
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


#endif


int8_t idx2val15_100(int8_t idx)
{
  //ruby  -e 'x=0; [[10,50],[5,105]].each{|s,e| while x<e; print(" #{x}");x+=s; end }'
  // 0 10 20 30 40 50 55 60 65 70 75 80 85 90 95 100
  // idx  0  1       5      15
  // val  0 10 .10. 50 .5. 100
  uint8_t i   = abs(idx);
  uint8_t uval;
  if(i>=5)    uval = 5*(i+5); //
  else        uval = 10*i;
  return (idx < 0) ? -uval : uval;
}
int8_t val2idx15_100(int8_t val)
{
  // idx  0  1       5      15
  // val  0 10 .10. 50 .5. 100
  uint8_t uval = abs(val);
  uint8_t i;
  if(uval>50) i = (uint8_t)(uval)/5 -  5;
  else        i = (uint8_t)(uval)/10;
  return val < 0 ? -i : i;
}

int8_t idx2val30_100(int8_t idx)
{
  //ruby  -e 'x=0; [[1,2],[2,30],[5,105]].each{|s,e| while x<e; print(" #{x}");x+=s; end }'
  //0 1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100
  // idx  0 1 2     16      30
  // val  0 1 2 .2. 30 .5. 100
  uint8_t i   = abs(idx);
  uint8_t uval= i;
  if(i>=16){
    uval = 5*(i-10); //
  }else{
    if(i>2){
      uval = 2*(i-1);
    }    
  }
  return (idx < 0) ? -uval : uval;
}
int8_t val2idx30_100(int8_t val)
{
  // idx  0 1 2     16      30
  // val  0 1 2 .2. 30 .5. 100
  uint8_t uval = abs(val);
  uint8_t i;
  if(uval>30)      i = (uint8_t)(uval)/5 + 10;
  else if(uval>2)  i = (uint8_t)(uval)/2 +  1;
  else             i = uval;
  return val < 0 ? -i : i;
}
int16_t idx2val50_150(int8_t idx)
{
  //ruby  -e 'x=0; [[1,10],[2,50],[5,155]].each{|s,e| while x<e; print(" #{x}");x+=s; end }'
  //0 1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150
  // idx  0  10  30   50
  // val  0  10  50  150
  uint8_t i   = abs(idx);
  uint8_t uval= i;
  if(i>10){
    if(i<=30) uval = 2*(i-5); // (i-10)*2 + 10
    else      uval = 5*(i-20);             // (i-30)*5 + 50
  }
  return (idx < 0) ? -uval : uval;
}
int8_t val2idx50_150(int16_t val)
{
  uint8_t uval = val < 0 ? (uint8_t)-val : val;
  int8_t  i;
  if(uval>50)      i = (uint8_t)(uval-50)/5 + 30;
  else if(uval>10) i = (uint8_t)(uval+10)/2;
  else             i = uval;
  return val < 0 ? -i : i;
}


void init() //common init for simu and target
{
  //g_menuStack[0] =  menuProc0;

  eeReadAll(); //load general setup and selected model
#ifndef SIM
  lcdSetRefVolt(g_eeGeneral.contrast);
  setupAdc();  //before checkTHR
#endif
  chainMenu(menuProc0); //call evt_entry
  checkMem();  //enough eeprom free? 
  checkTHR();
  checkSwitches(); //must be last
}

#ifndef SIM
//void main(void) __attribute__((noreturn));
int main(void)
{
  DDRA = 0xff;  PORTA = 0x00;
  DDRB = 0x81;  PORTB = 0x7e; //pullups keys+nc
  DDRC = 0x3e;  PORTC = 0xc1; //pullups nc
  DDRD = 0x00;  PORTD = 0xff; //pullups keys
  DDRE = 0x08;  PORTE = 0xff-(1<<OUT_E_BUZZER); //pullups + buzzer 0
  DDRF = 0x00;  PORTF = 0xff; //anain
  DDRG = 0x10;  PORTG = 0xff; //pullups + SIM_CTL=1 = phonejack = ppm_in
  lcd_init();

  // TCNT0         10ms = 16MHz/160000  periodic timer
  //TCCR0  = (1<<WGM01)|(7 << CS00);//  CTC mode, clk/1024
  TCCR0  = (7 << CS00);//  Norm mode, clk/1024
  OCR0   = 156;
  TIMSK |= (1<<OCIE0) |  (1<<TOIE0);

  // TCNT1 2MHz Pulse generator
  TCCR1A = (0<<WGM10);
  TCCR1B = (1 << WGM12) | (2<<CS10); // CTC OCR1A, 16MHz / 8
  //TIMSK |= (1<<OCIE1A); enable immediately before mainloop

  TCCR3A  = 0;
  TCCR3B  = (1<<ICNC3) | (2<<CS30);      //ICNC3 16MHz / 8
  ETIMSK |= (1<<TICIE3);

  sei(); //damit alert in eeReadGeneral() nicht haengt

  init();

  setupPulses();
  wdt_enable(WDTO_500MS);
  TIMSK |= (1<<OCIE1A); // Pulse generator enable immediately before mainloop
  while(1){
    uint16_t old10ms=g_tmr10ms;
    uint16_t t0 = getTmr16KHz();
    perMain();
    t0 = getTmr16KHz() - t0;
    g_timeMain = max(g_timeMain,t0);
    while(g_tmr10ms==old10ms) sleep_mode();
    if(heartbeat == 0x3)
    {
      wdt_reset();
      heartbeat = 0;
    }
  }
}
#endif
