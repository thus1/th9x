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

int8_t add7Bit(int8_t a,int8_t b){ 
  a  = (a+b) & 0x7f;
  if(a & 0x40) a|=0x80;
  return a;
}
int16_t lim2val(int8_t limidx,int8_t dlt){ 
  return idx2val12255(add7Bit(limidx,dlt));
}


uint16_t slopeFull100ms(uint8_t speed);

static int16_t anaCalib[4];
int16_t g_chans512[NUM_CHNOUT];
uint8_t g_sumAna;
//static TrainerData g_trainer;

//sticks
#include "sticks.lbm"
typedef PROGMEM void (*MenuFuncP_PROGMEM)(uint8_t event);

MenuFuncP_PROGMEM APM menuTabModel[] = {
  menuProcModelSelect,
  menuProcModel, 
  menuProcExpoAll, 
  menuProcMix, 
  menuProcTrim, 
  menuProcLimits,
  menuProcCurve
};

MenuFuncP_PROGMEM APM menuTabDiag[] = {
  menuProcSetup0,
  menuProcSetup1,
  menuProcTrainer,
  menuProcDiagVers,
  menuProcDiagKeys, 
  menuProcDiagAna, 
  menuProcDiagCalib
};

//#define PARR8(args...) (__extension__({static prog_uint8_t APM __c[] = args;&__c[0];}))
struct MState2
{
  uint8_t m_posVert;
  uint8_t m_posHorz;
  //void init(){m_posVert=m_posHorz=0;};
  void init(){m_posVert=0;};
  prog_uint8_t *m_tab;
  static uint8_t event;
  void check_v(uint8_t event,  uint8_t curr,MenuFuncP *menuTab, uint8_t menuTabSize, uint8_t maxrow);
  void check(uint8_t event,  uint8_t curr,MenuFuncP *menuTab, uint8_t menuTabSize, prog_int8_t*subTab,uint8_t subTabMax,uint8_t maxrow);
};
#define MSTATE_TAB  static prog_int8_t APM mstate_tab[]
#define MSTATE_CHECK0_VxH(numRows) mstate2.check(event,0,0,0,mstate_tab,DIM(mstate_tab)-1,numRows-1)
#define MSTATE_CHECK0_V(numRows) mstate2.check_v(event,0,0,0,numRows-1)
#define MSTATE_CHECK_VxH(curr,menuTab,numRows) mstate2.check(event,curr,menuTab,DIM(menuTab),mstate_tab,DIM(mstate_tab)-1,numRows-1)
#define MSTATE_CHECK_V(curr,menuTab,numRows) mstate2.check_v(event,curr,menuTab,DIM(menuTab),numRows-1)

void MState2::check_v(uint8_t event,  uint8_t curr,MenuFuncP *menuTab, uint8_t menuTabSize, uint8_t maxrow)
{
  check( event,  curr, menuTab, menuTabSize, 0, 0, maxrow);
}
void MState2::check(uint8_t event,  uint8_t curr,MenuFuncP *menuTab, uint8_t menuTabSize, prog_int8_t*horTab,uint8_t horTabMax,uint8_t maxrow)
{
  if(menuTab){
    uint8_t attr = INVERS; 
    curr--; //calc from 0, user counts from 1

    if(m_posVert==0){
      attr = BLINK;
      switch(event)
      {
        case EVT_KEY_FIRST(KEY_LEFT):
          if(curr>0){
            chainMenu((MenuFuncP)pgm_read_adr(&menuTab[curr-1]));
          }
          break;
        case EVT_KEY_FIRST(KEY_RIGHT):
          if(curr < (menuTabSize-1)){
            chainMenu((MenuFuncP)pgm_read_adr(&menuTab[curr+1]));
          }
          break;
      }
    }
    lcd_putcAtt(128-FW*1,0,menuTabSize+'0',attr);
    lcd_putcAtt(128-FW*2,0,'/',attr);
    lcd_putcAtt(128-FW*3,0,curr+'1',attr);
  }

#define INC(val,max) if(val<max) {val++;} else {val=0;}
#define DEC(val,max) if(val>0  ) {val--;} else {val=max;}
  switch(event) {
    case EVT_ENTRY:
      //if(m_posVert>maxrow) 
      checkLastSwitch(0,0);
      m_posVert=0;
      //init();BLINK_SYNC;
      break;
    case EVT_KEY_LONG(KEY_EXIT):
      popMenu(true); //return to uppermost, beeps itself
      break;
    case EVT_KEY_BREAK(KEY_EXIT):
      if(m_posVert==0 || !menuTab) {
        popMenu();  //beeps itself
      } else {
        beepKey();  
        init();BLINK_SYNC;
      }
      break;
  }
  if(horTab){
#define NUMCOL(row) (int8_t)pgm_read_byte(horTab+min( row, horTabMax ))
    bool    horzCsr = NUMCOL(m_posVert) < 0;
    uint8_t maxcol  = horzCsr ? -NUMCOL(m_posVert) : NUMCOL(m_posVert)-1;
    switch(event) {
      case EVT_KEY_BREAK(KEY_DOWN): //inc vert
        if(!horzCsr || m_posHorz==0){
          INC(m_posVert,maxrow);
          if(NUMCOL(m_posVert)<0){
            m_posHorz=0; //auf kopfelement setzen, damit vert navigierbar
          }else{
            m_posHorz=min(m_posHorz,(uint8_t)(NUMCOL(m_posVert)-1));
          }
        }
        BLINK_SYNC; 
        break;
      case EVT_KEY_BREAK(KEY_UP):   //dec vert
        if(!horzCsr || m_posHorz==0){
          DEC(m_posVert,maxrow);
          if(NUMCOL(m_posVert)<0){
            m_posHorz=0; //auf kopfelement setzen, damit vert navigierbar
          }else{
            m_posHorz=min(m_posHorz,(uint8_t)(NUMCOL(m_posVert)-1));
          }
        }
        BLINK_SYNC;
        break;
      case EVT_KEY_LONG(KEY_DOWN):  //inc horz
        if(horzCsr) break;
        killEvents(event);
        INC(m_posHorz,maxcol);
        BLINK_SYNC; 
        break;
      case EVT_KEY_LONG(KEY_UP):   //dec horz
        if(horzCsr) break;
        killEvents(event);
        DEC(m_posHorz,maxcol);
        BLINK_SYNC;
        break;
      case EVT_KEY_BREAK(KEY_RIGHT):  //inc horz
        if(!horzCsr) break;
        //killEvents(event);
        INC(m_posHorz,maxcol);
        BLINK_SYNC; 
        break;
      case EVT_KEY_BREAK(KEY_LEFT):   //dec horz
        if(!horzCsr) break;
        //killEvents(event);
        DEC(m_posHorz,maxcol);
        BLINK_SYNC;
        break;
    }}else switch(event) { //no horTab
    case EVT_KEY_REPT(KEY_DOWN):  //inc vert
      if(m_posVert==maxrow) break;
    case EVT_KEY_FIRST(KEY_DOWN): //inc
      //if(horTab)break;
      INC(m_posVert,maxrow);
      BLINK_SYNC;
      break;

    case EVT_KEY_REPT(KEY_UP):  //dec vert
      if(m_posVert==0) break;
    case EVT_KEY_FIRST(KEY_UP): //dec
      //if(horTab)break;
      DEC(m_posVert,maxrow);
      BLINK_SYNC;
      break;
  }
}


#ifdef SIM
extern char g_title[80];
MState2 mstate2;
#define TITLEP(pstr) lcd_putsAtt(0,0,pstr,INVERS);sprintf(g_title,"%s_%d_%d",pstr,mstate2.m_posVert,mstate2.m_posHorz);
#else
#define TITLEP(pstr) lcd_putsAtt(0,0,pstr,INVERS)  
#endif
#define TITLE(str)   TITLEP(PSTR(str))






static uint8_t s_curveChan;

uint8_t curveTyp(uint8_t idx)
{
  if(idx<3) return 3;
  if(idx<5) return 5;
  return 9;
}
int8_t* curveTab(uint8_t idx)
{
  if(idx<3) return g_model.curves3[idx];
  if(idx<5) return g_model.curves5[idx-3];
  return           g_model.curves9[idx-5];
}

void menuProcCurveOne(uint8_t event) {
  static MState2 mstate2;
  uint8_t x = TITLE("CURVE ");
  lcd_putcAtt(x, 0, s_curveChan + '1', INVERS);

/*  bool    cv9 = s_curveChan >= 2;
  MSTATE_CHECK0_V((cv9 ? 9 : 5)+1);*/
  uint8_t cvTyp=curveTyp(s_curveChan);
  int8_t *crv = curveTab(s_curveChan);//cv9 ? g_model.curves9[s_curveChan-2] : g_model.curves5[s_curveChan];
  MSTATE_CHECK0_V(cvTyp+1);

  int8_t  sub    = mstate2.m_posVert;


  for (uint8_t i = 0; i < min(cvTyp,(uint8_t)5); i++) {
    uint8_t y = i * FH + 16;
    uint8_t attr = sub == i ? BLINK : 0;
    lcd_outdezAtt(4 * FW, y, crv[i], attr);
  }
  if(cvTyp==9)
    for (uint8_t i = 0; i < 4; i++) {
      uint8_t y = i * FH + 16;
      uint8_t attr = sub == i + 5 ? BLINK : 0;
      lcd_outdezAtt(8 * FW, y, crv[i + 5], attr);
    }
  lcd_putsAtt( 2*FW, 7*FH,PSTR("PRESET"),sub == cvTyp ? BLINK : 0);

  static int8_t dfltCrv;
  if(sub<cvTyp)  CHECK_INCDEC_H_MODELVAR( event, crv[sub], -100,100);
  else {
    if( checkIncDecGen2(event, &dfltCrv, -10, 10, 0)){
      for (uint8_t i = 0; i < 5; i++) {
        int8_t pos=0,neg=0;
        switch(abs(dfltCrv)){
          case 0: break;
          case 1: 
          case 2: 
          case 3: 
          case 4: neg = -25*abs(dfltCrv)*i/4;  pos=-neg;  break;
          case 5: neg =  50-25*i/2  ; pos =    100-neg;   break;
          case 6:                     pos =       25*i   ;break;
          case 7: neg =      -25*i  ;                     break;
          case 8: neg =       25*i  ; pos =       25*i   ;break;
          case 9: neg = -100        ; pos = -100+ 50*i   ;break;
         case 10: neg = +100 -50*i  ; pos = +100         ;break;
        }
        if(dfltCrv<0) {neg=-neg;pos=-pos;}
        switch(cvTyp){ 
          case 9:                crv[4-i] = neg; crv[4+i] = pos;  break;
          case 5: if(i%2) break; crv[2-i/2] = neg; crv[2+i/2] = pos;  break;
          case 3: if(i%4) break; crv[1-i/4] = neg; crv[1+i/4] = pos;  break;
        }
      }
      eeDirty(EE_MODEL);
    }
    //    if( checkIncDecGen2(event, &dfltCrv, -4, 4, 0)){
    //  switch(cvTyp){ 
    //case 9: for (uint8_t i = 0; i < 9; i++) crv[i] = (i-4)*dfltCrv* 100 / 16; break;
    //	case 5: for (uint8_t i = 0; i < 5; i++) crv[i] = (i-2)*dfltCrv* 100 /  8; break;
    //	case 3: for (uint8_t i = 0; i < 3; i++) crv[i] = (i-1)*dfltCrv* 100 /  4; break;
    //      }
    //      eeDirty(EE_MODEL);
    //    }
  }

#define WCHART 32
#define X0     (128-WCHART-2)
#define Y0     32
#define RESX    512
#define RESXu   512u
#define RESXul  512ul
#define RESKul  100ul

  for (uint8_t xv = 0; xv < WCHART * 2; xv++) {
    uint16_t yv = intpol(xv * (RESXu / WCHART) - RESXu, s_curveChan) / 
      (RESXu / WCHART);
    if((int16_t)yv<-31) yv=-31;
    lcd_plot(X0 + xv - WCHART, Y0 - yv);
    if ((xv & 3) == 0) {
      lcd_plot(X0 + xv - WCHART, Y0 + 0);
    }
  }
  lcd_vline(X0, Y0 - WCHART, WCHART * 2);
}

void menuProcCurve(uint8_t event) {
  static MState2 mstate2;
  TITLE("CURVE");
  MSTATE_CHECK_V(7,menuTabModel,7+1);
  int8_t  sub    = mstate2.m_posVert - 1;

  switch (event) {
  case EVT_KEY_FIRST(KEY_MENU):
    if (sub >= 0) {
      s_curveChan = sub;
      pushMenu(menuProcCurveOne);
    }
    break;
  }
  uint8_t y    = 1*FH;
  for (uint8_t i = 0; i < 7; i++) {
    uint8_t attr = sub == i ? BLINK : 0;
    lcd_putsAtt(   FW*0, y,PSTR("CV"),attr);
    lcd_outdezAtt( FW*3, y,i+1 ,attr);

  uint8_t cvTyp=curveTyp(i);
  int8_t *crv = curveTab(i);
  //  bool    cv9 = i >= 2;
  //  int8_t *crv = cv9 ? g_model.curves9[i-2] : g_model.curves5[i];
    for (uint8_t j = 0; j < min(cvTyp,(uint8_t)5); j++) {
      lcd_outdezAtt( j*(3*FW+3) + 7*FW, y, crv[j], 0);
    }
    y += FH;
/*    if(cv9){
      for (uint8_t j = 0; j < 4; j++) {
        lcd_outdezAtt( j*(3*FW+3) + 7*FW, y, crv[j+5], 0);
      }
      y += FH;
    }*/
  }
}

static bool  s_limitCacheOk;
#define LIMITS_DIRTY s_limitCacheOk=false
void menuProcLimits(uint8_t event)
{
  static MState2 mstate2;
  TITLE("LIMITS");  
  MSTATE_TAB = { 5,5};
  MSTATE_CHECK_VxH(6,menuTabModel,8+1+1);

  int8_t  sub    = mstate2.m_posVert;// - 1;
  uint8_t subSub = mstate2.m_posHorz + 1;
  static uint8_t s_pgOfs;
  if(sub>7) s_pgOfs = 2;
  if(sub<6) s_pgOfs = 0;

  switch(event)
  {
    case EVT_ENTRY:
      s_pgOfs = 0;
      break;
  }
  for(uint8_t i=0; i<5; i++){
    //lcd_puts_P( 4*FW, 1*FH,PSTR("subT min  max inv"));
    uint8_t    x=5*FW+i*(3*FW+2);
    uint8_t    l=3;
    prog_char* adr=PSTR("min""scl""max""inv")+(i-1)*3;
    if(i==0){l=4; adr=PSTR("subT"); x-=FW;}
    lcd_putsnAtt(x , 1*FH,adr,l,(sub==1 && mstate2.m_posHorz==i) ? INVERS : 0);
  }
  if(sub==1){
    checkIncDecGen2(event, &mstate2.m_posHorz, 0, 4, 0);
  }
  sub-=2;
  for(uint8_t i=0; i<6; i++){
    uint8_t y=(i+2)*FH;
    uint8_t k=i+s_pgOfs;
    uint8_t v;
    LimitData_r167 *ld = &g_model.limitData[k];
    for(uint8_t j=0; j<=5;j++){
      uint8_t attr = ((sub==k && subSub==j) ? BLINK : 0);
      switch(j)
      {
        case 0:          
          putsChn(0,y,k+1,(sub==k && subSub==0) ? INVERS : 0);
          break;        
        case 1:
          lcd_outdezAtt(  7*FW, y,  ld->offset,               attr);
          if(attr) {
            if(CHECK_INCDEC_H_MODELVAR_BF( event, ld->offset, -63,63))  LIMITS_DIRTY;
          }
          break;        
        case 2:
          //lcd_outdezAtt(  12*FW, y, (int8_t)(ld->min-100),   attr);
          //ld->min -=  40;
          v = add7Bit(ld->min,-40);
          lcd_outdezAtt(  12*FW, y, idx2val12255(v),   attr);
          if(attr) {
            //ld->min -=  100;
            //if(CHECK_INCDEC_H_MODELVAR( event, ld->min, -125,125))  LIMITS_DIRTY; 
            //ld->min +=  100;
            if(CHECK_INCDEC_H_MODELVAR( event, v, -50,50))  LIMITS_DIRTY; 
          }
          //ld->min +=  40;
          ld->min = add7Bit(v,40);
          break;        
        case 3:
          lcd_putsnAtt(   13*FW, y, PSTR(" ""*")+ld->scale*1,1,attr);
          if(attr) {
            CHECK_INCDEC_H_MODELVAR_BF( event, ld->scale,    0,1);
          }
          break;
        case 4:
          //lcd_outdezAtt( 16*FW, y, (int8_t)(ld->max+100),    attr);
          v = add7Bit(ld->max,+40);
          //ld->max +=  40;
          lcd_outdezAtt( 18*FW, y, idx2val12255(v),    attr);
          if(attr) {
            // ld->max +=  100;
            // if(CHECK_INCDEC_H_MODELVAR( event, ld->max, -125,125))  LIMITS_DIRTY; 
            // ld->max -=  100;
            if(CHECK_INCDEC_H_MODELVAR_BF( event, v, -50,50))  LIMITS_DIRTY; 
          }
          ld->max = add7Bit(v,-40);
          //ld->max -=  40;
          break;        
        case 5:
          lcd_putsnAtt(   18*FW, y, PSTR(" - INV")+ld->revert*3,3,attr);
          if(attr) {
            CHECK_INCDEC_H_MODELVAR_BF( event, ld->revert,    0,1);
          }
          break;        
      }
    }
  }
}



static int8_t s_currMixIdx;
static int8_t s_currDestCh;
static bool   s_currMixInsMode;
void menuProcMixOne(uint8_t event)
{
  static MState2 mstate2;
  uint8_t x=TITLEP(s_currMixInsMode ? PSTR("INSERT MIX ") : PSTR("EDIT MIX "));  
  MixData_r0 *md2 = &g_model.mixData[s_currMixIdx];
  putsChn(x,0,md2->destCh,0);
  MSTATE_CHECK0_V(7);
  int8_t  sub    = mstate2.m_posVert;


//#define CURV_STR "  -""x>0""x<0""|x|""cv1""cv2""cv3""cv4"
#define CURV_STR "  -""cv1""cv2""cv3""cv4""cv5""cv6""cv7"
  for(uint8_t i=0; i<=6; i++)
  {
    uint8_t y=i*FH+FH;
    uint8_t attr = sub==i ? BLINK : 0; 
    lcd_putsn_P( FW*8, y,PSTR("SRC  PRC  CURVESWTCHSLOPE          ")+5*i,5);
    switch(i){
      case 0:   putsChnRaw(   FW*4,y,md2->srcRaw,attr);
        //if(attr) md2->srcRaw = checkIncDec_hm( event, md2->srcRaw, 1,NUM_XCHNRAW); //!! bitfield
        if(attr) CHECK_INCDEC_H_MODELVAR_BF( event, md2->srcRaw, 1,NUM_XCHNRAW); //!! bitfield
        break;
      case 1:   lcd_outdezAtt(FW*7,y,md2->weight,attr);
        if(attr) CHECK_INCDEC_H_MODELVAR( event, md2->weight, -125,125);
        break;
      case 2:   lcd_putsnAtt( FW*4,y,PSTR(CURV_STR)+md2->curve*3,3,attr);
        if(attr) CHECK_INCDEC_H_MODELVAR_BF( event, md2->curve, 0,7); //!! bitfield
        if(attr && md2->curve>=1 && event==EVT_KEY_FIRST(KEY_MENU)){
          s_curveChan = md2->curve-1;
          pushMenu(menuProcCurveOne);
        }
        break;
      case 3:   putsDrSwitches(3*FW,  y,md2->swtch,attr);
        if(attr) {
	  CHECK_INCDEC_H_MODELVAR_BF( event, md2->swtch, -MAX_DRSWITCH, MAX_DRSWITCH); //!! bitfield
	  CHECK_LAST_SWITCH(md2->swtch,EE_MODEL|_FL_POSNEG);
	}
        break;
      case 4:   
        {
          lcd_puts_P(3*FW, y, PSTR("<  s"));
          uint16_t slope = slopeFull100ms(md2->speedDown);
          if(slope<100)  lcd_outdezAtt(FW*6,y,slope,   attr|PREC1);
          else           lcd_outdezAtt(FW*6,y,slope/10,attr);
          //lcd_outdezAtt(FW*3,y,md2->speedDown,attr);
          if(attr)  CHECK_INCDEC_H_MODELVAR_BF( event, md2->speedDown, 0,15); //!! bitfield
          break;
        }
      case 5:
        {
          lcd_puts_P(14*FW, y-FH, PSTR(">  s"));
          //lcd_putcAtt(4*FW+1, y-FH, '>',0);
          uint16_t slope = slopeFull100ms(md2->speedUp);
          if(slope<100)  lcd_outdezAtt(FW*17,y-FH,slope,   attr|PREC1);
          else           lcd_outdezAtt(FW*17,y-FH,slope/10,attr);
          //lcd_outdezAtt(FW*7,y-FH,md2->speedUp,attr);
          if(attr)  CHECK_INCDEC_H_MODELVAR_BF( event, md2->speedUp, 0,15); //!! bitfield
          break;
        }
      case 6:   lcd_putsAtt(  FW*3,y,PSTR("RM"),attr);
                lcd_puts_P(  FW*6,y,PSTR("remove [Menu]"));
        if(attr && event==EVT_KEY_FIRST(KEY_MENU)){
          memmove(
            &g_model.mixData[s_currMixIdx],
            &g_model.mixData[s_currMixIdx+1],
            (MAX_MIXERS-(s_currMixIdx+1))*sizeof(MixData_r0));
          memset(&g_model.mixData[MAX_MIXERS-1],0,sizeof(MixData_r0));
          STORE_MODELVARS;
          killEvents(event);
          popMenu();  
        }
        break;
    }
  }
}







#if 1

//ch selChn  dat selDat
// 1  _0    
// 2          21  *1
//            22  *2
//    _4      23  *3
// 3  _5    
// 4  _6    
// 5  _7    
// 6  _8    
// 7  _9    
// 8  _10    
class FoldList
{
public:
  struct Line{
    bool   showCh:1;// show the dest chn
    bool   showDat:1;// show the data info
    int8_t chId;    //:4  1..NUM_XCHNOUT  dst chn id             
    int8_t seqCh;   //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t seqDat;  //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t idx;     //:5  0..MAX_MIXERS-1  edit index into mix data tab
    //int8_t insIdx;  //:5  0..MAX_MIXERS-1        insert index into mix data tab
    //int8_t editIdx; //:5  0..MAX_MIXERS-1        edit   index into mix data tab
  };
  static Line s_lines[MAX_MIXERS+NUM_XCHNOUT+1];
  static uint8_t s_currCh,s_currLine,s_currSeq,s_currIdx; //for construction of s_lines
  static Line* getLine(uint8_t line){return &s_lines[line];};
  static int8_t numSeqs(){return s_currSeq;};
  static void init()
  {
    s_currCh  = 0;
    s_currLine= 0;
    s_currSeq = 1;
    s_currIdx =-1;
    memset(s_lines,0,sizeof(s_lines));
  }
  static bool fill(uint8_t ch) //helper func for construction
  {
    if(ch > s_currCh) {
      while(1){
        if(s_currLine>0) s_lines[s_currLine-1].seqCh=s_currSeq++;
        s_currCh++;
        if(s_currCh>=ch) break;
        s_lines[s_currLine].showCh = true;
        s_lines[s_currLine].chId   = s_currCh;
        s_lines[s_currLine].idx    = s_currIdx; //insert behind
        s_currLine++;
        assert(s_currLine<=DIM(s_lines));
      }
      return true;
    }else{
      return false;
    }
  }
  static void addDat(uint8_t ch, uint8_t idx)
  {
    if(fill(ch))
      s_lines[s_currLine].showCh = true;
    s_lines[s_currLine].chId     = s_currCh;
    s_lines[s_currLine].idx      = s_currIdx = idx;
    s_lines[s_currLine].showDat  = true;
    s_lines[s_currLine].seqDat   = s_currSeq++;
    s_currLine++;
  }

};
FoldList::Line FoldList::s_lines[MAX_MIXERS+NUM_XCHNOUT+1];
uint8_t FoldList::s_currCh,FoldList::s_currLine,FoldList::s_currSeq,FoldList::s_currIdx; //for construction of

void genMixTab()
{
  MixData_r0 *md=g_model.mixData;
  FoldList::init();
  for(uint8_t i=0; i<MAX_MIXERS && md[i].destCh; i++)
  {
    FoldList::addDat(md[i].destCh,i);
  }
  FoldList::fill(NUM_XCHNOUT+1);
#ifdef SIM
  //for(uint8_t i=0; i<DIM(s_mixTab); i++){
  for(uint8_t i=0; i<14; i++){
    //MixTab *mt=s_mixTab+i;
    FoldList::Line* line=FoldList::getLine(i);
    printf("dest %2d wght %4d    "
           "chId %2d %cseqCh %2d %cseqDat %2d idx %d\n",
           md[i].destCh, md[i].weight,
           line->chId,
           line->showCh?'*':' ', line->seqCh,
           line->showDat?'*':' ', line->seqDat,
           line->idx);
  }
#endif
}
void newLine(uint8_t idx)
{
  MixData_r0 *md=g_model.mixData;
  memmove(&md[idx+1],&md[idx],
          (MAX_MIXERS-(idx+1))*sizeof(md[0]) );
  md[idx].destCh      = s_currDestCh; //-s_mixTab[sub];
  md[idx].srcRaw      = s_currDestCh; //1;   //
  md[idx].weight      = 100;
  md[idx].swtch       = 0; //no switch
  md[idx].curve       = 0; //linear
  md[idx].speedUp     = 0; //Servogeschwindigkeit aus Tabelle (10ms Cycle)
  md[idx].speedDown   = 0; //
  STORE_MODELVARS;
  genMixTab();
}
void dupLine(uint8_t idx)
{
  MixData_r0 *md=g_model.mixData;
  memmove(&md[idx+1],&md[idx],
          (MAX_MIXERS-(idx+1))*sizeof(md[0]) );
  STORE_MODELVARS;
  genMixTab();
}
bool moveLine(uint8_t from, uint8_t to, bool insMode)
{
  //printf("moveLine(from %d, to %d, ins %d)\n",from,to,insMode);
  MixData_r0 *md = g_model.mixData;
  if(insMode){
    if(from < to)  {//nach hinten
      if(md[from].destCh >= NUM_XCHNOUT) return false;
      md[from].destCh++; 
    }
    else{
      if(md[from].destCh <= 1) return false;
      md[from].destCh--;
    }
  }else{
    if(from==to) return false;
    MixData_r0 tmp = md[to];
    md[to]         = md[from];
    md[from]       = tmp;
  }
  STORE_MODELVARS;
  genMixTab();
  return true;
}

uint8_t currMixerLine;
int32_t currMixerVal;
int32_t currMixerSum;
void menuProcMix(uint8_t event)
{
  static MState2 mstate2;
  TITLE("MIXER");  
  int8_t subOld  = mstate2.m_posVert;
  int8_t mixIdOld  = s_currMixIdx;
  MSTATE_CHECK_V(4,menuTabModel,FoldList::numSeqs());
  int8_t  sub    = mstate2.m_posVert;
  static uint8_t s_pgOfs;
  static bool    s_editMode;
  MixData_r0 *md=g_model.mixData;
  switch(event)
  {
    case EVT_ENTRY:
      s_pgOfs=0;
    case EVT_ENTRY_UP:
      s_editMode=false;
      genMixTab();
      break;
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(s_editMode){
        s_editMode = false;
        beepKey();
        killEvents(event); //cut off MSTATE_CHECK (KEY_BREAK)
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):
      if(s_currMixInsMode) break;
      if(s_editMode)
      {
        //duplicate line
        dupLine(s_currMixIdx);
        beepKey();
      }
      s_editMode=true;
      killEvents(event); //cut off 
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(sub<1) break;

      if(s_currMixInsMode) newLine(s_currMixIdx);
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
    FoldList::Line* line=FoldList::getLine(k);
    if(!line->showCh && !line->showDat ) break;

    if(line->showCh){  
      putsChn(0,y,line->chId,0); // show CHx
    }
    if(sub>0 && sub==line->seqCh) { //handle CHx is selected (other line)
      if(BLINK_ON_PHASE) lcd_hline(0,y+7,FW*4);
      s_currMixIdx     = line->idx+1;
      s_currDestCh     = line->chId;
      s_currMixInsMode = true;
      markedIdx        = i;
    }
    if(line->showDat){ //show data 
      MixData_r0 *md2=&md[line->idx];
      uint8_t attr = sub==line->seqDat ? BLINK : 0; 
      uint8_t att2 = 0;
      
      if(attr) {
        currMixerLine = line->idx;
        lcd_outdez(   9*FW, 0, currMixerVal>>9);
        lcd_putc  (   9*FW, 0, '/');
        lcd_outdez(  13*FW+1, 0, currMixerSum>>9);
        if(s_editMode) {attr=0; att2=BLINK;}
      }

      lcd_outdezAtt(  7*FW, y, md2->weight,attr);
      lcd_putcAtt(    7*FW+1, y, '%',0);
      putsChnRaw(     9*FW-2, y, md2->srcRaw,0);
      if(md2->swtch)putsDrSwitches( 13*FW-4, y, md2->swtch,0);
      if(md2->curve)lcd_putsnAtt(   17*FW+2, y, PSTR(CURV_STR)+md2->curve*3,3,0);
      if(md2->speedDown || md2->speedUp)lcd_putcAtt(20*FW+1, y, 's',0);

      if(att2) lcd_barAtt( 4*FW,y,16*FW,att2);
      //lcd_putsAtt( 4*FW+1, y, PSTR("                "),att2);

      if(sub==line->seqDat) { //handle dat is selected
        CHECK_INCDEC_H_MODELVAR( event, md2->weight, -125,125);
        s_currMixIdx     = line->idx;
        s_currDestCh     = line->chId;
        s_currMixInsMode = false;
        markedIdx        = i;
      }
    }
    //welche sub-indize liegen im sichtbaren bereich?
    if(line->seqCh){
      minSel = min(minSel,line->seqCh);
      maxSel = max(maxSel,line->seqCh);
    }
    if(line->seqDat){
      minSel = min(minSel,line->seqDat);
      maxSel = max(maxSel,line->seqDat);
    }    

  } //for 7
  if(s_editMode && subOld != sub) //mixIdOld != s_currMixIdx){
  {
    printf("subOld %d sub %d\n",subOld,sub);
    if(! moveLine(mixIdOld,s_currMixIdx,s_currMixInsMode))
      s_editMode = false;
  }
  if( sub!=0 &&  markedIdx==-1) { //versuche die Marke zu finden
    if(sub < minSel) s_pgOfs = max(0,s_pgOfs-1);
    if(sub > maxSel) s_pgOfs++;
  }
  else if(markedIdx<=1)              s_pgOfs = max(0,s_pgOfs-1);
  else if(markedIdx>=5 && i>=7)      s_pgOfs++;
}


#else
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
  bool   showCh:1;// show the dest chn
  bool   hasDat:1;// show the data info
  int8_t chId;    //:4  1..NUM_XCHNOUT  dst chn id             
  int8_t selCh;   //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
  int8_t selDat;  //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
  int8_t insIdx;  //:5  0..MAX_MIXERS-1        insert index into mix data tab
  int8_t editIdx; //:5  0..MAX_MIXERS-1        edit   index into mix data tab
} s_mixTab[MAX_MIXERS+NUM_XCHNOUT+1];
int8_t s_mixMaxSel;

void genMixTab()
{
  uint8_t maxDst  = 0;
  uint8_t mtIdx   = 0;
  uint8_t sel     = 1;
  memset(s_mixTab,0,sizeof(s_mixTab));

  MixData_r0 *md=g_model.mixData;

  for(uint8_t i=0; i<MAX_MIXERS; i++)
  {
    uint8_t destCh = md[i].destCh;
    if(destCh==0) destCh=NUM_XCHNOUT;
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
    if(md[i].destCh==0) break; //letzter eintrag in mix data tab
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
#ifdef xSIM
  //for(uint8_t i=0; i<DIM(s_mixTab); i++){
  for(uint8_t i=0; i<14; i++){
    MixTab *mt=s_mixTab+i;
    printf("dest %2d wght %2d    "
           "chId %2d selCh %2d selDat %2d insIdx %d editIdx %d\n",
           md[i].destCh, md[i].weight,
           mt->chId,mt->selCh,mt->selDat,mt->insIdx,mt->editIdx);
  }
#endif
}

void newLine(uint8_t idx)
{
  MixData_r0 *md=g_model.mixData;
  memmove(&md[idx+1],&md[idx],
          (MAX_MIXERS-(idx+1))*sizeof(md[0]) );
  md[idx].destCh      = s_currDestCh; //-s_mixTab[sub];
  md[idx].srcRaw      = s_currDestCh; //1;   //
  md[idx].weight      = 100;
  md[idx].swtch       = 0; //no switch
  md[idx].curve       = 0; //linear
  md[idx].speedUp     = 0; //Servogeschwindigkeit aus Tabelle (10ms Cycle)
  md[idx].speedDown   = 0; //
  STORE_MODELVARS;
  genMixTab();
}
void dupLine(uint8_t idx)
{
  MixData_r0 *md=g_model.mixData;
  memmove(&md[idx+1],&md[idx],
          (MAX_MIXERS-(idx+1))*sizeof(md[0]) );
  STORE_MODELVARS;
  genMixTab();
}
bool moveLine(uint8_t from, uint8_t to, bool insMode)
{
  //printf("moveLine(from %d, to %d, ins %d)\n",from,to,insMode);
  MixData_r0 *md = g_model.mixData;
  if(insMode){
    if(from < to)  {//nach hinten
      if(md[from].destCh >= NUM_XCHNOUT) return false;
      md[from].destCh++; 
    }
    else{
      if(md[from].destCh <= 1) return false;
      md[from].destCh--;
    }
  }else{
    if(from==to) return false;
    MixData_r0 tmp = md[to];
    md[to]         = md[from];
    md[from]       = tmp;
  }
  STORE_MODELVARS;
  genMixTab();
  return true;
}

uint8_t currMixerLine;
int32_t currMixerVal;
int32_t currMixerSum;
void menuProcMix(uint8_t event)
{
  static MState2 mstate2;
  TITLE("MIXER");  
  int8_t subOld  = mstate2.m_posVert;
  int8_t mixIdOld  = s_currMixIdx;
  MSTATE_CHECK_V(4,menuTabModel,s_mixMaxSel);
  int8_t  sub    = mstate2.m_posVert;
  static uint8_t s_pgOfs;
  static bool    s_editMode;
  MixData_r0 *md=g_model.mixData;
  switch(event)
  {
    case EVT_ENTRY:
      s_pgOfs=0;
    case EVT_ENTRY_UP:
      s_editMode=false;
      genMixTab();
      break;
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(s_editMode){
        s_editMode = false;
        beepKey();
        killEvents(event); //cut off MSTATE_CHECK (KEY_BREAK)
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):
      if(s_currMixInsMode) break;
      if(s_editMode)
      {
        //duplicate line
        dupLine(s_currMixIdx);
        beepKey();
      }
      s_editMode=true;
      killEvents(event); //cut off 
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(sub<1) break;

      if(s_currMixInsMode) newLine(s_currMixIdx);
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
      putsChn(0,y,s_mixTab[k].chId,0); // show CHx
    }
    if(sub>0 && sub==s_mixTab[k].selCh) { //handle CHx is selected (other line)
      if(BLINK_ON_PHASE) lcd_hline(0,y+7,FW*4);
      s_currMixIdx     = s_mixTab[k].insIdx;
      s_currDestCh     = s_mixTab[k].chId;
      s_currMixInsMode = true;
      markedIdx        = i;
    }
    if(s_mixTab[k].hasDat){ //show data 
      MixData_r0 *md2=&md[s_mixTab[k].editIdx];
      uint8_t attr = sub==s_mixTab[k].selDat ? BLINK : 0; 
      uint8_t att2 = 0;
      
      if(attr) {
        currMixerLine = s_mixTab[k].editIdx;
        lcd_outdez(   9*FW, 0, currMixerVal>>9);
        lcd_putc  (   9*FW, 0, '/');
        lcd_outdez(  13*FW+1, 0, currMixerSum>>9);
        if(s_editMode) {attr=0; att2=BLINK;}
      }

      lcd_outdezAtt(  7*FW, y, md2->weight,attr);
      lcd_putcAtt(    7*FW+1, y, '%',0);
      putsChnRaw(     9*FW-2, y, md2->srcRaw,0);
      if(md2->swtch)putsDrSwitches( 13*FW-4, y, md2->swtch,0);
      if(md2->curve)lcd_putsnAtt(   17*FW+2, y, PSTR(CURV_STR)+md2->curve*3,3,0);
      if(md2->speedDown || md2->speedUp)lcd_putcAtt(20*FW+1, y, 's',0);

      if(att2) lcd_barAtt( 4*FW,y,16*FW,att2);
      //lcd_putsAtt( 4*FW+1, y, PSTR("                "),att2);

      if(sub==s_mixTab[k].selDat) { //handle dat is selected
        CHECK_INCDEC_H_MODELVAR( event, md2->weight, -125,125);
        s_currMixIdx     = s_mixTab[k].editIdx;
        s_currDestCh     = s_mixTab[k].chId;
        s_currMixInsMode = false;
        markedIdx        = i;
      }
    }
    //welche sub-indize liegen im sichtbaren bereich?
    if(s_mixTab[k].selCh){
      minSel = min(minSel,s_mixTab[k].selCh);
      maxSel = max(maxSel,s_mixTab[k].selCh);
    }
    if(s_mixTab[k].selDat){
      minSel = min(minSel,s_mixTab[k].selDat);
      maxSel = max(maxSel,s_mixTab[k].selDat);
    }    

  } //for 7
  if(s_editMode && subOld != sub) //mixIdOld != s_currMixIdx){
  {
    printf("subOld %d sub %d\n",subOld,sub);
    if(! moveLine(mixIdOld,s_currMixIdx,s_currMixInsMode))
      s_editMode = false;
  }
  if( sub!=0 &&  markedIdx==-1) { //versuche die Marke zu finden
    if(sub < minSel) s_pgOfs = max(0,s_pgOfs-1);
    if(sub > maxSel) s_pgOfs++;
  }
  else if(markedIdx<=1)              s_pgOfs = max(0,s_pgOfs-1);
  else if(markedIdx>=5 && i>=7)      s_pgOfs++;
}
#endif









int16_t trimVal(uint8_t idx)
{
  return trimExp(g_model.trimData[idx].trim);
//  return trim*(abs(trim)+1)/2;
}

void menuProcTrim(uint8_t event)
{
  static MState2 mstate2;
  TITLE("TRIM-SUBTRIM");  
  MSTATE_CHECK_V(5,menuTabModel,4+1);
  int8_t  sub    = mstate2.m_posVert - 1;
  static int16_t outHelp[NUM_CHNOUT];
  if(sub>=0)
  {
    int8_t  trimTmp = g_model.trimData[sub].trim;
    g_model.trimData[sub].trim = 0;
    perOut(outHelp); //try output calculation without this trim-value
    g_model.trimData[sub].trim = trimTmp;
    for(uint8_t i=0; i<NUM_CHNOUT;i++){
      outHelp[i] = (g_chans512[i] - outHelp[i]) ;
      outHelp[i] = (outHelp[i] + sgn(outHelp[i])*2) / 5 ;
    }
  }

  switch(event)
  {
    case  EVT_KEY_FIRST(KEY_RIGHT): 
      //case  EVT_KEY_REPT(KEY_RIGHT): 
      if(sub>=0)
      {
        for(uint8_t i=0; i<NUM_CHNOUT;i++){
          g_model.limitData[i].offset += outHelp[i];
        }
        g_model.trimData[sub].trim     = 0;
        STORE_MODELVARS;
        beepKey();
      }
      break;
  }

  lcd_puts_P( 5*FW, 1*FH,PSTR("Trim   Subtrim"));
  lcd_puts_P(11*FW, 2*FH,PSTR(      "Ch14 Ch58"));
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=i*FH+FH*3;
    uint8_t attr = sub==i ? INVERS : 0; 
    putsChnRaw(0,y,i+1,0);//attr);
    lcd_outdezAtt( 8*FW, y, trimVal(i)*2, attr|PREC1 );
    if(sub>=0 && outHelp[i] && BLINK_ON_PHASE) lcd_outdezAtt(14*FW, y, outHelp[i]   , outHelp[i]   ? BLINK|SIGN : 0);
    else           lcd_outdezAtt(14*FW, y, g_model.limitData[i].offset , 0);

    if(sub>=0 && outHelp[i+4] && BLINK_ON_PHASE)lcd_outdezAtt(19*FW, y, outHelp[i+4] , outHelp[i+4] ? BLINK|SIGN : 0);
    else           lcd_outdezAtt(19*FW, y, g_model.limitData[i+4].offset , 0);
  }
  lcd_puts_P(FW*6,FH*7,PSTR("-->  Rearrange"));  
}

uint16_t expou(uint16_t x, uint16_t k)
{
  // k*x*x*x + (1-k)*x
  return ((unsigned long)x*x*x/0x10000*k/(RESXul*RESXul/0x10000) + (RESKul-k)*x+RESKul/2)/RESKul;
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
    y = RESXu-expou(RESXu-x,-k);
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
  drx = d * ((uint16_t)RESXu/256);
}
int16_t Expo::expou(uint16_t x,uint16_t c, int16_t d)
{
  uint16_t a = 256 - c - d;
  if( (int16_t)a < 0 ) a = 0;
  // a x^3 + c x + d
  //                         9  18  27        11  20   18
  uint32_t res =  ((uint32_t)x * x * x / 0x10000 * a / (RESXul*RESXul/0x10000) +
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

void editExpoVals(uint8_t event,uint8_t which,bool edit,uint8_t x, uint8_t y, uint8_t chn)
{
  uint8_t  invBlk = edit ? BLINK : 0;
  switch(which)
  {
    case 0:
      lcd_outdezAtt(x, y, g_model.expoData[chn].expNorm, invBlk);
      if(edit) CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[chn].expNorm,-100, 100);
      break; 
    case 1:
      lcd_outdezAtt(x, y, g_model.expoData[chn].expNormWeight+100, invBlk);
      if(edit) CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[chn].expNormWeight, -100, 0);
      break; 
    case 2:
      putsDrSwitches(x,y,g_model.expoData[chn].drSw,invBlk);
      if(edit) {
        uint8_t prev=g_model.expoData[chn].drSw;
	CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[chn].drSw,0,MAX_DRSWITCH); 
        CHECK_LAST_SWITCH(g_model.expoData[chn].drSw,EE_MODEL);
        if( prev==0 && prev!=g_model.expoData[chn].drSw){
          g_model.expoData[chn].expDr       = g_model.expoData[chn].expNorm;
          g_model.expoData[chn].expSwWeight = g_model.expoData[chn].expNormWeight;
        }
      }
      break; 
    case 3:
      lcd_outdezAtt(x, y, g_model.expoData[chn].expDr, invBlk);
      if(edit) CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[chn].expDr,-100, 100);
      break; 
    case 4:
      lcd_outdezAtt(x, y, g_model.expoData[chn].expSwWeight+100, invBlk);
      if(edit) CHECK_INCDEC_H_MODELVAR(event,g_model.expoData[chn].expSwWeight, -100, 0);
      break; 
  }
}

void menuProcExpoOne(uint8_t event)
{
  static MState2 mstate2;
  uint8_t x=TITLE("EXPO/DR ");  
  putsChnRaw(x,0,s_expoChan+1,0);
  bool withDr=g_model.expoData[s_expoChan].drSw!=0;
  MSTATE_CHECK0_V(withDr ? 5 : 3);
  int8_t  sub    = mstate2.m_posVert;

  //uint8_t  invBlk = 0;
  uint8_t  y = 16;


  lcd_puts_P(0,y,PSTR("Expo"));
  editExpoVals(event,0,sub==0,9*FW, y,s_expoChan);
  y+=FH;

  lcd_puts_P(0,y,PSTR("Weight"));
  editExpoVals(event,1,sub==1,9*FW, y,s_expoChan);
  y+=FH;
  y+=FH;

  lcd_puts_P(0,y,PSTR("DrSw"));  
  editExpoVals(event,2,sub==2,5*FW, y,s_expoChan);
  y+=FH;
  
  if(withDr){
    lcd_puts_P(0,y,PSTR("DrExp"));  
    editExpoVals(event,3,sub==3,9*FW, y,s_expoChan);
    y+=FH;

    lcd_puts_P(0,y,PSTR("Weight"));
    editExpoVals(event,4,sub==4,9*FW, y,s_expoChan);
    y+=FH;
  }

  int8_t   kView  = 0;
  int8_t   wView  = 0;
  if(sub<=1){
    kView  = g_model.expoData[s_expoChan].expNorm;
    wView  = g_model.expoData[s_expoChan].expNormWeight+100;
  }else{
    if(sub<=4 && withDr){
      kView =g_model.expoData[s_expoChan].expDr;
      wView =g_model.expoData[s_expoChan].expSwWeight+100;
    }else{
      return;
    }
  }
 
#define WCHART 32
#define X0     (128-WCHART-2)
#define Y0     32
  for(uint8_t xv=0;xv<WCHART;xv++)
  {
    uint16_t yv=expo(xv*(RESXu/WCHART),kView) / (RESXu/WCHART);
    yv = (yv * wView)/100;
    lcd_plot(X0+xv, Y0-yv);
    lcd_plot(X0-xv, Y0+yv);
  }
  lcd_vline(X0,Y0-WCHART,WCHART*2);
  lcd_hline(X0-WCHART,Y0,WCHART*2);

  int16_t x512  = anaCalib[s_expoChan];
  int16_t y512  = expo(x512,kView);
  y512 = y512 * (wView / 4)/(100 / 4);

  lcd_outdezAtt( 19*FW, 6*FH,x512*25/((signed) RESXu/4), 0 );
  lcd_outdezAtt( 14*FW, 1*FH,y512*25/((signed) RESXu/4), 0 );
  x512 = X0+x512/(RESXu/WCHART);
  y512 = Y0-y512/(RESXu/WCHART);
  lcd_vline(x512, y512-3,3*2+1);
  lcd_hline(x512-3, y512,3*2+1);
  //dy/dx
  
  int16_t dy  = x512>0 ? y512-expo(x512-20,kView) : expo(x512+20,kView)-y512;
  lcd_outdezNAtt(14*FW, 2*FH,   dy*(100/20), LEADING0|PREC2,3);
}
void menuProcExpoAll(uint8_t event)
{
  static MState2 mstate2;
  TITLE("EXPO/DR");  
  MSTATE_TAB = {5,5};
  MSTATE_CHECK_VxH(3,menuTabModel,4+2);
  int8_t  sub    = mstate2.m_posVert;
  int8_t  subHor = mstate2.m_posHorz;

  switch(event)
  {
    case EVT_KEY_FIRST(KEY_MENU):
      if(sub>=2){
        s_expoChan = sub-2;
        pushMenu(menuProcExpoOne);  
      }
      break;
  }

  for(uint8_t i=0; i<5; i++)
  {
    lcd_putsnAtt( 3*FW+i*4*FW, 1*FH,PSTR("exp" " % " "sw " "exp" " % ")+i*3,3,(sub==1 && mstate2.m_posHorz==i) ? INVERS : 0);
  }
  if(sub==1){
    checkIncDecGen2(event, &mstate2.m_posHorz, 0, 4, 0);
  }
  for(uint8_t i=0; i<4; i++)
  {
    uint8_t y=(i+2)*FH;
    bool    sel=(sub==i+2);
    putsChnRaw( 0, y,i+1,0);
    editExpoVals(event,0,sel && subHor==0, 6*FW, y,i);
    editExpoVals(event,1,sel && subHor==1,10*FW, y,i);
    editExpoVals(event,2,sel && subHor==2,10*FW, y,i);
    if(g_model.expoData[i].drSw){
      editExpoVals(event,3,sel && subHor==3,17*FW, y,i);
      editExpoVals(event,4,sel && subHor==4,21*FW, y,i);
    }else{
      lcd_putsAtt( 16*FW, y,PSTR(" "),(sel && subHor==3) ? INVERS : 0);
      lcd_putsAtt( 20*FW, y,PSTR(" "),(sel && subHor==4) ? INVERS : 0);
      //if(sel && subHor>=3) mstate2.m_posHorz=2;
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
  static MState2 mstate2;
  uint8_t x=TITLE("SETUP ");  
  lcd_outdezNAtt(x+2*FW,0,g_eeGeneral.currModel+1,INVERS+LEADING0,2); 
  MSTATE_TAB = { 1,(int8_t)-sizeof(g_model.name),-3,1,1,1};
  MSTATE_CHECK_VxH(2,menuTabModel,5+1);
  int8_t  sub    = mstate2.m_posVert-1;

  uint8_t subSub = mstate2.m_posHorz;//+1;
  static uint8_t s_type;
  switch(event){
    case EVT_ENTRY:
      if(g_eeGeneral.currModel==0) s_type = 1; //beim ersten Modell solls shon mal funktionieren
      break;
    case EVT_EXIT: 
      if(! g_model.mdVers )  modelMixerDefault(s_type);
      break;
  }

  uint8_t y=1*FH;
  for(uint8_t i=0; i<5; i++)
  {
    y+=FH;
    uint8_t attr = sub==i ? BLINK : 0; 
    if(i<2)
      lcd_putsnAtt(  0,    y,    PSTR("Name ""Timer")+5*i,5,(subSub==0 && attr) ? INVERS : 0);
    else        
      lcd_putsn_P(  0,    y,    PSTR("Proto""Type ""RM   ")+5*(i-2),5);
    switch(i){
      case 0:    
        //lcd_putsAtt(    0,    2*FH, PSTR("Name"),sub==1 && subSub==0 ? BLINK:0);
        lcd_putsnAtt(   6*FW, y, g_model.name ,sizeof(g_model.name),BSS_NO_INV);
        if(attr && subSub) {
          char v = char2idx(g_model.name[subSub-1]);
          CHECK_INCDEC_V_MODELVAR_BF( event,v ,0,NUMCHARS-1);
          v = idx2char(v);
          g_model.name[subSub-1]=v;
          lcd_putcAtt((6+subSub-1)*FW, y, v,BLINK);
        }
        break;
      case 1:
        //lcd_putsAtt(    0,    4*FH, PSTR("Timer"),sub==3 && subSub==0 ? BLINK:0);
        putsTime(       5*FW, y, g_model.tmrVal,
                        ( subSub==1 ? attr:0),
                        ( subSub==2 ? attr:0) );
        lcd_putsnAtt(  12*FW, y, PSTR(" OFF ABS THRTHR%")+4*g_model.tmrMode,4,
                       ( subSub==3 ? attr:0));
        if(attr) switch(subSub) 
        {
          case 1:
            {
              int8_t min=g_model.tmrVal/60;
              CHECK_INCDEC_V_MODELVAR_BF( event,min ,0,59);
              g_model.tmrVal = g_model.tmrVal%60 + min*60;
              break;
            }
          case 2:
            {
              int8_t sec=g_model.tmrVal%60;
              sec -= checkIncDec_vm( event,sec+2 ,1,62)-2;
              g_model.tmrVal -= sec ;
              if((int16_t)g_model.tmrVal < 0) g_model.tmrVal=0;
              break;
            }
          case 3:
            CHECK_INCDEC_V_MODELVAR_BF( event,g_model.tmrMode ,0,3);
            break;
        }
        break;
      case 2:    
        //lcd_putsAtt(    0,    3*FH, PSTR("Proto"),0);//sub==2 ? INVERS:0);
        lcd_putsnAtt(   6*FW, y, PSTR(PROT_STR)+PROT_STR_LEN*g_model.protocol,PROT_STR_LEN, attr);
        if(attr) CHECK_INCDEC_H_MODELVAR(event,g_model.protocol,0,PROT_MAX);
        break;
      case 3:
        if(! g_model.mdVers ){
          lcd_putsAtt(  FW*6, y, modelMixerDefaultName(s_type),attr);
          if(attr){
            checkIncDecGen2(event, &s_type, 0, modelMixerDefaults-1, 0);
          }
        }else{
          lcd_putsAtt(  FW*6, y, PSTR("modif."),attr?INVERS:0);
        }
        y+=FH;
        break;
      case 4:
        //lcd_putsAtt(    0, (7)*FH, PSTR("RM"),attr);
        lcd_putsAtt(  FW*6, y, PSTR("[MENU LONG]"),attr);
        if(attr){
          if(event==EVT_KEY_LONG(KEY_MENU)){
            killEvents(event);
            EFile::rm(FILE_MODEL(g_eeGeneral.currModel)); //delete file
            eeLoadModel(g_eeGeneral.currModel); //load default values
            chainMenu(menuProcModelSelect);
          }
        }       
    }//switch(i)
  }
}
void menuProcModelSelect(uint8_t event)
{
  static uint8_t s_editMode;
  static MState2 mstate2;
  TITLE("MODELSEL");  
  lcd_puts_P(     10*FW, 0, PSTR("free"));
  lcd_outdezAtt(  18*FW, 0, EeFsGetFree(),0);
  lcd_putsAtt(128-FW*3,0,PSTR("1/7"),INVERS);
  int8_t subOld  = mstate2.m_posVert;
  MSTATE_CHECK0_V(MAX_MODELS);
  int8_t  sub    = mstate2.m_posVert;
  static uint8_t s_pgOfs;
  switch(event)
  {
    //case  EVT_KEY_FIRST(KEY_MENU):
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(s_editMode){
        s_editMode = false;
        beepKey();
        killEvents(event);
        break;
      }
      //fallthrough
    case  EVT_KEY_FIRST(KEY_RIGHT):
      if(g_eeGeneral.currModel != mstate2.m_posVert)
      {
        eeLoadModel(g_eeGeneral.currModel = mstate2.m_posVert);
        eeDirty(EE_GENERAL);
        LIMITS_DIRTY;
        beepKey();
      }
      //case EXIT handled in checkExit
      if(event==EVT_KEY_FIRST(KEY_RIGHT))  chainMenu(menuProcModel);
      break;
    case  EVT_KEY_FIRST(KEY_MENU):
      s_editMode = true;
      beepKey();
      break;
    case  EVT_KEY_LONG(KEY_MENU):
      if(s_editMode){
        if(eeDuplicateModel(sub)) {
          beepKey();
          s_editMode = false;
        }
        else                      beepWarn();
      }
      break;

    case EVT_ENTRY:
      s_editMode = false;
      
      mstate2.m_posVert = g_eeGeneral.currModel;
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
    static char buf[sizeof(g_model.name)+8];
    eeLoadModelName(k,buf,sizeof(buf));
    lcd_putsnAtt(  3*FW, y, buf,sizeof(buf),BSS_NO_INV|((sub==k) ? (s_editMode ? BLINK : 0 ) : 0));
  }

}



void menuProcDiagCalib(uint8_t event)
{
  static MState2 mstate2;
  TITLE("CALIB");
  MSTATE_CHECK_V(7,menuTabDiag,4);
  int8_t  sub    = mstate2.m_posVert ;
  static int16_t midVals[7];
  static int16_t loVals[7];
  static int16_t hiVals[7];

  for(uint8_t i=0; i<7; i++) { //get low and high vals for sticks and trims
    int16_t vt = anaIn(i);
    loVals[i] = min(vt,loVals[i]);
    hiVals[i] = max(vt,hiVals[i]);
    if(i>=4) midVals[i] = (loVals[i] + hiVals[i])/2;
  }

  switch(event)
  {
    case EVT_ENTRY:
      for(uint8_t i=0; i<7; i++) loVals[i] = 15000;
      break;
    case EVT_KEY_BREAK(KEY_DOWN): // !! achtung sub schon umgesetzt
      switch(sub)
      {
        case 2: //get mid
          for(uint8_t i=0; i<4; i++)midVals[i] = anaIn(i);
          beepKey();
          break;
        case 3: 
          printf("do calib");
          for(uint8_t i=0; i<7; i++)
            if(hiVals[i]-loVals[i]>50) {
            g_eeGeneral.calibMid[i]  = midVals[i];
              int16_t v = midVals[i] - loVals[i];
            g_eeGeneral.calibSpanNeg[i] = v - v/64;
              v = hiVals[i] - midVals[i];
            g_eeGeneral.calibSpanPos[i] = v - v/64;
          }
          //int16_t sum=0;
          //for(uint8_t i=0; i<12;i++) sum+=g_eeGeneral.calibMid[i];
          //g_eeGeneral.chkSum = sum;
          eeDirty(EE_GENERAL); //eeWriteGeneral();
          beepKey();
          break;
      }
      break;
  }
  for(uint8_t i=1; i<4; i++)
  {
    uint8_t y=i*FH+FH;
    lcd_putsnAtt( 0, y,PSTR("SetMid MovArndDone   ")+7*(i-1),7,
                    sub==i ? INVERS : 0);
  }
  for(uint8_t i=0; i<7; i++)
  {
    uint8_t y=i*FH+0;
    //lcd_putsn_P( 8*FW,  y,      PSTR("A1A2A3A4")+2*i,2);  
    //lcd_outhex4(12*FW,  y,      anaIn(i));
    lcd_puts_P( 11*FW,  y+1*FH, PSTR("<    >"));  
    lcd_outhex4( 8*FW-3,y+1*FH, sub==2 ? loVals[i]  :g_eeGeneral.calibSpanNeg[i]);
    lcd_outhex4(12*FW,  y+1*FH, sub==1 ? anaIn(i) : (sub==2 ? midVals[i] :g_eeGeneral.calibMid[i]));
    lcd_outhex4(17*FW,  y+1*FH, sub==2 ? hiVals[i]  :g_eeGeneral.calibSpanPos[i]);
  }

}
void menuProcDiagAna(uint8_t event)
{
  static MState2 mstate2;
  TITLE("ANA");  
  MSTATE_CHECK_V(6,menuTabDiag,9);
  int8_t  sub    = mstate2.m_posVert-1 ;
  for(uint8_t i=0; i<8; i++)
  {
    uint8_t y=i*FH;
    lcd_putsnAtt( 4*FW, y,PSTR("A1A2A3A4A5A6A7A8")+2*i,2,sub==i ? INVERS : 0);  
    //lcd_outhex4( 8*FW, y,g_anaIns[i]);
    lcd_outhex4( 7*FW, y,anaIn(i));
    if(i<7){
      //int16_t v = g_anaIns[i];
      int16_t v = anaIn(i) - g_eeGeneral.calibMid[i];
      v =  v*50/max(1, (v > 0 ? g_eeGeneral.calibSpanPos[i] :  g_eeGeneral.calibSpanNeg[i])/2);
      lcd_outdez(15*FW, y, v);
        //lcd_outdez(17*FW, y, (v-g_eeGeneral.calibMid[i])*50/ max(1,g_eeGeneral.calibSpan[i]/2));
    }
    if(i==7){
      putsVBat(11*FW,y,sub==7 ? BLINK : 0);
    }
  }
  if(sub==7){
   CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.vBatCalib, -127, 127);
  }
#ifdef WITH_ADC_STAT
  switch(event)
    {
    case EVT_KEY_FIRST(KEY_MENU):
      g_rawPos=0;
      break;
    }
  g_rawChan=sub;
  for(uint8_t j=0; j<DIM(g_rawVals); j++){
    lcd_outdez(20*FW+2 , (j+1)*FH, g_rawVals[j]);
  }
#endif
}

void menuProcDiagKeys(uint8_t event)
{
  static MState2 mstate2;
  TITLE("DIAG");  
  MSTATE_CHECK_V(5,menuTabDiag,1);

  uint8_t x;

  x=7*FW;
  for(uint8_t i=0; i<9; i++)
  {
    uint8_t y=i*FH; //+FH;
    if(i>(SW_ID0-SW_BASE_DIAG)) y-=FH; //overwrite ID0
    bool t=keyState((EnumKeys)(SW_BASE_DIAG+i));
    putsDrSwitches(x,y,i+1,0); //ohne off,on
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
  static MState2 mstate2;
  TITLE("VERSION");
  MSTATE_CHECK_V(4,menuTabDiag,1);

  lcd_puts_P(0, 2*FH,stamp4 ); 
  lcd_puts_P(0, 3*FH,stamp1 ); 
  lcd_puts_P(0, 4*FH,stamp2 ); 
  lcd_puts_P(0, 5*FH,stamp3 ); 
}

void menuProcTrainer(uint8_t event)
{
  static MState2 mstate2;
  TITLE("TRAINER");  
  MSTATE_TAB = { 4,4};
  MSTATE_CHECK_VxH(3,menuTabDiag,1+1+4+1);
  int8_t  sub    = mstate2.m_posVert;//-1 ;
  uint8_t subSub = mstate2.m_posHorz+1;
  uint8_t y;
  bool    edit;

  if(PING & (1<<INP_G_RF_POW)) // i am the slave
  {
    lcd_puts_P(  7*FW,3*FH , PSTR("Slave"));
    return;
  }
  
  for(uint8_t i=0; i<4; i++){
    //lcd_puts_P( 3*FW, 1*FH,PSTR("mode prc src swt"));
    lcd_putsnAtt( 3*FW+i*4*FW, 1*FH,PSTR("mode"" prc"" src"" swt")+i*4,4,(sub==1 && mstate2.m_posHorz==i) ? INVERS : 0);
  }
  if(sub==1){
    checkIncDecGen2(event, &mstate2.m_posHorz, 0, 3, 0);
  }
  sub-=2;
  for(uint8_t i=0; i<4; i++){
    y=(i+2)*FH;
    TrainerData1_r0*  td = &g_eeGeneral.trainer.chanMix[i];
    putsChnRaw( 0, y,i+1,0);
    //                sub==i ? (subSub==0 ? BLINK : INVERS) : 0);
    edit = (sub==i && subSub==1);
    lcd_putsnAtt(   4*FW, y, PSTR("off += :=")+3*td->mode,3,
                    edit ? BLINK : 0);
    if(edit) td->mode = checkIncDec_hg( event, td->mode, 0,2); //!! bitfield

    edit = (sub==i && subSub==2);
    lcd_outdezAtt( 11*FW, y, td->studWeight*13/4,
                   edit ? BLINK : 0);
    if(edit) td->studWeight = checkIncDec_hg( event, td->studWeight, -31,31); //!! bitfield

    edit = (sub==i && subSub==3);
    lcd_putsnAtt(  12*FW, y, PSTR("ch1ch2ch3ch4")+3*td->srcChn,3, edit ? BLINK : 0);
    if(edit) td->srcChn = checkIncDec_hg( event, td->srcChn, 0,3); //!! bitfield

    edit = (sub==i && subSub==4);
    putsDrSwitches(15*FW, y, td->swtch, edit ? BLINK : 0);
    if(edit) {
      td->swtch = checkIncDec_hg( event, td->swtch,  -MAX_DRSWITCH, MAX_DRSWITCH); //!! bitfield
      CHECK_LAST_SWITCH(td->swtch,EE_GENERAL|_FL_POSNEG);
    }


  }
  edit = (sub==4);
  y    = 7*FH;
  lcd_putsnAtt(  0*FW, y, PSTR("Cal"),3,(sub==4) ? BLINK : 0);
  if(g_trainerSlaveActive){
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
        beepKey();
      }
    }
  }
  
}
void menuProcSetup1(uint8_t event)
{
  static MState2 mstate2;
  TITLE("WARNINGS");  
  MSTATE_CHECK_V(2,menuTabDiag,1+5);
  int8_t  sub    = mstate2.m_posVert-1 ;
  for(uint8_t i=0; i<5; i++){
    uint8_t y=i*FH+1*FH;
    uint8_t attr = sub==i ? BLINK : 0; 
    lcd_putsnAtt( FW*5,y,PSTR("  THR pos "
                              "  Switches"
                              "  Mem free"
                              "V Bat low "
                              "m Inactive"
                  )+i*10,10,0);
    switch(i){
      case 0: //"THR pos "
      case 1: //"Switches"
      case 2: //"Mem free"
        {
          uint8_t bit = 1<<i;
          bool    val = !(g_eeGeneral.warnOpts & bit);
          lcd_putsAtt( FW*2, y, val ? PSTR("ON"): PSTR("OFF"),attr);
          if(attr)  {
            val = checkIncDec_hg( event, val, 0, 1); //!! bitfield
            if(checkIncDec_Ret && (i==0) && val) // THR warn changed
              setTHR0pos();
          }
          g_eeGeneral.warnOpts |= bit;
          if(val) g_eeGeneral.warnOpts &= ~bit;


          break;
        }
      case 3://"Bat low "
        lcd_outdezAtt(4*FW,y,g_eeGeneral.vBatWarn,attr|PREC1);
        if(attr){
          CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.vBatWarn, 50, 120); //5-10V
        }
        break;
      case 4://"Inactive"
        lcd_outdezAtt(4*FW,y,g_eeGeneral.inactivityMin,attr);
        if(attr){
          CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.inactivityMin, 0, 30);
        }
        break;
    }
  }
}
void menuProcSetup0(uint8_t event)
{
  static MState2 mstate2;
  TITLE("SETUP BASIC");  
  MSTATE_CHECK_V(1,menuTabDiag,1+5);
  int8_t  sub    = mstate2.m_posVert-1 ;

  uint8_t y=1*FH;
  for(uint8_t i=0; i<5; i++,y += FH){
    
    uint8_t attr = sub==i ? BLINK : 0; 
    if(i<4)lcd_putsnAtt( FW*6,y,PSTR("Contrast"
                                     "AdcFilt."
                                     "Light   "
                                     "Beep Mod"
                              )+i*8,8,0);
    switch(i){
      case 0: //Contrast
        lcd_outdezAtt(4*FW,y,g_eeGeneral.contrast,attr);
        if(attr){
          CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.contrast, 20, 45);
          lcdSetRefVolt(g_eeGeneral.contrast);
        }
        break;
      case 1://"AdcFilt."
        lcd_outdezAtt( FW*4, y, g_eeGeneral.adcFilt,attr);
        if(attr)  CHECK_INCDEC_H_GENVAR_BF(event,g_eeGeneral.adcFilt,0,3);
        break;
      case 2://Light
        if(g_eeGeneral.lightSw<=MAX_DRSWITCH){
          putsDrSwitches(0*FW,y,g_eeGeneral.lightSw,attr);
        }else{
          lcd_outdezAtt(4*FW,y,(g_eeGeneral.lightSw-MAX_DRSWITCH)*5,(attr)|PREC1);
          lcd_puts_P( 4*FW,y, PSTR("m"));
        }
        if(attr){
          CHECK_INCDEC_H_GENVAR(event, g_eeGeneral.lightSw, -MAX_DRSWITCH, MAX_DRSWITCH+20);
          CHECK_LAST_SWITCH(g_eeGeneral.lightSw,EE_GENERAL|_FL_POSNEG);
        }
        break;
      case 3:// "Beeper  "
        lcd_outdezAtt( FW*4, y, g_eeGeneral.beepVol,attr);
        if(attr)  CHECK_INCDEC_H_GENVAR_BF(event,g_eeGeneral.beepVol,0,3);
        break;
      case 4://stick Mode
        y += FH;
        lcd_putsAtt( 1*FW, y, PSTR("Mode"),0);//sub==3?INVERS:0);
        lcd_putcAtt( 3*FW, y+FH, '1'+g_eeGeneral.stickMode,attr);
        for(uint8_t i=0; i<4; i++)
        {
          lcd_img(    (6+4*i)*FW, y,   sticks,i,0);
          putsChnRaw( (6+4*i)*FW, y+FH,i+1,0);//sub==3?BLINK:0);
        }
        if(attr){
          CHECK_INCDEC_H_GENVAR(event,g_eeGeneral.stickMode,0,3);
        }
        break;
    }
  }
}

uint16_t s_timeCumTot;    
uint16_t s_timeCumAbs;  //laufzeit in 1/16 sec
uint16_t s_timeCumThr;  //gewichtete laufzeit in 1/16 sec
uint16_t s_timeCum16ThrP; //gewichtete laufzeit in 1/16 sec
uint8_t  s_timerState;
#define TMR_OFF     0
#define TMR_RUNNING 1
#define TMR_BEEPING 2
#define TMR_BEEPSTOPPED 3
int16_t  s_timerVal;
void timer(uint8_t val)
{
  static uint16_t s_time;
  static uint16_t s_cnt;
  static uint16_t s_sum;
  s_cnt++;
  s_sum+=val;
  if((g_tmr10ms-s_time)<100) //1 sec
    return;
  s_time += 100;
  val     = s_sum/s_cnt;
  s_sum  -= val*s_cnt; //rest
  s_cnt   = 0;

  s_timeCumTot           += 1;
  s_timeCumAbs           += 1;
  if(val) s_timeCumThr   += 1;
  s_timeCum16ThrP        += val/2;

  s_timerVal = g_model.tmrVal;
  switch(g_model.tmrMode)
  {
    case TMRMODE_NONE:
      s_timerState = TMR_OFF;
      return;
    case TMRMODE_THR_REL:
      s_timerVal -= s_timeCum16ThrP/16;
      //s_timerVal  = s_timerVal * (s_timeCumAbs+10)/(s_timeCum16ThrP/16+10);
      break;
    case TMRMODE_THR:     
      s_timerVal -= s_timeCumThr;
      break;
    case TMRMODE_ABS:
      s_timerVal -= s_timeCumAbs;
      //s_timeCum16 += 16;
      break;
  }
  switch(s_timerState)
  {
    case TMR_OFF:
      if(g_model.tmrMode != TMRMODE_NONE) s_timerState=TMR_RUNNING;
      break;
    case TMR_RUNNING:
      //if(s_timerVal<=0 && g_model.tmrVal) s_timerState=TMR_BEEPING;
      if(s_timerVal<=MAX_ALERT_TIME && g_model.tmrVal) s_timerState=TMR_BEEPING;
      break;
    case TMR_BEEPING:
      //if(s_timerVal <= -MAX_ALERT_TIME)   s_timerState=TMR_STOPPED;
      if(s_timerVal < 0)                  s_timerState=TMR_BEEPSTOPPED;
      if(g_model.tmrVal == 0)             s_timerState=TMR_RUNNING;
      break;
    case TMR_BEEPSTOPPED:
      break;
  }

  if(s_timerState==TMR_BEEPING){
    static int16_t last_tmr;
    if(last_tmr != s_timerVal){
      last_tmr   = s_timerVal;
      if(s_timerVal>20  )       {if((s_timerVal&1)==0)beepTmr();}
      else if(s_timerVal>10  )  {beepTmr();}
      else if(s_timerVal>0)     {beepTmrDbl();}
      else                      {beepTmrLong();}
    }
  }
}


#define MAXTRACE 120
uint8_t s_traceBuf[MAXTRACE];
uint16_t s_traceWr;
uint16_t s_traceCnt;
void trace(uint8_t val)
{
  if(val>31)val=31;
  if(g_eeGeneral.thr0pos > 8) val=31-val; //inverted throttle usage

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


uint16_t g_tmr1Latency_max;
uint16_t g_tmr1Latency_min = 0x7ff;
uint16_t g_timeMain;
uint16_t g_timePerOut;
void menuProcStatistic2(uint8_t event)
{
  TITLE("STAT2");  
  switch(event)
  {
    case EVT_KEY_FIRST(KEY_MENU):
      g_tmr1Latency_min = 0x7ff;
      g_tmr1Latency_max = 0;
      g_timeMain    = 0;
      g_timePerOut  = 0;
      g_badAdc=g_allAdc=0;
      beepKey();
      break;
    case EVT_KEY_FIRST(KEY_DOWN):
      chainMenu(menuProcStatistic); 
      break;
    case EVT_KEY_FIRST(KEY_UP):
    case EVT_KEY_FIRST(KEY_EXIT):
      chainMenu(menuProc0); 
      break;
  }
  lcd_puts_P( 0*FW,  1*FH, PSTR("tmr1Lat max    us"));
  lcd_outdez(14*FW , 1*FH, g_tmr1Latency_max/2 );
  lcd_puts_P( 0*FW,  2*FH, PSTR("tmr1Lat min    us"));
  lcd_outdez(14*FW , 2*FH, g_tmr1Latency_min/2 );
  lcd_puts_P( 0*FW,  3*FH, PSTR("tmr1 Jitter    us"));
  lcd_outdez(14*FW , 3*FH, (g_tmr1Latency_max - g_tmr1Latency_min) /2 );
  lcd_puts_P( 0*FW,  4*FH, PSTR("tmain          ms"));
  lcd_outdezAtt(14*FW , 4*FH, g_timeMain*5/8,PREC1 );
  lcd_puts_P( 0*FW,  5*FH, PSTR("tperOut        ms"));
  lcd_outdezAtt(14*FW , 5*FH, g_timePerOut*5/8 ,PREC1);
  
  lcd_puts_P( 0*FW,  6*FH, PSTR("adc err        %"));

  if(g_allAdc > 300 ){
    g_allAdc /= 4;
    g_badAdc /= 4;
  }
  if(g_allAdc) lcd_outdez(14*FW , 6*FH, g_badAdc*100/g_allAdc );

  
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

  lcd_puts_P(  1*FW, FH*1, PSTR("TME"));
  putsTime(    4*FW, FH*1, s_timeCumAbs, 0, 0);
  lcd_puts_P( 17*FW, FH*1, PSTR("TOT"));
  putsTime(   10*FW, FH*1, s_timeCumTot,      0, 0);

  lcd_puts_P(  1*FW, FH*2, PSTR("THR"));
  putsTime(    4*FW, FH*2, s_timeCumThr, 0, 0);
  lcd_puts_P( 17*FW, FH*2, PSTR("THR%"));
  putsTime(   10*FW, FH*2, s_timeCum16ThrP/16, 0, 0);


  uint16_t traceRd = s_traceCnt>MAXTRACE ? s_traceWr : 0;
  uint8_t x=5;
  uint8_t y=60;
  lcd_hline(x-3,y,120+3+3);
  lcd_hlineStip(x-3,y-16,120+3+3,0x11);
  lcd_hlineStip(x-3,y-32,120+3+3,0x11);
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
  static uint8_t   sub;
  static MenuFuncP s_lastPopMenu[2];

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
      if(getEventDbl(event)==2 && s_lastPopMenu[1]){
        pushMenu(s_lastPopMenu[1]);
        break;
      }
      if(sub<1) {
        sub=sub+1;
        beepKey();
      }
      break;
    case EVT_KEY_LONG(KEY_RIGHT):
      pushMenu(menuProcModelSelect);//menuProcExpoAll); 
      killEvents(event);
      break;
    case EVT_KEY_FIRST(KEY_LEFT):
      if(getEventDbl(event)==2 && s_lastPopMenu[0]){
        pushMenu(s_lastPopMenu[0]);
        break;
      }
      if(sub>0) {
        sub=sub-1;
        beepKey();
      }
      break;
    case EVT_KEY_LONG(KEY_LEFT):
      pushMenu(menuProcSetup0);
      killEvents(event);
      break;
#define MAX_VIEWS 2
    case EVT_KEY_BREAK(KEY_UP):
      g_eeGeneral.view += 2;
    case EVT_KEY_BREAK(KEY_DOWN):
      g_eeGeneral.view += MAX_VIEWS-1; 
      g_eeGeneral.view %= MAX_VIEWS;
      eeDirty(EE_GENERAL);
      beepKey();
      break;
    case EVT_KEY_LONG(KEY_UP):
      chainMenu(menuProcStatistic); 
      killEvents(event);
      break;
    case EVT_KEY_LONG(KEY_DOWN):
      chainMenu(menuProcStatistic2); 
      killEvents(event);
      break;
    case EVT_KEY_FIRST(KEY_EXIT):
      if(s_timerState==TMR_BEEPING) {
        s_timerState = TMR_BEEPSTOPPED;
        beepKey();
      }
      break;
    case EVT_KEY_LONG(KEY_EXIT):
      s_timerState = TMR_OFF; //is changed to RUNNING dep from mode
      s_timeCumAbs=0;
      s_timeCumThr=0;
      s_timeCum16ThrP=0;
      beepKey();
      break;
    case EVT_ENTRY_UP:
      s_lastPopMenu[sub] = lastPopMenu();
    case EVT_ENTRY:
      killEvents(KEY_EXIT);
      killEvents(KEY_UP);
      killEvents(KEY_DOWN);
      break;
  }


  uint8_t x=FW*2;
  lcd_putsAtt(x,0,PSTR("Th9x"),sub==0 ? INVERS : 0);
  lcd_putsnAtt(x+ 5*FW,   0*FH, g_model.name ,sizeof(g_model.name),sub==1 ? BSS_INVERS : BSS_NO_INV);
  if(g_trainerSlaveActive){
    lcd_putsAtt(x,1*FH,PSTR("Stud"), BLINK);
  }
  lcd_puts_P(  x+ 5*FW,   1*FH,    PSTR("BAT"));
  putsVBat(x+ 8*FW,1*FH, g_vbat100mV < g_eeGeneral.vBatWarn ? BLINK : 0);

  //if(g_model.tmrMode != TMRMODE_NONE){
  if(s_timerState != TMR_OFF){
    //int16_t tmr = g_model.tmrVal - s_timeCum16/16;
    uint8_t att = DBLSIZE | (s_timerState==TMR_BEEPING ? (s_timerVal&1 ? 0 : INVERS) : 0);
    //putsTime( x+8*FW, FH*2, tmr, att,att);
    putsTime( x+8*FW, FH*2, s_timerVal, att,att);
    lcd_putsnAtt(   x+ 4*FW, FH*2, PSTR(" TME THRTHR%")-4+4*g_model.tmrMode,4,0);
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
  for(uint8_t i=0; i<NUM_CHNOUT; i++)
  {
    uint8_t x0,y0;
    switch(g_eeGeneral.view)
    {
      case 0:
        x0 = (i%4*9+3)*FW/2;
        y0 = i/4*FH+40;
        // *1000/512 =   *2 - 24/512
        lcd_outdezAtt( x0+4*FW , y0, g_chans512[i]*2-g_chans512[i]/21,PREC1 );
        break;
      case 1:
#define WBAR2 (50/2)
        x0       = i<4 ? 128/4+4 : 128*3/4-4;
        y0       = 38+(i%4)*5;
        int8_t l = (abs(g_chans512[i])+WBAR2/2) * WBAR2 / 512;
        lcd_hlineStip(x0-WBAR2,y0,WBAR2*2+1,0x55);
        lcd_vline(x0,y0-2,5);
        if(g_chans512[i]>0){
          x0+=1;
        }else{
          x0-=l;
        }
        lcd_hline(x0,y0+1,l);
        lcd_hline(x0,y0-1,l);
        break;
    }
  }

}

static int16_t s_cacheLimitsMin[NUM_CHNOUT];
static int16_t s_cacheLimitsMax[NUM_CHNOUT];

void calcLimitCache()
{
  if(s_limitCacheOk) return;
  printf("calc limit cache\n");
  s_limitCacheOk = true;
  for(uint8_t i=0; i<NUM_CHNOUT; i++){
    //int16_t v = idx2val12255(g_model.limitData[i].min-40);
    int16_t v;
    v = lim2val(g_model.limitData[i].min,-40);
    s_cacheLimitsMin[i] = 5*v + v/8 ; // *512/100 ~  *(5 1/8)
    //v = idx2val12255(g_model.limitData[i].max+40);
    v = lim2val(g_model.limitData[i].max,+40);
    s_cacheLimitsMax[i] = 5*v + v/8 ; // *512/100 ~  *(5 1/8)
  }
}




int16_t intpol(int16_t x, uint8_t idx) // -100, -75, -50, -25, 0 ,25 ,50, 75, 100
{
#define D9 (RESX * 2 / 8)
#define D5 (RESX * 2 / 4)
#define D3 (RESX * 2 / 2)
  uint8_t cvTyp=curveTyp(idx);
  int8_t *crv = curveTab(idx);
  /*  bool    cv9 = idx >= 2;
  int8_t *crv = cv9 ? g_model.curves9[idx-2] : g_model.curves5[idx];*/
  int16_t erg;

  x+=RESXu;
  if(x < 0) {
    erg = crv[0]             * (RESX/2);
  } else if(x >= (RESX*2)) {
    erg = crv[cvTyp-1] * (RESX/2);
  } else {
    int16_t a,dx;
    switch(cvTyp){
      case 9:	a   = (uint16_t)x / D9;	dx  =((uint16_t)x % D9) * 2; break;
      case 5:	a   = (uint16_t)x / D5;	dx  =((uint16_t)x % D5)    ; break;
      default: /*case 3*/	a   = (uint16_t)x / D3;	dx  =((uint16_t)x % D3) / 2; break;
/*    } else {
      a   = (uint16_t)x / D5;
      dx  = (uint16_t)x % D5;*/
    }
    erg  = (int16_t)crv[a]*(D5-dx) + (int16_t)crv[a+1]*(dx);
  }
  return erg / 50; // 100*D5/RESX;
}

uint16_t pulses2MHz[60];

/*
  dt=[ 1, 1,1,1,1,1,1,2,1,3,2,3,4,6,9];dx=[18,13,9,6,4,3,2,3,1,2,1,1,1,1,1]
  rp=1; 15.times{|i| r=dx[i]*100.0/(dt[i]); printf("%2d: rate=%4d i/s full=%5.1fs %3.1f\n",i+1,r,1024.0/r,rp/r);rp=r}
 1: rate=1800 i/s full=  0.6s 0.0
 2: rate=1300 i/s full=  0.8s 1.4
 3: rate= 900 i/s full=  1.1s 1.4
 4: rate= 600 i/s full=  1.7s 1.5
 5: rate= 400 i/s full=  2.6s 1.5
 6: rate= 300 i/s full=  3.4s 1.3
 7: rate= 200 i/s full=  5.1s 1.5
 8: rate= 150 i/s full=  6.8s 1.3
 9: rate= 100 i/s full= 10.2s 1.5
10: rate=  66 i/s full= 15.4s 1.5
11: rate=  50 i/s full= 20.5s 1.3
12: rate=  33 i/s full= 30.7s 1.5
13: rate=  25 i/s full= 41.0s 1.3
14: rate=  16 i/s full= 61.4s 1.5
15: rate=  11 i/s full= 92.2s 1.5
*/
//                                     1  2 3 4 5 6 7 8 9 0 1 2 3 4 5
//                                                        1 1 1 1 1 1 
static prog_uint8_t APM s_slopeDlt[]={18,13,9,6,4,3,2,3,1,2,1,1,1,1,1}; 
static prog_uint8_t APM s_slopeTmr[]={ 1, 1,1,1,1,1,1,2,1,3,2,3,4,6,9};

uint16_t slopeFull100ms(uint8_t speed) //zeit fuer anstieg von -512 bis 512 in 100ms
{
  if(speed==0) return 0;
  int8_t  delta    = pgm_read_byte(&s_slopeDlt[speed-1]);
  uint8_t timerend = pgm_read_byte(&s_slopeTmr[speed-1]); // *10ms
  // 1024* timerend*10ms / delta
  return (102 * timerend + delta / 2 ) / delta;     
}

void perOut(int16_t *chanOut)
{
  static int16_t anas     [NUM_XCHNRAW];

  g_sumAna=0;
  for(uint8_t i=0;i<7;i++){        // calc Sticks

    //Normierung  [0..1024] ->   [-512..512]
    
    int16_t v= anaIn(i);
    g_sumAna += (uint8_t)v;
    v -= g_eeGeneral.calibMid[i];
    v  =  v * (int32_t)RESX /  (max((int16_t)100,
                                    (v>0 ? 
                                     g_eeGeneral.calibSpanPos[i] : 
                                     g_eeGeneral.calibSpanNeg[i])));

    if(v <= -RESX) v = -RESX;
    if(v >=  RESX) v =  RESX;

    if(i<4){
      anaCalib[i] = v; //for show in expo
      bool expSw=getSwitch(g_model.expoData[i].drSw,0);
      v  = expo(v,
                expSw ?
                g_model.expoData[i].expDr           :
                g_model.expoData[i].expNorm
      );
      //int32_t x = (int32_t)v * (getSwitch(g_model.expoData[i].drSw,0) ? 
      v = (int32_t)v * (expSw ? 
                        g_model.expoData[i].expSwWeight+100 :
                        g_model.expoData[i].expNormWeight+100) / 100;
      //v = (int16_t)x;
      TrainerData1_r0*  td = &g_eeGeneral.trainer.chanMix[i];
      if(g_trainerSlaveActive && td->mode && getSwitch(td->swtch,1)){
        uint8_t chStud = td->srcChn;
        int16_t vStud  = (g_ppmIns[chStud]- g_eeGeneral.trainer.calib[chStud])*
          td->studWeight/31;

        switch(td->mode)
        {
          case 1: v += vStud;   break; // add-mode
          case 2: v  = vStud;   break; // subst-mode
        }
      }

      //trace throttle
      if(THRCHN == i)  //stickMode=0123 -> thr=2121
        trace((v+512)/32); //trace thr 0..31

      //trim
      v += trimVal(i); // + g_model.trimData[i].trimDef;
    }
    anas[i] = v; //10+1 Bit
  }
  anas[7] = 512; //100% fuer MAX
  anas[8] = 512; //100% fuer MAX
/* In anaNoTrim stehen jetzt die Werte ohne Trimmung implementiert -512..511
   in anas mit Trimmung */

  static int32_t chans[NUM_XCHNOUT];          // Ausgaenge + intermidiates
  memset(chans,0,sizeof(chans));		// Alle Ausgaenge auf 0

  //mixer loop
  for(uint8_t stage=1; stage<=2; stage++){
    if(stage==2){
      for(uint8_t i = NUM_CHNOUT;  i<NUM_XCHNOUT; i++){
        uint8_t   j = i - NUM_XCHNOUT + NUM_XCHNRAW;
        if(chans[i])
          // anaNoTrim[j]= 
          anas[j]=
            (chans[i] + (chans[i]>0 ? 100/2 : -100/2)) / 100;
        else
          // anaNoTrim[j]= 
          anas[j]=0;
      }
    }
    for(uint8_t i=0;i<MAX_MIXERS;i++){
      MixData_r0 &md = g_model.mixData[i];

      static uint8_t timer[MAX_MIXERS];
      static int16_t act  [MAX_MIXERS];
      uint8_t destCh = md.destCh;

      if(stage==1){
        if(destCh<=NUM_CHNOUT) continue; //im ersten durchlauf alle intermediates X1-X4
      }else{
        if(destCh>NUM_CHNOUT) break;     //im zweiten Durchlauf alle outputs CH1-CH8
      }
      if(destCh==0) break;

      //achtung 0=NC heisst switch nicht verwendet -> Zeile immer aktiv

      if( !getSwitch(md.swtch,1) &&
          (md.srcRaw <= 4 ||  md.srcRaw > 9) //P1 P2 P3 MAX FUL
          //          md.srcRaw != 8         && //MAX
          //          md.srcRaw != 9            //FUL
      ){
        currMixerVal=0;
        goto mixend;     // Zeile abgeschaltet nicht wenn src==MAX oder FULL
      }

      int16_t v;
      v = !getSwitch(md.swtch,1) ? ( //P1 P2 P3     FUL
        (md.srcRaw == 5 || md.srcRaw == 6 || md.srcRaw == 7 || md.srcRaw == 9 )
                                    ? -512 : 0) : anas[md.srcRaw-1];
      if(md.weight<0) v=-v;
      if (md.speedUp || md.speedDown)
      {
        int16_t     diff     = v - act[i];
        if(diff){
          uint8_t   speed    = (diff > 0) ? md.speedUp : md.speedDown;
          if(speed){
            uint8_t timerend = pgm_read_byte(&s_slopeTmr[speed-1]);
            int8_t  dlt      = pgm_read_byte(&s_slopeDlt[speed-1]);
            dlt              = min((int16_t)dlt, abs(diff)) ;
            if(diff < 0) dlt = -dlt;

            if (--timer[i] != 0)
            {
              if (timer[i] > timerend) timer[i] = timerend;
            }
            else
            {
              act[i]        += dlt;
              timer[i]       = timerend;
            }
          }else{
            act[i]   = v;
            timer[i] = 0;
          }
        }
        v = act[i];
      }
      if(md.curve) v = intpol(v, md.curve - 1);

    {
      int32_t dv=(int32_t)v*(abs(md.weight)); // 10+1 Bit + 7 = 17+1
      if(currMixerLine==i){
        currMixerVal=dv; //for mixer debug
        //mov32div8to16(currMixerVal,dv);
      }
      chans[destCh-1] += dv; //Mixerzeile zum Ausgang addieren (dv + (dv>0 ? 100/2 : -100/2))/(100);
    }
      mixend:
      if(currMixerLine==i){
        currMixerSum=chans[md.destCh-1];
        //mov32div8to16(currMixerSum,chans[destCh-1]);
      }
      
    }
  }

  //limit + revert loop
  calcLimitCache();
  for(uint8_t i=0;i<NUM_CHNOUT;i++){
    int32_t v32 = chans[i];
    int16_t v   = 0;
    if(g_model.limitData[i].scale){
      if(v32>0)      v = v32 * s_cacheLimitsMax[i] / 51200;
      else if(v32<0) v = -v32 * s_cacheLimitsMin[i] / 51200;
    }else{
      if(v32) v = (v32 + (v32 > 0 ? 100/2 : -100/2)) / 100;
    }

    v = max(s_cacheLimitsMin[i],v);
    v = min(s_cacheLimitsMax[i],v);

    if(g_model.limitData[i].revert) v=-v;
    //offset after limit -> 
    v+=g_model.limitData[i].offset*5; // 512/100  //issue 40

    cli();
    chanOut[i] = v; //copy consistent word to int-level
    sei();
  }

#ifdef xSIM
  static int s_cnt;
  if(s_cnt++%100==0){
    setupPulses();
    for(unsigned j=0; j<DIM(pulses2MHz); j++){
      printf(" %d:%d",j&1,pulses2MHz[j]);
      if(pulses2MHz[j]==0) break;
    }
    printf("\n\n");
  }
#endif

}



