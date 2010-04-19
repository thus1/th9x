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





static int16_t anaCalib[4];
static int16_t chans512[8];
//static TrainerData g_trainer;

//sticks
#include "sticks.lbm"
typedef PROGMEM void (*MenuFuncP_PROGMEM)(uint8_t event);

MenuFuncP_PROGMEM APM menuTabModel[] = {
  menuProcModelSelect,
  menuProcModel, 
  menuProcExpoAll, 
  menuProcTrim, 
  menuProcMix, 
  menuProcCurve,
  menuProcLimits
};

MenuFuncP_PROGMEM APM menuTabDiag[] = {
  menuProcSetup0,
  menuProcTrainer,
  menuProcDiagVers,
  menuProcDiagKeys, 
  menuProcDiagAna, 
  menuProcDiagCalib
};


struct MState
{
  uint8_t sVert;
  uint8_t sHorz;
  static uint8_t event;
  void init(){sVert=sHorz=0;};
  
  void checkExit(uint8_t event,int8_t exitMode=0);
  /// schltet horiz weiter zum naechsten menu. 
  /// entry    initialisiert, 
  /// key_exit schaltet in zwei stufen zurueck zuerst sub=0, dann popmenu
  void checkChain( uint8_t curr, MenuFuncP *menuTab, uint8_t size);
  /// schltet vertik weiter zum naechsten submenu. 
  /// entry    initialisiert, 
  /// keine reaktion auf exit
  uint8_t checkVert( uint8_t maxVert);
  /// schltet horiz weiter zum naechsten subsubmenu. 
  /// entry    initialisiert, 
  /// keine reaktion auf exit
  uint8_t checkHorz( uint8_t myVert, uint8_t maxHoriz);
};
uint8_t MState::event;
void MState::checkExit(uint8_t i_event,int8_t exitMode)
{
  event=i_event;
  if(event == EVT_ENTRY)  init();
  if(exitMode<0) return;
  if(event == EVT_KEY_FIRST(KEY_EXIT)){
    if(sVert==0 || exitMode)   popMenu();  
    else                        init();
  }
}

void MState::checkChain( uint8_t curr, MenuFuncP *menuTab, uint8_t size)
{
  uint8_t attr = INVERS; 
  curr--; //calc from 0, user counts from 1
  if(sVert==0){
    attr = BLINK;
    switch(event)
    {
      case EVT_KEY_FIRST(KEY_LEFT):
        if(curr>0){
          chainMenu((MenuFuncP)pgm_read_adr(&menuTab[curr-1]));
        }
        break;
      case EVT_KEY_FIRST(KEY_RIGHT):
        if(curr < (size-1)){
          chainMenu((MenuFuncP)pgm_read_adr(&menuTab[curr+1]));
        }
        break;
    }
  }
  lcd_putcAtt(128-FW*1,0,size+'0',attr);
  lcd_putcAtt(128-FW*2,0,'/',attr);
  lcd_putcAtt(128-FW*3,0,curr+'1',attr);
}
uint8_t MState::checkVert( uint8_t maxVert)
{
  if(sHorz==0)  sVert=checkSubGen(event, maxVert, sVert, true);
  return sVert;
}
uint8_t MState::checkHorz( uint8_t myVert, uint8_t maxHoriz)
{
  if(myVert==sVert)  sHorz=checkSubGen(event, maxHoriz, sHorz, false);
  return sHorz;
}

#ifdef SIM
extern char g_title[80];
MState mState;
#define TITLEP(pstr) lcd_putsAtt(0,0,pstr,INVERS);sprintf(g_title,"%s_%d_%d",pstr,mState.sVert,mState.sHorz);
#else
#define TITLEP(pstr) lcd_putsAtt(0,0,pstr,INVERS)  
#endif
#define TITLE(str)   TITLEP(PSTR(str))






static bool  s_limitCacheOk;
#define LIMITS_DIRTY s_limitCacheOk=false
void menuProcLimits(uint8_t event)
{
  static MState mState;
  TITLE("LIMITS");  
  mState.checkExit(event);
  mState.checkChain(7,menuTabModel,DIM(menuTabModel));
  int8_t sub = mState.checkVert(8+1) - 1;
  static uint8_t s_pgOfs;
  uint8_t subSub=0;
  if(sub>=0){
    LimitData *ld = &g_model.limitData[sub];
    subSub=mState.checkHorz(sub+1,4);
    switch(subSub)
    {
      case 1:
        ld->min -=  100;
        if(CHECK_INCDEC_V_MODELVAR( event, ld->min, -125,125))  LIMITS_DIRTY; 
        ld->min +=  100;
        break;
      case 2: 
        ld->max +=  100;
        if(CHECK_INCDEC_V_MODELVAR( event, ld->max, -125,125))  LIMITS_DIRTY; 
        ld->max -=  100;
        break;
      case 3: CHECK_INCDEC_V_MODELVAR( event, ld->revert,    0,1); 
        break;
    }
  }
  if(sub>4) s_pgOfs = 2;
  if(sub<3) s_pgOfs = 0;

  switch(event)
  {
    case EVT_ENTRY:
      s_pgOfs = 0;
      // subSub  = 0;
      break;
  }
  lcd_puts_P( 6*FW, 1*FH,PSTR("min  max  inv"));
  for(uint8_t i=0; i<6; i++){
    uint8_t y=(i+2)*FH;
    uint8_t k=i+s_pgOfs;
    LimitData *ld = &g_model.limitData[k];
    putsChn(0,y,k+1,(sub==k && subSub==0) ? INVERS : 0);
    lcd_outdezAtt(  9*FW, y, (int8_t)(ld->min-100),   (sub==k && subSub==1) ? BLINK : 0);
    lcd_outdezAtt( 14*FW, y, (int8_t)(ld->max+100),   (sub==k && subSub==2) ? BLINK : 0);
    lcd_putsnAtt(   15*FW, y, PSTR(" - INV")+ld->revert*3,3,(sub==k && subSub==3) ? BLINK : 0);
  }
}


static uint8_t s_curveChan;

void menuProcCurveOne(uint8_t event) {
  static MState mState;
  uint8_t x = TITLE("CURVE ");
  lcd_putcAtt(x, 0, s_curveChan + '1', INVERS);

  mState.checkExit(event, 1);
  int8_t sub = mState.checkVert(10);
  for (uint8_t i = 0; i < 5; i++) {
    uint8_t y = i * FH + 16;
    uint8_t attr = sub == i ? BLINK : 0;
    lcd_outdezAtt(4 * FW, y, (g_model.curves[s_curveChan][i] * 100) / 128, attr);
  }
  for (uint8_t i = 0; i < 4; i++) {
    uint8_t y = i * FH + 16;
    uint8_t attr = sub == i + 5 ? BLINK : 0;
    lcd_outdezAtt(8 * FW, y, (g_model.curves[s_curveChan][i + 5] * 100) / 128, attr);
  }
  lcd_putsAtt( 2*FW, 7*FH,PSTR("PRESET"),sub == 9 ? BLINK : 0);

  static int8_t dfltCrv;
  if(sub<9)  CHECK_INCDEC_H_MODELVAR( event, g_model.curves[s_curveChan][sub], -128,127);
  else {
    if( checkIncDecGen2(event, &dfltCrv, -4, 4, 0)){
      for (uint8_t i = 0; i < 9; i++) {
        g_model.curves[s_curveChan][i] = min((i-4)*dfltCrv*8,127);
      }
      eeDirty(EE_MODEL);
    }
  }

#define WCHART 32
#define X0     (128-WCHART-2)
#define Y0     32
#define RESX  512ul
#define RESK  100ul

  for (uint8_t xv = 0; xv < WCHART * 2; xv++) {
    uint16_t yv = intpol(xv * (RESX / WCHART) - RESX, s_curveChan) / (RESX
        / WCHART);
    lcd_plot(X0 + xv - WCHART, Y0 - yv);
    if ((xv & 3) == 0) {
      lcd_plot(X0 + xv - WCHART, Y0 + 0);
    }
  }
  lcd_vline(X0, Y0 - WCHART, WCHART * 2);
}

void menuProcCurve(uint8_t event) {
  static MState mState;
  TITLE("CURVE");
  mState.checkExit(event);
  mState.checkChain(6, menuTabModel, DIM(menuTabModel));
  int8_t sub = mState.checkVert(3 + 1) - 1;

  switch (event) {
  case EVT_KEY_FIRST(KEY_MENU):
    if (sub >= 0) {
      s_curveChan = sub;
      pushMenu(menuProcCurveOne);
    }
    break;
  }
  for (uint8_t i = 0; i < 3; i++) {
    uint8_t y    = i * 2 * FH + 16;
    uint8_t attr = sub == i ? BLINK : 0;
    lcd_putsAtt(   FW*0, y,PSTR("CV"),attr);
    lcd_outdezAtt( FW*3, y,i+1 ,attr);
    for (uint8_t j = 1; j < 10; j++) {
      lcd_outdezAtt( (j%5+1) *4 * FW, y+(j/5*FH), g_model.curves[i][j-1] * 100 / 128, 0);
    }
  }
}

static int8_t s_currMixIdx;
static int8_t s_currDestCh;
static bool   s_currMixInsMode;
void menuProcMixOne(uint8_t event)
{
  static MState mState;
  uint8_t x=TITLEP(s_currMixInsMode ? PSTR("INSERT MIX ") : PSTR("EDIT MIX "));  
  MixData *md2 = &g_model.mixData[s_currMixIdx];
  putsChn(x,0,md2->destCh,0);

  // int8_t sub=checkSub_v(event,5);
  mState.checkExit(event,1);
  int8_t sub = mState.checkVert(7);

#define CURV_STR " - x>0x<0|x|cv1cv2cv3"
  for(uint8_t i=0; i<=6; i++)
  {
    uint8_t y=i*FH+8;
    uint8_t attr = sub==i ? BLINK : 0; 
    lcd_putsn_P( FW*6, y,PSTR("SRC  PRC  CURVESWTCHSPEED          ")+5*i,5);
    switch(i){
      case 0:   putsChnRaw(   FW*2,y,md2->srcRaw,attr);         
        if(attr) md2->srcRaw = checkIncDec_hm( event, md2->srcRaw, 1,MAX_CHNRAW); //!! bitfield
        break;
      case 1:   lcd_outdezAtt(FW*5,y,md2->weight,attr);         
        if(attr) CHECK_INCDEC_H_MODELVAR( event, md2->weight, -125,125);
        break;
      case 2:   lcd_putsnAtt( FW*2,y,PSTR(CURV_STR)+md2->curve*3,3,attr);
        if(attr) md2->curve=checkIncDec_hm( event, md2->curve, 0,6); //!! bitfield
        if(attr && md2->curve>=4 && event==EVT_KEY_FIRST(KEY_MENU)){
          s_curveChan = md2->curve-4;
          pushMenu(menuProcCurveOne);
        }
        break;
      case 3:   putsDrSwitches(0,  y,md2->swtch,attr);
        if(attr) md2->swtch=checkIncDec_hm( event, md2->swtch, -MAX_DRSWITCH, MAX_DRSWITCH); //!! bitfield
        break;
      case 4:   lcd_outdezAtt(FW*3,y,md2->speedUp,attr);
        if(attr)  md2->speedUp=checkIncDec_hm( event, md2->speedUp, 0,15); //!! bitfield
        break;
      case 5:   lcd_outdezAtt(FW*5,y-FH,md2->speedDown,attr);
        if(attr)  md2->speedDown=checkIncDec_hm( event, md2->speedDown, 0,15); //!! bitfield
        break;
      case 6:   lcd_putsAtt(  FW*3,y,PSTR("RM"),attr);
                lcd_puts_P(  FW*6,y,PSTR("remove [Menu]"));
        if(attr && event==EVT_KEY_FIRST(KEY_MENU)){
          memmove(
            &g_model.mixData[s_currMixIdx],
            &g_model.mixData[s_currMixIdx+1],
            (MAX_MIXERS-(s_currMixIdx+1))*sizeof(MixData));
          memset(&g_model.mixData[MAX_MIXERS-1],0,sizeof(MixData));
          STORE_MODELVARS;
          popMenu();  
        }
        break;
    }
  }
}
//  i   destCh          ch1 
//                      ch2
//  0   3               ch3     info0        
//  1   3                       info1
//  2   5               ch4
//  3   0               ch5     info2
//  4   0               
//  5   0               
//


struct MixTab{
  bool   showCh:1;
  bool   hasDat:1;
  int8_t chId;    //:4  1..8             
  int8_t selCh;   //:5  1..MAX_MIXERS+8
  int8_t insIdx;  //:5  0..MAX_MIXERS-1

  int8_t selDat;  //:5  1..MAX_MIXERS+8
  int8_t editIdx;  //:5  0..MAX_MIXERS-1
} s_mixTab[MAX_MIXERS+8+1];
int8_t s_mixMaxSel;

void genMixTab()
{
  uint8_t maxDst  = 0;
  uint8_t mtIdx   = 0;
  uint8_t sel     = 1;
  memset(s_mixTab,0,sizeof(s_mixTab));

  MixData *md=g_model.mixData;

  for(uint8_t i=0; i<MAX_MIXERS; i++)
  {
    uint8_t destCh = md[i].destCh;
    if(destCh==0) destCh=8;
    if(destCh > maxDst){
      while(destCh > maxDst){ //ch-loop, hole alle channels auf
        maxDst++;
        s_mixTab[mtIdx].chId  = maxDst; //mark channel header
        s_mixTab[mtIdx].showCh = true;
        s_mixTab[mtIdx].selCh = sel++; //vorab vergeben, falls keine dat
        s_mixTab[mtIdx].insIdx= i;     //
        mtIdx++;
      }
      mtIdx--; //folding: letztes ch bekommt zusaetzlich dat
      s_mixMaxSel =sel;
      sel--; //letzte zeile hat dat, falls nicht ist selCh schon belegt
    }
    if(md[i].destCh==0) break;
    s_mixTab[mtIdx].chId    = destCh; //mark channel header
    s_mixTab[mtIdx].editIdx = i;
    s_mixTab[mtIdx].hasDat  = true;
    s_mixTab[mtIdx].selDat  = sel++;
    if(md[i].destCh == md[i+1].destCh){
      s_mixTab[mtIdx].selCh  = 0; //ueberschreibt letzte Zeile von ch-loop
      s_mixTab[mtIdx].insIdx = 0; //
    }
    else{
      s_mixTab[mtIdx].selCh  = sel++;
      s_mixTab[mtIdx].insIdx = i+1; //
    }
    s_mixMaxSel =sel;
    mtIdx++;
  }
}

void menuProcMix(uint8_t event)
{
  static MState mState;
  TITLE("MIXER");  
  mState.checkExit(event);
  mState.checkChain(5,menuTabModel,DIM(menuTabModel));
  int8_t sub = mState.checkVert(s_mixMaxSel);

  static uint8_t s_pgOfs;
  MixData *md=g_model.mixData;
  switch(event)
  {
    case EVT_ENTRY:
      s_pgOfs=0;
    case EVT_ENTRY_UP:
      genMixTab();
      break;
    case EVT_KEY_FIRST(KEY_MENU):
      if(sub<1) break;

      if(s_currMixInsMode) {
        memmove(&md[s_currMixIdx+1],&md[s_currMixIdx],
                (MAX_MIXERS-(s_currMixIdx+1))*sizeof(md[0]) );
        md[s_currMixIdx].destCh      = s_currDestCh; //-s_mixTab[sub];
        md[s_currMixIdx].srcRaw      = s_currDestCh; //1;   //
        md[s_currMixIdx].weight      = 100;
        md[s_currMixIdx].swtch       = 1; //on
        md[s_currMixIdx].curve      = 0; //linear
        md[s_currMixIdx].speedUp 		 = 0;         // Servogeschwindigkeit aus Tabelle (10ms Cycle)
        md[s_currMixIdx].speedDown 	 = 0;      // 0 nichts
        STORE_MODELVARS;
      }
      pushMenu(menuProcMixOne);
      break;
  }

  int8_t markedIdx=-1;
  uint8_t i;
  int8_t minSel=99;
  int8_t maxSel=-1;
  for(i=0; i<7; i++){
    uint8_t y = i * FH + FH;
    uint8_t k = i + s_pgOfs;
    if(!s_mixTab[k].showCh && !s_mixTab[k].hasDat ) break;

    if(s_mixTab[k].showCh){
      putsChn(0,y,s_mixTab[k].chId,0);
    }
    if(sub>0 && sub==s_mixTab[k].selCh) {
      if(BLINK_ON_PHASE) lcd_hline(0,y+7,FW*4);
      s_currMixIdx     = s_mixTab[k].insIdx;
      s_currDestCh     = s_mixTab[k].chId;
      s_currMixInsMode = true;
      markedIdx        = i;
      minSel = min(minSel,s_mixTab[k].selCh);
      maxSel = max(maxSel,s_mixTab[k].selCh);
    }
    if(s_mixTab[k].hasDat){
      MixData *md2=&md[s_mixTab[k].editIdx];
      uint8_t attr = sub==s_mixTab[k].selDat ? BLINK : 0; 
      minSel = min(minSel,s_mixTab[k].selDat);
      maxSel = max(maxSel,s_mixTab[k].selDat);
      lcd_outdezAtt(  8*FW, y, md2->weight,attr);
      lcd_putcAtt(    8*FW+1, y, '%',0);
      putsChnRaw(     10*FW-2, y, md2->srcRaw,0);
      putsDrSwitches( 14*FW-4, y, md2->swtch,0);
      lcd_putsnAtt(   18*FW+2, y, PSTR(CURV_STR)+md2->curve*3,3,0);
      if(attr == BLINK){
        CHECK_INCDEC_H_MODELVAR( event, md2->weight, -125,125);
        s_currMixIdx     = s_mixTab[k].editIdx;
        s_currDestCh     = s_mixTab[k].chId;
        s_currMixInsMode = false;
        markedIdx        = i;
      }
    }
  } //for 7
  if( sub!=0 &&  markedIdx==-1) {
#ifdef SIM
    printf("sub-1\n");
#endif
    if(sub < minSel) s_pgOfs = max(0,s_pgOfs-1);
    if(sub > maxSel) s_pgOfs++;
  }
  else if(markedIdx<=1)              s_pgOfs = max(0,s_pgOfs-1);
  else if(markedIdx>=5 && i>=7)      s_pgOfs++;
}



int16_t trimVal(uint8_t idx)
{
  int8_t trim = g_model.trimData[idx].trim;
  return trim*(abs(trim)+1)/2;
}

void menuProcTrim(uint8_t event)
{
  static MState mState;
  TITLE("TRIM");  
  mState.checkExit(event);
  mState.checkChain(4,menuTabModel,DIM(menuTabModel));
  int8_t sub = mState.checkVert(4+1)-1;

  switch(event)
  {
    case  EVT_KEY_FIRST(KEY_LEFT): 
    case  EVT_KEY_REPT(KEY_LEFT): 
      if(sub>=0)
      {
        g_model.trimData[sub].trimDef = 0;
        STORE_MODELVARS;
      }
      break;
    case  EVT_KEY_FIRST(KEY_RIGHT): 
    case  EVT_KEY_REPT(KEY_RIGHT): 
      if(sub>=0)
      {
        g_model.trimData[sub].trimDef += trimVal(sub);
        g_model.trimData[sub].trim     = 0;
        STORE_MODELVARS;
      }
      break;
  }
  lcd_puts_P( 6*FW, 1*FH,PSTR("Trim  Base"));
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=i*FH+16;
    uint8_t attr = sub==i ? BLINK : 0; 
    putsChnRaw(0,y,i+1,0);//attr);
    lcd_outdezAtt( 8*FW, y, trimVal(i), attr );
    lcd_outdezAtt(14*FW, y, g_model.trimData[i].trimDef, attr );
  }
  lcd_puts_P(0,FH*7,PSTR(" -> Balance  <- Clr"));  
}

uint16_t expou(uint16_t x, uint16_t k)
{
  // k*x*x*x + (1-k)*x
  return ((unsigned long)x*x*x/0x10000*k/(RESX*RESX/0x10000) + (RESK-k)*x+RESK/2)/RESK;
}
// expo-funktion:
// ---------------
// kmplot
// f(x,k)=exp(ln(x)*k/10) ;P[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
// f(x,k)=x*x*x*k/10 + x*(1-k/10) ;P[0,1,2,3,4,5,6,7,8,9,10]
// f(x,k)=x*x*k/10 + x*(1-k/10) ;P[0,1,2,3,4,5,6,7,8,9,10]
// f(x,k)=1+(x-1)*(x-1)*(x-1)*k/10 + (x-1)*(1-k/10) ;P[0,1,2,3,4,5,6,7,8,9,10]

int16_t expo(int16_t x, int16_t k)
{
  if(k == 0) return x;
  int16_t   y;
  bool    neg =  x < 0;
  if(neg)   x = -x;
  if(k<0){
    y = RESX-expou(RESX-x,-k);
  }else{
    y = expou(x,k);
  }
  return neg? -y:y;
}


#ifdef EXTENDED_EXPO
/// expo with y-offset
class Expo
{
  uint16_t   c;
  int16_t    d,drx;
public:
  void     init(uint8_t k, int8_t yo);
  static int16_t  expou(uint16_t x,uint16_t c, int16_t d);
  int16_t  expo(int16_t x);
};
void    Expo::init(uint8_t k, int8_t yo)
{
  c = (uint16_t) k  * 256 / 100;
  d = (int16_t)  yo * 256 / 100;
  drx = d * ((uint16_t)RESX/256);
}
int16_t Expo::expou(uint16_t x,uint16_t c, int16_t d)
{
  uint16_t a = 256 - c - d;
  if( (int16_t)a < 0 ) a = 0;
  // a x^3 + c x + d
  //                         9  18  27        11  20   18
  uint32_t res =  ((uint32_t)x * x * x / 0x10000 * a / (RESX*RESX/0x10000) +
                   (uint32_t)x                   * c
  ) / 256;
  return (int16_t)res;
}
int16_t  Expo::expo(int16_t x)
{
  if(c==256 && d==0) return x;
  if(x>=0) return expou(x,c,d) + drx;
  return -expou(-x,c,-d) + drx;
}
#endif

static uint8_t s_expoChan;

void menuProcExpoOne(uint8_t event)
{
  static MState mState;
  uint8_t x=TITLE("EXPO/DR ");  
  putsChnRaw(x,0,s_expoChan+1,0);
  mState.checkExit(event,1);
  int8_t sub = mState.checkVert(3);

  int8_t   kView  = 0;
  uint8_t  invBlk = 0;
  uint8_t  y = 16;

  if(sub==0){
    CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[s_expoChan].expNorm,-100, 100);

    invBlk = BLINK;
    kView =g_model.expoData[s_expoChan].expNorm;
  }
  lcd_puts_P(0,y,PSTR("Expo"));  
  lcd_outdezAtt(9*FW, y, g_model.expoData[s_expoChan].expNorm, invBlk);
  y+=FH;

  invBlk = 0;
  if(sub==1){
    CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[s_expoChan].expDr,-100, 100);
    invBlk = BLINK;
    kView  = g_model.expoData[s_expoChan].expDr;
  }
  lcd_puts_P(0,y,PSTR("DrExp"));  
  lcd_outdezAtt(9*FW, y, g_model.expoData[s_expoChan].expDr, invBlk);
  y+=FH;

  invBlk = 0;
  if(sub==2){
    CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[s_expoChan].drSw,0,MAX_DRSWITCH);
    invBlk = BLINK;
  }
  int8_t k= g_model.expoData[s_expoChan].drSw;
  lcd_puts_P(0,y,PSTR("DrSw"));  
  putsDrSwitches(4*FW,y,k,invBlk);
  y+=FH;

  
#define WCHART 32
#define X0     (128-WCHART-2)
#define Y0     32
  for(uint8_t xv=0;xv<WCHART;xv++)
  {
    uint16_t yv=expo(xv*(RESX/WCHART),kView) / (RESX/WCHART);
    lcd_plot(X0+xv, Y0-yv);
    lcd_plot(X0-xv, Y0+yv);
    if((xv&3) == 0){
      lcd_plot(X0+xv, Y0+0);
      lcd_plot(X0-xv, Y0+0);
      lcd_plot(X0  , Y0+xv);
      lcd_plot(X0  , Y0-xv);
    }
  }
  int16_t x512  = anaCalib[s_expoChan];
  int16_t y512  = expo(x512,kView);
  lcd_vline(X0+x512/(RESX/WCHART), Y0-WCHART,WCHART*2);
  lcd_hline(X0-WCHART,             Y0-y512/(RESX/WCHART),WCHART*2);
  lcd_outdezAtt( 19*FW, 6*FH,x512*25/((signed) RESX/4), 0 );
  lcd_outdezAtt( 14*FW, 1*FH,y512*25/((signed) RESX/4), 0 );
  //dy/dx
  
  int16_t dy  = x512>0 ? y512-expo(x512-20,kView) : expo(x512+20,kView)-y512;
  lcd_outdezNAtt(14*FW, 2*FH,   dy*(100/20), LEADING0|PREC2,3);
}
void menuProcExpoAll(uint8_t event)
{
  static MState mState;
  TITLE("EXPO/DR");  
  mState.checkExit(event);
  mState.checkChain(3,menuTabModel,DIM(menuTabModel));
  int8_t sub = mState.checkVert(4+1)-1;
  switch(event)
  {
    case EVT_KEY_FIRST(KEY_MENU):
      if(sub>=0){
        s_expoChan = sub;
        pushMenu(menuProcExpoOne);  
      }
      break;
  }

  lcd_puts_P( 6*FW, 1*FH,PSTR("Exp  DrSw DrExp"));
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=(i+2)*FH;
    putsChnRaw( 0, y,i+1,0);
    uint8_t invNorm = 0;
    uint8_t invDr   = 0;
    if(sub==i){
      //if(g_model.expoData[i].drSw && keyState((EnumKeys)(SW_BASE+g_model.expoData[i].drSw))){
      if( getSwitch(g_model.expoData[i].drSw,0)){
        CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[i].expDr,-100, 100);
        invDr = BLINK;
      }else{
        CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[i].expNorm,-100, 100);
        invNorm = BLINK;
      }
    }

    lcd_outdezAtt( 8*FW, y, g_model.expoData[i].expNorm,invNorm);
    if(g_model.expoData[i].drSw){
      putsDrSwitches( 10*FW, y, g_model.expoData[i].drSw,0);
      lcd_outdezAtt( 19*FW, y, g_model.expoData[i].expDr,invDr);
    }else{
      lcd_putc( 13*FW, y,'-');
    }
  }
}
const prog_char APM s_charTab[]=" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";
#define NUMCHARS (sizeof(s_charTab)-1)

uint8_t char2idx(char c)
{
  for(int8_t ret=0;;ret++)
  {
    char cc= pgm_read_byte(s_charTab+ret);
    if(cc==c) return ret;
    if(cc==0) return 0;
  }
}
char idx2char(uint8_t idx)
{
  if(idx < NUMCHARS) return pgm_read_byte(s_charTab+idx);
  return ' ';
}

void menuProcModel(uint8_t event)
{
  static MState mState;
  uint8_t x=TITLE("SETUP ");  
  lcd_outdezNAtt(x+2*FW,0,g_eeGeneral.currModel+1,INVERS+LEADING0,2); 
  mState.checkExit(event);
  mState.checkChain(2,menuTabModel,DIM(menuTabModel));
  int8_t  sub = mState.checkVert(4+1);
  uint8_t subSub;
  subSub = mState.checkHorz(1,1+sizeof(g_model.name));
  subSub = mState.checkHorz(3,4);

  lcd_putsAtt(    0,    2*FH, PSTR("Name"),sub==1 && subSub==0 ? BLINK:0);
  lcd_putsnAtt(   6*FW, 2*FH, g_model.name ,sizeof(g_model.name),BSS_NO_INV);

  lcd_putsAtt(    0,    3*FH, PSTR("Proto"),sub==2 ? INVERS:0);
  lcd_putsnAtt(   6*FW, 3*FH, PSTR(PROT_STR)+PROT_STR_LEN*g_model.protocol,PROT_STR_LEN,
                 (sub==2 ? BLINK:0));

  lcd_putsAtt(    0,    4*FH, PSTR("Timer"),sub==3 && subSub==0 ? BLINK:0);
  putsTime(       5*FW, 4*FH, g_model.tmrVal,
                  (sub==3 && subSub==1 ? BLINK:0),
                 (sub==3 && subSub==2 ? BLINK:0) );
  
  lcd_putsnAtt(  12*FW, 4*FH, PSTR(" OFF ABS THRTHR%")+4*g_model.tmrMode,4,
                 (sub==3 && subSub==3 ? BLINK:0));


  lcd_putsAtt( 0,    5*FH, PSTR("Mode"),sub==4?INVERS:0);
  lcd_putcAtt( 4*FW, 5*FH, '1'+g_model.stickMode,sub==4?INVERS:0);
  for(uint8_t i=0; i<4; i++)
  {
    lcd_img(    (6+4*i)*FW, (5)*FH, sticks,i,0);
    putsChnRaw( (6+4*i)*FW, (6)*FH,i+1,sub==4?BLINK:0);
  }

  switch(sub)
  {
    case 1:
      if(subSub) {
        char v = char2idx(g_model.name[subSub-1]);
        v = checkIncDec_vm( event,v ,0,NUMCHARS-1);
        v = idx2char(v);
        g_model.name[subSub-1]=v;
        lcd_putcAtt((6+subSub-1)*FW, 2*FH, v,BLINK);
      }
      break;
    case 2:
      CHECK_INCDEC_H_MODELVAR(event,g_model.protocol,0,PROT_MAX);
      break;
    case 3:
      switch(subSub) 
      {
        case 1:
          {
          int8_t min=g_model.tmrVal/60;
          min = checkIncDec_vm( event,min ,0,59);
          g_model.tmrVal = g_model.tmrVal%60 + min*60;
         break;
          }
        case 2:
          {
          int8_t sec=g_model.tmrVal%60;
          sec = checkIncDec_vm( event,sec ,-1,60);
          g_model.tmrVal += sec - g_model.tmrVal%60 ;
          break;
          }
        case 3:
          g_model.tmrMode = checkIncDec_vm( event,g_model.tmrMode ,0,3);
          break;

      }
      break;
    case 4:
      CHECK_INCDEC_H_MODELVAR(event,g_model.stickMode,0,3);
      break;
  }
}
void menuProcModelSelect(uint8_t event)
{
  static MState  mState;
  static uint8_t s_editMode;
  TITLE("MODELSEL");  
  lcd_puts_P(     10*FW, 0, PSTR("free"));
  lcd_outdezAtt(  18*FW, 0, EeFsGetFree(),0);
  //mState.event = event;
  //if(!s_editMode) 
  mState.checkExit(event,s_editMode ? -1 : 1); // EVT_ENTRY no KEY_EXIT -> init,popMenu
  //mState.sVert++; //trick, never 0 -> only print x/5
  //mState.checkChain(1,menuTabModel,DIM(menuTabModel));
  //mState.sVert--;
  lcd_putsAtt(128-FW*3,0,PSTR("1/7"),INVERS);

  int8_t sub = mState.sVert;
  int8_t subOld=sub;
  sub = mState.checkVert(MAX_MODELS);
  static uint8_t s_pgOfs;
  switch(event)
  {
    //case  EVT_KEY_FIRST(KEY_MENU):
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(s_editMode){
        s_editMode = false;
        break;
      }
    case  EVT_KEY_FIRST(KEY_RIGHT):
      if(g_eeGeneral.currModel != mState.sVert)
      {
        eeLoadModel(g_eeGeneral.currModel = mState.sVert);
        eeDirty(EE_GENERAL);
        LIMITS_DIRTY;
      }
      //case EXIT handled in checkExit
      if(event==EVT_KEY_FIRST(KEY_RIGHT))  chainMenu(menuProcModel);
      break;
    case  EVT_KEY_FIRST(KEY_MENU):
      s_editMode = true;
      break;

    case EVT_ENTRY:
      s_editMode = false;
      
      mState.sVert = g_eeGeneral.currModel;
      eeCheck(true); //force writing of current model data before this is changed
      break;
  }
  if(s_editMode && subOld!=sub){
    EFile::swap(FILE_MODEL(subOld),FILE_MODEL(sub));
  }

  if(sub-s_pgOfs < 1)        s_pgOfs = max(0,sub-1);
  else if(sub-s_pgOfs >4 )  s_pgOfs = min(MAX_MODELS-6,sub-4);
  for(uint8_t i=0; i<6; i++){
    uint8_t y=(i+2)*FH;
    uint8_t k=i+s_pgOfs;
    lcd_outdezNAtt(  2*FW, y, k+1, ((sub==k) ? (s_editMode ? INVERS : BLINK ) : 0) + LEADING0,2);
    static char buf[sizeof(g_model.name)+5];
    eeLoadModelName(k,buf,sizeof(buf));
    lcd_putsnAtt(  3*FW, y, buf,sizeof(buf),BSS_NO_INV|((sub==k) ? (s_editMode ? BLINK : 0 ) : 0));
  }

}



void menuProcDiagCalib(uint8_t event)
{
  static MState mState;
  TITLE("CALIB");
  mState.checkExit(event);
  mState.checkChain(6,menuTabDiag,DIM(menuTabDiag));
  mState.checkVert(5);
  int8_t sub = mState.sVert;
  static int16_t midVals[4];
  static int16_t lowVals[4];
  switch(event)
  {
    case EVT_KEY_FIRST(KEY_DOWN): // !! achtung sub schon umgesetzt
      switch(sub)
      {
        case 2: //get mid
          for(uint8_t i=0; i<4; i++)midVals[i] = g_anaIns[i];
          break;
        case 3: 
          for(uint8_t i=0; i<4; i++)lowVals[i] = g_anaIns[i];
          break;
        case 4: 
#ifdef SIM
          printf("do calib");
#endif
          int16_t sum=0;
          for(uint8_t i=0; i<4; i++){
            sum += g_eeGeneral.calibMid[i]  = midVals[i];
            int16_t    dv1 = abs(midVals[i]-lowVals[i]);
            int16_t    dv2 = abs(midVals[i]-(int16_t)g_anaIns[i]);
            sum += g_eeGeneral.calibSpan[i] = min(dv1,dv2);
          }
          g_eeGeneral.chkSum = sum;
          eeWriteGeneral();
          break;
      }
      break;
  }
  for(uint8_t i=1; i<5; i++)
  {
    uint8_t y=i*FH+FH;
    lcd_putsnAtt( 0, y,PSTR("SetMid SetLow SetHighReady  ")+7*(i-1),7,
                    sub==i ? BLINK : 0);
  }
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=i*FH+0;
    lcd_putsn_P( 8*FW,  y,      PSTR("A1A2A3A4")+2*i,2);  
    lcd_outhex4(12*FW,  y,      g_anaIns[i]);
    lcd_putsn_P( 8*FW,  y+4*FH, PSTR("C1C2C3C4")+2*i,2);  
    lcd_puts_P( 11*FW,  y+4*FH, PSTR("*    /"));  
    lcd_outhex4(12*FW,  y+4*FH, g_eeGeneral.calibMid[i]);
    lcd_outhex4(17*FW,  y+4*FH, g_eeGeneral.calibSpan[i]);
  }

}
void menuProcDiagAna(uint8_t event)
{
  static MState mState;
  TITLE("ANA");  
  mState.checkExit(event);
  mState.checkChain(5,menuTabDiag,DIM(menuTabDiag));
  mState.checkVert(2);
  int8_t sub = mState.sVert;

  for(uint8_t i=0; i<8; i++)
  {
    uint8_t y=i*FH;
    lcd_putsn_P( 4*FW, y,PSTR("A1A2A3A4A5A6A7A8")+2*i,2);  
    lcd_outhex4( 8*FW, y,g_anaIns[i]);
    if(i<4){
      int16_t v = g_anaIns[i];
      lcd_outdez(17*FW, y, (v-g_eeGeneral.calibMid[i])*50/ max(1,g_eeGeneral.calibSpan[i]/2));
    }
    if(i==7){
      putsVBat(13*FW,y,sub==1 ? BLINK : 0);
    }
  }
  if(sub==1){
   CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.vBatCalib, -127, 127);
  }

}

void menuProcDiagKeys(uint8_t event)
{
  static MState mState;
  TITLE("DIAG");  
  mState.checkExit(event);
  mState.checkChain(4,menuTabDiag,DIM(menuTabDiag));

  uint8_t x;

  x=7*FW;
  for(uint8_t i=0; i<9; i++)
  {
    uint8_t y=i*FH; //+FH;
    if(i>(SW_ID0-SW_BASE_DIAG)) y-=FH; //overwrite ID0
    bool t=keyState((EnumKeys)(SW_BASE_DIAG+i));
    putsDrSwitches(x-FW,y,i+2,0); //ohne off,on
    lcd_putcAtt(x+FW*4+2,  y,t+'0',t ? INVERS : 0);
  }

  x=0;
  for(uint8_t i=0; i<6; i++)
  {
    uint8_t y=(5-i)*FH+2*FH;
    bool t=keyState((EnumKeys)(KEY_MENU+i));
    lcd_putsn_P(x, y,PSTR(" Menu Exit Down   UpRight Left")+5*i,5);  
    lcd_putcAtt(x+FW*5+2,  y,t+'0',t);
  }


  x=14*FW;
  lcd_putsn_P(x, 3*FH,PSTR("Trim- +"),7);  
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=i*FH+FH*4;
    //lcd_putsn_P(x+7, y,PSTR("TR_LH-TR_LH+TR_LV-TR_LV+TR_RV-TR_RV+TR_RH-TR_RH+")+6*i,6);  
    lcd_img(    x,       y, sticks,i,0);
    bool tm=keyState((EnumKeys)(TRM_BASE+2*i));
    bool tp=keyState((EnumKeys)(TRM_BASE+2*i+1));
    lcd_putcAtt(x+FW*4,  y, tm+'0',tm ? INVERS : 0);
    lcd_putcAtt(x+FW*6,  y, tp+'0',tp ? INVERS : 0);
  }
}
void menuProcDiagVers(uint8_t event)
{
  static MState mState;
  TITLE("VERSION");
  mState.checkExit(event);
  mState.checkChain(3,menuTabDiag,DIM(menuTabDiag));

  lcd_puts_P(0, 2*FH,stamp1 ); 
  lcd_puts_P(0, 3*FH,stamp2 ); 
  lcd_puts_P(0, 4*FH,stamp3 ); 
}

void menuProcTrainer(uint8_t event)
{
  static MState mState;
  TITLE("TRAINER");  
  mState.checkExit(event);
  mState.checkChain(2,menuTabDiag,DIM(menuTabDiag));
  int8_t  sub = mState.checkVert(1+4+1)-1;
  uint8_t y;
  bool    edit;
  
  for(uint8_t i=0; i<4; i++){
    y=(i+2)*FH;
    TrainerData1*  td = &g_eeGeneral.trainer.chanMix[i];
    uint8_t subSub=0;
    if(sub==i){
      //subSub = mState.checkHorz(sub+1,5);
    }
    subSub = mState.checkHorz(i+1,5);
    putsChnRaw( 0, y,i+1,
                sub==i ? (subSub==0 ? BLINK : INVERS) : 0);
    edit = (sub==i && subSub==1);
    lcd_putsnAtt(   4*FW, y, PSTR("off += :=")+3*td->mode,3,
                    edit ? BLINK : 0);
    if(edit) td->mode = checkIncDec_vg( event, td->mode, 0,2); //!! bitfield

    edit = (sub==i && subSub==2);
    lcd_outdezAtt( 11*FW, y, td->weight*25/16,
                   edit ? BLINK : 0);
    if(edit) td->weight = checkIncDec_vg( event, td->weight, 0,63); //!! bitfield

    edit = (sub==i && subSub==3);
    lcd_putsnAtt(  12*FW, y, PSTR("ch1ch2ch3ch4")+3*td->srcChn,3, edit ? BLINK : 0);
    if(edit) td->srcChn = checkIncDec_vg( event, td->srcChn, 0,3); //!! bitfield

    edit = (sub==i && subSub==4);
    putsDrSwitches(16*FW, y, td->swtch, edit ? BLINK : 0);
    if(edit) td->swtch = checkIncDec_vg( event, td->swtch,  -MAX_DRSWITCH, MAX_DRSWITCH); //!! bitfield


  }
  edit = (sub==4);
  y    = 7*FH;
  lcd_putsnAtt(  0*FW, y, PSTR("Cal"),3,(sub==4) ? BLINK : 0);
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t x = (i*8+16)*FW/2;
    lcd_outdezAtt( x , y, (g_ppmIns[i]-g_eeGeneral.trainer.calib[i])*2,PREC1 );
  }
  if(edit)
  {
    if(event==EVT_KEY_FIRST(KEY_MENU)){
      memcpy(g_eeGeneral.trainer.calib,g_ppmIns,sizeof(g_eeGeneral.trainer.calib));
      eeDirty(EE_GENERAL);
    }
  }
  
}
void menuProcSetup0(uint8_t event)
{
  static MState mState;
  TITLE("SETUP BASIC");  
  mState.checkExit(event);
  mState.checkChain(1,menuTabDiag,DIM(menuTabDiag));
  int8_t sub = mState.checkVert(4)-1;
  uint8_t y=2*FH;
  lcd_outdezAtt(5*FW,y,g_eeGeneral.contrast,sub==0 ? BLINK : 0);
  if(sub==0){
    CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.contrast, 20, 45);
    lcdSetRefVolt(g_eeGeneral.contrast);
  }
  lcd_puts_P( 5*FW, y,PSTR("  CONTRAST"));
  y+=8;

  lcd_outdezAtt(5*FW,y,g_eeGeneral.vBatWarn,(sub==1 ? BLINK : 0)|PREC1);
  if(sub==1){
    CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.vBatWarn, 50, 100); //5-10V
  }
  lcd_puts_P( 5*FW, y,PSTR("V BAT WARNING"));
  y+=8;

  putsDrSwitches(0,y,g_eeGeneral.lightSw,sub==2 ? BLINK : 0);
  
  if(sub==2){
    CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.lightSw, -MAX_DRSWITCH, MAX_DRSWITCH); //5-10V
  }
  lcd_puts_P( 7*FW, y,PSTR("LIGHT"));
}

uint16_t s_timeCum16; //gewichtete laufzeit in 1/16 sec
void timer(uint8_t val)
{
  static uint16_t s_time;
  static uint16_t s_cnt;
  static uint16_t s_sum;
  s_cnt++;
  s_sum+=val;
  if((g_tmr10ms-s_time)<100) //10 sec
    return;
  s_time= g_tmr10ms;
  val   = s_sum/s_cnt;
  s_sum = 0;
  s_cnt = 0;

  switch(g_model.tmrMode)
  {
    case TMRMODE_NONE:
      return;
    case TMRMODE_THR_REL:
      s_timeCum16 += val/2;
      break;
    case TMRMODE_THR:     
      if(val) s_timeCum16 += 16;
      break;
    case TMRMODE_ABS:
      s_timeCum16 += 16;
      break;
  }
  int16_t tmr = g_model.tmrVal - s_timeCum16/16;
  if(tmr<=0) {
    static int16_t last_tmr;
    if(last_tmr != tmr){
      last_tmr = tmr;
      beep();
    }
  }

}
#define MAXTRACE 120
uint8_t s_traceBuf[MAXTRACE];
uint16_t s_traceWr;
uint16_t s_traceCnt;
void trace(uint8_t val)
{
  timer(val);
  static uint16_t s_time;
  static uint16_t s_cnt;
  static uint16_t s_sum;
  s_cnt++;
  s_sum+=val;
  if((g_tmr10ms-s_time)<1000) //10 sec
    return;
  s_time= g_tmr10ms;
  val   = s_sum/s_cnt;
  s_sum = 0;
  s_cnt = 0;


  s_traceCnt++;
  s_traceBuf[s_traceWr++] = val;
  if(s_traceWr>=MAXTRACE) s_traceWr=0;
}


uint16_t g_tmr1Latency;
uint16_t g_timeMain;
void menuProcStatistic2(uint8_t event)
{
  TITLE("STAT2");  
  switch(event)
  {
    case EVT_KEY_FIRST(KEY_MENU):
      g_tmr1Latency = 0;
      g_timeMain    = 0;
      break;
    case EVT_KEY_FIRST(KEY_DOWN):
      chainMenu(menuProcStatistic); 
      break;
    case EVT_KEY_FIRST(KEY_UP):
    case EVT_KEY_FIRST(KEY_EXIT):
      chainMenu(menuProc0); 
      break;
  }
  lcd_puts_P( 0*FW,  1*FH, PSTR("tmr1Lat      /2 us"));
  lcd_outdez(11*FW , 1*FH, g_tmr1Latency );
  lcd_puts_P( 0*FW,  2*FH, PSTR("tmain        /16 ms"));
  lcd_outdez(11*FW , 2*FH, g_timeMain );
}

void menuProcStatistic(uint8_t event)
{
  TITLE("STAT");  
  switch(event)
  {
    case EVT_KEY_FIRST(KEY_UP):
      chainMenu(menuProcStatistic2); 
      break;
    case EVT_KEY_FIRST(KEY_DOWN):
    case EVT_KEY_FIRST(KEY_EXIT):
      chainMenu(menuProc0); 
      break;
  }

  lcd_puts_P(  0*FW, FH*2, PSTR("TME"));
  putsTime(    4*FW, FH*2, s_timeCum16/16, 0, 0);


  uint16_t traceRd = s_traceCnt>MAXTRACE ? s_traceWr : 0;
  uint8_t x=5;
  uint8_t y=60;
  lcd_hline(x-3,y,120+3+3);
  lcd_vline(x,y-32,32+3);

  for(uint8_t i=0; i<120; i+=6)
  {
    lcd_vline(x+i+6,y-1,3);
  }
  for(uint8_t i=1; i<=120; i++)
  {
    lcd_vline(x+i,y-s_traceBuf[traceRd],s_traceBuf[traceRd]);
    traceRd++;
    if(traceRd>=MAXTRACE) traceRd=0;
    if(traceRd==s_traceWr) break;
  }

}

extern volatile uint16_t captureRing[16];


void menuProc0(uint8_t event)
{
#ifdef SIM
  sprintf(g_title,"M0");  
#endif
  static uint8_t sub;
  //sub = checkSubGen(event, 2, sub, false);
  switch(event)
  {
    case  EVT_KEY_LONG(KEY_MENU):
      switch(sub){
        case 0: 
          pushMenu(menuProcSetup0);
          break;
        case 1:
          pushMenu(menuProcModelSelect);//menuProcModel);
          break;
      }
      killEvents(event);
      break;
    case EVT_KEY_FIRST(KEY_RIGHT):
      if(sub<1) sub=sub+1;
      break;
    case EVT_KEY_LONG(KEY_RIGHT):
      pushMenu(menuProcModelSelect);//menuProcExpoAll); 
      killEvents(event);
      break;
    case EVT_KEY_FIRST(KEY_LEFT):
      if(sub>0) sub=sub-1;
      break;
    case EVT_KEY_LONG(KEY_LEFT):
      pushMenu(menuProcSetup0);
      killEvents(event);
      break;
    case EVT_KEY_LONG(KEY_UP):
      chainMenu(menuProcStatistic); 
      killEvents(event);
      break;
    case EVT_KEY_LONG(KEY_DOWN):
      chainMenu(menuProcStatistic2); 
      killEvents(event);
      break;
  }


  uint8_t x=FW*3;
  lcd_putsAtt(x,0,PSTR("Th9x"),sub==0 ? INVERS : 0);
  lcd_putsnAtt(x+ 5*FW,   0*FH, g_model.name ,sizeof(g_model.name),sub==1 ? BSS_INVERS : BSS_NO_INV);

  lcd_puts_P(  x+ 5*FW,   1*FH,    PSTR("BAT"));
  putsVBat(x+ 8*FW,1*FH,0);

  if(g_model.tmrMode != TMRMODE_NONE){
    int16_t tmr = g_model.tmrVal - s_timeCum16/16;
    lcd_puts_P(   x+ 5*FW, FH*2, PSTR("TME"));
    
    putsTime( x+9*FW, FH*2, tmr, 0, 0);
  }
  //trim sliders
  for(uint8_t i=0; i<4; i++)
  {
#define TL 27
    //                        LH LV RV RH
    static uint8_t x[4]    = {128*1/4+2, 4, 128-4, 128*3/4-2};
    static uint8_t vert[4] = {0,1,1,0};
    uint8_t xm,ym;
    xm=x[i];
    int8_t val = max((int8_t)-(TL+1),min((int8_t)(TL+1),g_model.trimData[i].trim));
    if(vert[i]){
      ym=31;
      lcd_vline(xm,   ym-TL, TL*2);
      lcd_vline(xm-1, ym-1,  3);
      lcd_vline(xm+1, ym-1,  3);
      //lcd_hline(xm-1, ym,     3);
      ym -= val;
    }else{
      ym=60;
      lcd_hline(xm-TL,ym,    TL*2);
      lcd_hline(xm-1, ym-1,  3);
      lcd_hline(xm-1, ym+1,  3);
      //lcd_vline(xm,   ym-1,     3);
      xm += val;
    }

    //value marker
#define MW 7
    lcd_vline(xm-MW/2,ym-MW/2,MW);
    lcd_hline(xm-MW/2,ym+MW/2,MW);
    lcd_vline(xm+MW/2,ym-MW/2,MW);
    lcd_hline(xm-MW/2,ym-MW/2,MW);
  }
  for(uint8_t i=0; i<8; i++)
  {
    uint8_t x = (i%4*9+3)*FW/2;
    uint8_t y = i/4*FH+40;
    // *1000/512 =   *2 - 24/512
    lcd_outdezAtt( x+4*FW , y, chans512[i]*2-chans512[i]/21,PREC1 );
    // lcd_outdezAtt( x+4*FW , y-2*FH, g_ppmIns[i]*2,PREC1 );
    // lcd_outdezAtt( x+4*FW , y, captureRing[i],PREC1 );
  }

}

static int16_t s_cacheLimitsMin[8];
static int16_t s_cacheLimitsMax[8];
void calcLimitCache()
{
  if(s_limitCacheOk) return;
#ifdef SIM
  printf("calc limit cache\n");
#endif  
  s_limitCacheOk = true;
  for(uint8_t i=0; i<8; i++){
    int16_t v = g_model.limitData[i].min-100;
    s_cacheLimitsMin[i] = 5*v + v/8 ; // *512/100 ~  *(5 1/8)
    v = g_model.limitData[i].max+100;
    s_cacheLimitsMax[i] = 5*v + v/8 ; // *512/100 ~  *(5 1/8)
  }
}

int16_t intpol(int16_t x, uint8_t idx) // -100, -75, -50, -25, 0 ,25 ,50, 75, 100
{
  int16_t erg;

  int16_t a = (x + RESX) / (RESX * 2 / 8);
  int8_t modu = (x + RESX) % (RESX * 2 / 8);
  if (a < 0)
    erg = g_model.curves[idx][0] * 4;
  else if (a >= 8)
    erg = g_model.curves[idx][8] * 4;
  else
    erg = (int16_t)g_model.curves[idx][a] * 4 + (int32_t)((int16_t)g_model.curves[idx][a + 1]
      * 4 - (int16_t)g_model.curves[idx][a] * 4) * modu / (RESX / 4);
  if (erg == RESX - 4) // Leichtes gemurkse, sieht aber im Ergebnis einfach besser aus
    erg = RESX;
  return erg;
}

//uint16_t pulses2MHz[9]={1200*2,1200*2,1200*2,1200*2,1200*2,1200*2,1200*2,1200*2,10500*2};
uint16_t pulses2MHz[60];

prog_uint8_t APM timer_table[] = {1,2,3,4,5,6,7,8,9,10,11,12};   // 15 - 3

void perOut()
{
  static int16_t anaNoTrim[8];
  static int16_t anas[8];

  for(uint8_t i=0;i<4;i++){        // calc Sticks

    //Normierung  [0..1024] ->   [-512..512]
    
    cli();
    int16_t v= g_anaIns[i];
    sei();
    v -= g_eeGeneral.calibMid[i];
    v  = v * ((signed)RESX/8) / (max(40,g_eeGeneral.calibSpan[i]/8));
    if(v <= -(signed)RESX) v = -(signed)RESX;
    if(v >= (signed) RESX) v =  (signed)RESX;
    anaCalib[i] = v; //for show in expo

    //expo  [-512..512]  9+1 Bit
    v  = expo(v,
              getSwitch(g_model.expoData[i].drSw,0) ?
              g_model.expoData[i].expDr           :
              g_model.expoData[i].expNorm
    );

    TrainerData1*  td = &g_eeGeneral.trainer.chanMix[i];
    if(td->mode && getSwitch(td->swtch,1)){
      uint8_t chStud = td->srcChn;
      int16_t vStud  = (g_ppmIns[chStud]- g_eeGeneral.trainer.calib[chStud])*
        td->weight/64;

      switch(td->mode)
      {
        case 1: v += vStud;   break; // add-mode
        case 2: v  = vStud;   break; // subst-mode
      }
    }

    //trace throttle
    if(((2-g_model.stickMode)&1) == i)  //stickMode=0123 -> thr=2121
      trace((v+512)/32); //trace thr 0..32

    anaNoTrim[i]  = v;
    //trim
    v += trimVal(i) + g_model.trimData[i].trimDef;
    anas[i] = v; //10+1 Bit
  }
  for(uint8_t i=4;i<7;i++){
    int16_t v= g_anaIns[i];
    anaNoTrim[i] = anas[i] = v-512; // [-512..511]
  }
  anaNoTrim[7] = anas[7] = 512; //100% für MAX
/* In anaNoTrim stehen jetzt die Werte ohne Trimmung implementiert -512..511
   in anas mit Trimmung */

  static int32_t chans[8];          // Ausgänge
  memset(chans,0,sizeof(chans));		// Alle Ausgänge auf 0

  //mixer loop
  for(uint8_t i=0;i<MAX_MIXERS;i++){
    MixData &md = g_model.mixData[i];

    static uint8_t timer[MAX_MIXERS];
    static int16_t act[MAX_MIXERS];


    if(md.destCh==0) break;

    //achtung 0=NC heisst switch nicht verwendet -> Zeile immer aktiv
    //if(!md.swtch) continue;     // 0 Zeile nicht verwendet
    int16_t v;
    if(md.curve){
      v = !getSwitch(md.swtch,1) ? 0 : anaNoTrim[md.srcRaw-1];
      switch(md.curve){
        case 1: if( v<0 ) v=0;   break;//x|x>0
        case 2: if( v>0 ) v=0;   break;//x|x<0
        case 3: v = abs(v);      break; //ABS
          //case 4: v = v==0 ? 0 : (v > 0 ? 512 : -512)  ; break; //ABS
        // Kurve soll erst nach Speed gerechnet werden
      }
    }
    else
      v = !getSwitch(md.swtch,1) ? 0 : anas[md.srcRaw-1];

    if (md.speedUp || md.speedDown)
    {
      if(v > act[i])            // hochzählen
      {
        if (md.speedUp > 2)
        {
          uint8_t timerend = timer_table[md.speedUp - 3];
          if (timer[i] != 0)
          {
            if (timer[i] > timerend)
              timer[i] = timerend;
            if (timer[i] > 0)
              --timer[i];
          }
          else
          {
            ++act[i];
            timer[i] = timerend;
          }
        }   //timer hier unten auch schreiben!!
        else if (md.speedUp > 0)        // 1 und 2
          act[i] += min(v - act[i], md.speedUp == 1 ? 5 : 3); // 5 200ms   // 3 333ms
        else
          act[i] = v;
      }
      else if (v < act[i])        // runterzählen
      {
         if (md.speedDown > 2)
         {
           uint8_t timerend = timer_table[md.speedDown - 3];
           if (timer[i] != 0)
           {
             if (timer[i] > timerend)
               timer[i] = timerend;
             if (timer[i] > 0)
               --timer[i];
           }
           else
           {
             --act[i];
             timer[i] = timerend;
           }
         }   //timer hier unten auch schreiben!!
         else if (md.speedDown > 0)
           act[i] += max(v - act[i], md.speedDown == 1 ? -5 : -3); // 5 200ms   // 3 333ms
         else
           act[i] = v;
      }
      v = act[i];
    }
    if((md.curve > 3) && (md.curve < 7))
      v = intpol(v, md.curve - 4);


    //    if (md.tableIdx)
    //      v = intpol(v, md.tableIdx - 1);

    int32_t dv=(int32_t)v*(md.weight); // 10+1 Bit + 7 = 17+1
    chans[md.destCh-1] += dv; //Mixerzeile zum Ausgang addieren (dv + (dv>0 ? 100/2 : -100/2))/(100);
  }

  //limit + revert loop
  calcLimitCache();
  for(uint8_t i=0;i<8;i++){
    int16_t v = (chans[i] + (chans[i]>0 ? 100/2 : -100/2)) / 100;

    v = max(s_cacheLimitsMin[i],v);
    v = min(s_cacheLimitsMax[i],v);
    if(g_model.limitData[i].revert) v=-v;

    cli();
    chans512[i] = v;
    sei();
  }

  if( getSwitch(g_eeGeneral.lightSw,1)) PORTB |=  (1<<OUT_B_LIGHT);
  else                                  PORTB &= ~(1<<OUT_B_LIGHT);

#ifdef xSIM
  setupPulses();
  static int s_cnt;
  if(s_cnt++%100==0){
    for(unsigned j=0; j<DIM(pulses2MHz); j++){
      printf(" %d:%d",j&1,pulses2MHz[j]);
      if(pulses2MHz[j]==0) break;
    }
    printf("\n\n");
  }
#endif

}
void setupPulses()
{
  switch(g_model.protocol)
  {
    case PROTO_PPM:
      setupPulsesPPM();
      break;
    case PROTO_SILV_A:
    case PROTO_SILV_B:
    case PROTO_SILV_C:
      setupPulsesSilver();
      break;
    case PROTO_TRACER_CTP1009:
      setupPulsesTracerCtp1009();
      break;
  }
}

void setupPulsesPPM()
{
  //http://www.aerodesign.de/peter/2000/PCM/frame_ppm.gif
  //22.5 ges   0.3low 8* (0.7-1.7 high 0.3low) high
  //uint16_t rest=22500u*2;
  uint16_t rest=22500u*2;
  uint8_t j=0;
  for(uint8_t i=0;i<8;i++){
    int16_t v = chans512[i];
    v = 2*v - v/21 + 1200*2; // 24/512 = 3/64 ~ 1/21
    rest-=v;//chans[i];
    pulses2MHz[j++]=300*2;
    pulses2MHz[j++]=v;
  }
  pulses2MHz[j++]=300*2;
  pulses2MHz[j++]=rest;
  pulses2MHz[j++]=0;

}


uint16_t *pulses2MHzPtr;
#define BITLEN (600u*2)
void _send_hilo(uint16_t hi,uint16_t lo)
{
  *pulses2MHzPtr++=hi; *pulses2MHzPtr++=lo;
}
#define send_hilo_silv( hi, lo) _send_hilo( (hi)*BITLEN,(lo)*BITLEN )

void sendBitSilv(uint8_t val)
{
  send_hilo_silv((val)?2:1,(val)?2:1);
}
void send2BitsSilv(uint8_t val)
{
  sendBitSilv(val&2);sendBitSilv(val&1);
}
// _ oder - je 0.6ms  (gemessen 0.7ms)
//
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
void setupPulsesSilver()
{
  int8_t chan=1; //chan 1=C 2=B 0=A?

  switch(g_model.protocol)
  {
    case PROTO_SILV_A: chan=0; break;
    case PROTO_SILV_B: chan=2; break;
    case PROTO_SILV_C: chan=1; break;
  }

  int8_t m1 = (uint16_t)(chans512[0]+512)*4 / 256;
  int8_t m2 = (uint16_t)(chans512[1]+512)*4 / 256;
  if (m1 < 0)    m1=0;
  if (m2 < 0)    m2=0;
  if (m1 > 15)   m1=15;
  if (m2 > 15)   m2=15;
  if (m2 > m1+9) m1=m2-9;
  if (m1 > m2+9) m2=m1-9;
  //uint8_t i=0;
  pulses2MHzPtr=pulses2MHz;
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

  sendBitSilv(0);
  pulses2MHzPtr--;
  send_hilo_silv(50,0); //low-impuls (pegel=1) ueberschreiben


}



/*
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
  if(val) _send_hilo( BIT_TRA*1 , BIT_TRA*2 );
  else    _send_hilo( BIT_TRA*2 , BIT_TRA*1 );
}
void sendByteTra(uint8_t val)
{
  for(uint8_t i=0; i<8; i++, val>>=1) sendBitTra(val&1);
}
void setupPulsesTracerCtp1009()
{
  pulses2MHzPtr=pulses2MHz;
  static bool phase;
  if( (phase=!phase) ){
    uint8_t thr = max(127u,(uint16_t)(chans512[0]+512+4) /  8u);
    uint8_t rot;
    if (chans512[1] >= 0)
    {
      rot = max(63u,(uint16_t)( chans512[1]+8) / 16u) | 0x40;
    }else{
      rot = max(63u,(uint16_t)(-chans512[1]+8) / 16u);
    }
    sendByteTra(thr);
    sendByteTra(rot);
    uint8_t chk=thr^rot;
    sendByteTra( (chk>>4) | (chk<<4) );
    _send_hilo( 5000*2, 2000*2 );
  }else{
    uint8_t fwd = max(127u,(uint16_t)(chans512[2]+512) /  8u) | 0x80;
    sendByteTra(fwd);
    sendByteTra(0x8e);
    uint8_t chk=fwd^0x8e;
    sendByteTra( (chk>>4) | (chk<<4) );
    _send_hilo( 7000*2, 2000*2 );
  }
  *pulses2MHzPtr++=0;
  if((pulses2MHzPtr-pulses2MHz) >= (signed)DIM(pulses2MHz)) alert(PSTR("pulse tab overflow"));
}

