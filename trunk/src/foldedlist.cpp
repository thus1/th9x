
#include "foldedlist.h"


FoldedList::Line FoldedList::s_lines[MAX_MIXERS+NUM_XCHNOUT+1];
//indize:
//
// IDT  data tab
// ISL  select sequence
// IFL  foldedlist
// IFLr rel. foldedlist
//
//for construction of FoldedList
uint8_t FoldedList::s_prepCurrCh;  
uint8_t FoldedList::s_prepCurrIFL; //IFL
uint8_t FoldedList::s_prepCurrISL; //ISL
uint8_t FoldedList::s_prepCurrIDT; //IDT
//for iteration of FoldedList
uint8_t FoldedList::s_iterOfsIFL;  //IFL first visible
uint8_t FoldedList::s_iterPosIFL;  //IFL curr
uint8_t FoldedList::s_iterHitIFL;  //IFLr selected
uint8_t FoldedList::s_subISL;      //ISL
uint8_t FoldedList::s_iterMinISL;  //ISL make visible
bool    FoldedList::s_isSelectedCh;
bool    FoldedList::s_isSelectedDat;
bool    FoldedList::s_editMode; //edit linesequence

//variables for edit/insert one line
uint8_t FoldedList::s_currIDTOld;   //IDT before
uint8_t FoldedList::s_currIDT;  //IDT curr
uint8_t FoldedList::s_currDestCh;
bool    FoldedList::s_currInsMode; //insert or edit


void FoldedList::init()
{
  s_prepCurrCh  = 0;
  s_prepCurrIFL= 0;
  s_prepCurrISL = 1;
  s_prepCurrIDT =-1;
  memset(s_lines,0,sizeof(s_lines));
  // s_iterOfsIFL   = 0; only on entry
}
void FoldedList::addDat(uint8_t ch, uint8_t idt)
{
  if(fill(ch))
    s_lines[s_prepCurrIFL].showCh = true;
  s_lines[s_prepCurrIFL].chId     = s_prepCurrCh;
  s_lines[s_prepCurrIFL].idt      = s_prepCurrIDT = idt;
  s_lines[s_prepCurrIFL].showDat  = true;
  s_lines[s_prepCurrIFL].islDat   = s_prepCurrISL++;
  s_prepCurrIFL++;
}
void FoldedList::show(){
#ifdef SIM
  //for(uint8_t i=0; i<DIM(s_mixTab); i++){
  for(uint8_t i=0; i<14; i++){
    //MixTab *mt=s_mixTab+i;
    FoldedList::Line* line=&s_lines[i];
    printf( "chId %2d islCh%c%2d islDat%c%2d idt %d\n",
            line->chId,
            line->showCh?'*':' ', line->islCh,
            line->showDat?'*':' ', line->islDat,
            line->idt);
  }
#endif
}
bool FoldedList::fill(uint8_t ch) //helper func for construction
{
  if(ch > s_prepCurrCh) {
    while(1){
      if(s_prepCurrIFL>0) s_lines[s_prepCurrIFL-1].islCh=s_prepCurrISL++;
      s_prepCurrCh++;
      if(s_prepCurrCh>=ch) break;
      s_lines[s_prepCurrIFL].showCh = true;
      s_lines[s_prepCurrIFL].chId   = s_prepCurrCh;
      s_lines[s_prepCurrIFL].idt    = s_prepCurrIDT; //insert behind
      s_prepCurrIFL++;
      assert(s_prepCurrIFL<=DIM(s_lines));
    }
    return true;
  }else{
    return false;
  }
}
FoldedList::Line* FoldedList::firstLine(int8_t sub){
  s_currIDTOld  = s_currIDT;
  s_subISL     = sub;
  s_iterPosIFL = s_iterOfsIFL;
  Line *l=&s_lines[s_iterPosIFL];
  s_iterMinISL = l->islDat ? l->islDat : l->islCh;
  s_iterHitIFL = 0;
  return nextLine(6);
}
FoldedList::Line* FoldedList::nextLine(uint8_t lines){
  int8_t i = s_iterPosIFL-s_iterOfsIFL;
  Line  *l  = &s_lines[s_iterPosIFL];
  if(i>=lines  || !(l->showCh || l->showDat) ) {
    //Line *l=&s_lines[s_iterPosIFL-1];
    l--;
    uint8_t iterMaxISL = l->islCh ? l->islCh : l->islDat;

    //printf("s_subISL%d,s_iterOfsIFL%d,s_iterHitIFL%d,s_iterMinISL%d,iterMax%d\n",s_subISL,s_iterOfsIFL,s_iterHitIFL,s_iterMinISL,iterMax);
    if( s_subISL!=0 &&  s_iterHitIFL==0) { //versuche die Marke zu finden
      if(s_subISL < s_iterMinISL)      s_iterOfsIFL = max(0,s_iterOfsIFL-1);
      if(s_subISL > iterMaxISL)      s_iterOfsIFL++;
    }
    else if(s_iterHitIFL<=2)          s_iterOfsIFL = max(0,s_iterOfsIFL-1);
    else if(s_iterHitIFL>=(lines-1) && i>=lines)  s_iterOfsIFL++;
    return 0;
  }
  s_isSelectedCh  = s_subISL > 0 && s_subISL == l->islCh; 
  s_isSelectedDat = s_subISL > 0 && s_subISL == l->islDat; 

  if(s_isSelectedCh){ //handle CHx is selected 
    s_currIDT     = l->idt+1;
    s_currInsMode = true;
    s_currDestCh     = l->chId;
    s_iterHitIFL      = i+1;
    // printf("s_currMixIdx=%d\n",s_currMixIdx);
  }
  if(s_isSelectedDat){ //handle dat is selected 
    s_currIDT     = l->idt;
    s_currInsMode = false;
    s_currDestCh     = l->chId;
    s_iterHitIFL      = i+1;
    // printf("s_currMixIdx=%d\n",s_currMixIdx);
  }
  s_iterPosIFL++;
  return l;
}

uint8_t FoldedList::doEvent(uint8_t event, bool subChanged, void*array,uint8_t dimArr, uint8_t szeElt)
{
  uint8_t ret=0;
  switch(event)
  {
    case EVT_ENTRY:
      FoldedList::s_iterOfsIFL=0;
    case EVT_ENTRY_UP:
      s_editMode=false;
      break;
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(s_editMode){
        s_editMode = false;
        beepKey();
        killEvents(event); //cut off MSTATE_CHECK (KEY_BREAK)
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):
      if(s_currInsMode) break;
      killEvents(event); //cut off 
      if(s_editMode)
      {
        beepKey();
        ret = FoldedListDup;
        goto ret_dup;
      }
      s_editMode=true;
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(s_subISL<1) break;
      if(s_currInsMode){
        ret=FoldedListNew;
        goto ret_dup;
      }
      return FoldedListEdit;
  }

  if(s_editMode && subChanged) // && s_currIDTOld != s_currMixIdx)
  {
    //printf("subOld %d sub %d\n",subOld,sub);
    //if(! moveMixLine(mixIdOld,s_currMixIdx,s_currMixInsMode))
      //      s_editMode = false;
    STORE_MODELVARS;
    if(s_currInsMode){
      return s_currIDTOld <  s_currIDT ? FoldedListCntUp : FoldedListCntDown;
    }else{
      //swap
      if( (s_currIDTOld<=s_prepCurrIDT) && (s_currIDT<=s_prepCurrIDT)){
        printf("swap %d %d %d\n",s_currIDTOld,s_currIDT,s_prepCurrIDT);
        char* p=(char*)array + (uint8_t)(szeElt * (s_currIDT));
        char* q=(char*)array + (uint8_t)(szeElt * (s_currIDTOld));
        for(uint8_t i=szeElt; i>0; i--,p++,q++){
          char c = *p; *p=*q; *q=c;
        }
        return FoldedListSwap;
      }else{
        s_editMode=false;
      }
    }
  }
  return 0; 
  
  ret_dup:
  memmove(
    (char*)array + (uint8_t)(szeElt * (uint8_t)(s_currIDT+1)),
    (char*)array + (uint8_t)(szeElt *  s_currIDT),
    (uint8_t)(szeElt * (uint8_t)(dimArr-s_currIDT-1))
  );
  STORE_MODELVARS;
  return ret;

}

