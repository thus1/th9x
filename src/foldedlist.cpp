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

 */

#include "foldedlist.h"


FoldedList FoldedList::inst;

#if 0
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
#endif

void FoldedList::init()
{
  inst.s_prepCurrCh  = 0;
  inst.s_prepCurrIFL= 0;
  inst.s_prepCurrISL = 1;
  inst.s_prepCurrIDT =-1;
  memset(inst.s_lines,0,sizeof(inst.s_lines));
  // inst.s_iterOfsIFL   = 0; only on entry
}
void FoldedList::addDat(uint8_t ch, uint8_t idt)
{
  if(fill(ch))
    inst.s_lines[inst.s_prepCurrIFL].showCh = true;
  inst.s_lines[inst.s_prepCurrIFL].chId     = inst.s_prepCurrCh;
  inst.s_lines[inst.s_prepCurrIFL].idt      = inst.s_prepCurrIDT = idt;
  inst.s_lines[inst.s_prepCurrIFL].showDat  = true;
  inst.s_lines[inst.s_prepCurrIFL].islDat   = inst.s_prepCurrISL++;
  inst.s_prepCurrIFL++;
}
void FoldedList::show(){
#ifdef SIM
  //for(uint8_t i=0; i<DIM(inst.s_mixTab); i++){
  for(uint8_t i=0; i<14; i++){
    //MixTab *mt=inst.s_mixTab+i;
    FoldedList::Line* line=&inst.s_lines[i];
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
  if(ch > inst.s_prepCurrCh) {
    while(1){
      if(inst.s_prepCurrIFL>0) inst.s_lines[inst.s_prepCurrIFL-1].islCh=inst.s_prepCurrISL++;
      inst.s_prepCurrCh++;
      if(inst.s_prepCurrCh>=ch) break;
      inst.s_lines[inst.s_prepCurrIFL].showCh = true;
      inst.s_lines[inst.s_prepCurrIFL].chId   = inst.s_prepCurrCh;
      inst.s_lines[inst.s_prepCurrIFL].idt    = inst.s_prepCurrIDT; //insert behind
      inst.s_prepCurrIFL++;
      assert(inst.s_prepCurrIFL<=DIM(inst.s_lines));
    }
    return true;
  }else{
    return false;
  }
}
FoldedList::Line* FoldedList::firstLine(int8_t sub){
  inst.s_currIDTOld  = inst.s_currIDT;
  inst.s_subISL     = sub;
  inst.s_iterPosIFL = inst.s_iterOfsIFL;
  Line *l=&inst.s_lines[inst.s_iterPosIFL];
  inst.s_iterMinISL = l->islDat ? l->islDat : l->islCh;
  inst.s_iterHitIFL = 0;
  return nextLine(6);
}
FoldedList::Line* FoldedList::nextLine(uint8_t lines){
  int8_t i = inst.s_iterPosIFL-inst.s_iterOfsIFL;
  Line  *l  = &inst.s_lines[inst.s_iterPosIFL];
  if(i>=lines  || !(l->showCh || l->showDat) ) {
    //Line *l=&inst.s_lines[inst.s_iterPosIFL-1];
    l--;
    uint8_t iterMaxISL = l->islCh ? l->islCh : l->islDat;

    //printf("inst.s_subISL%d,inst.s_iterOfsIFL%d,inst.s_iterHitIFL%d,inst.s_iterMinISL%d,iterMax%d\n",inst.s_subISL,inst.s_iterOfsIFL,inst.s_iterHitIFL,inst.s_iterMinISL,iterMax);
    if( inst.s_subISL!=0 &&  inst.s_iterHitIFL==0) { //versuche die Marke zu finden
      if(inst.s_subISL < inst.s_iterMinISL)      inst.s_iterOfsIFL = max(0,inst.s_iterOfsIFL-1);
      if(inst.s_subISL > iterMaxISL)      inst.s_iterOfsIFL++;
    }
    else if(inst.s_iterHitIFL<=2)          inst.s_iterOfsIFL = max(0,inst.s_iterOfsIFL-1);
    else if(inst.s_iterHitIFL>=(lines-1) && i>=lines)  inst.s_iterOfsIFL++;
    return 0;
  }
  inst.s_isSelectedCh  = inst.s_subISL > 0 && inst.s_subISL == l->islCh; 
  inst.s_isSelectedDat = inst.s_subISL > 0 && inst.s_subISL == l->islDat; 

  if(inst.s_isSelectedCh){ //handle CHx is selected 
    inst.s_currIDT     = l->idt+1;
    inst.s_currInsMode = true;
    inst.s_currDestCh     = l->chId;
    inst.s_iterHitIFL      = i+1;
    // printf("inst.s_currMixIdx=%d\n",inst.s_currMixIdx);
  }
  if(inst.s_isSelectedDat){ //handle dat is selected 
    inst.s_currIDT     = l->idt;
    inst.s_currInsMode = false;
    inst.s_currDestCh     = l->chId;
    inst.s_iterHitIFL      = i+1;
    // printf("inst.s_currMixIdx=%d\n",inst.s_currMixIdx);
  }
  inst.s_iterPosIFL++;
  return l;
}

uint8_t FoldedList::doEvent(uint8_t event, bool subChanged, void*array,uint8_t dimArr, uint8_t szeElt)
{
  uint8_t ret=0;
  switch(event)
  {
    case EVT_ENTRY:
      FoldedList::inst.s_iterOfsIFL=0;
    case EVT_ENTRY_UP:
      inst.s_editMode=false;
      break;
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(inst.s_editMode){
        inst.s_editMode = false;
        beepKey();
        killEvents(event); //cut off MSTATE_CHECK (KEY_BREAK)
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):
      if(inst.s_currInsMode) break;
      killEvents(event); //cut off 
      if(inst.s_editMode)
      {
        beepKey();
        ret = FoldedListDup;
        goto ret_dup;
      }
      inst.s_editMode=true;
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(inst.s_subISL<1) break;
      if(inst.s_currInsMode){
        ret=FoldedListNew;
        goto ret_dup;
      }
      return FoldedListEdit;
  }

  if(inst.s_editMode && subChanged) // && inst.s_currIDTOld != inst.s_currMixIdx)
  {
    STORE_MODELVARS;
    if(inst.s_currInsMode){
      return inst.s_currIDTOld <  inst.s_currIDT ? FoldedListCntUp : FoldedListCntDown;
    }else{
      //swap
      if( (inst.s_currIDTOld<=inst.s_prepCurrIDT) && (inst.s_currIDT<=inst.s_prepCurrIDT)){
        printf("swap %d %d %d\n",inst.s_currIDTOld,inst.s_currIDT,inst.s_prepCurrIDT);
        memswap((char*)array + (uint8_t)(szeElt * (inst.s_currIDT)),
                (char*)array + (uint8_t)(szeElt * (inst.s_currIDTOld)),
                szeElt);
        return FoldedListSwap;
      }else{
        inst.s_editMode=false;
      }
    }
  }
  return 0; 
  
  ret_dup:
  if((uint8_t)(inst.fillLevel())>=dimArr){
    //printf("currIDT %d dimArr %d\n",inst.s_prepCurrIDT,dimArr);
    beepErr();
    return 0;
  }

  memmove(
    (char*)array + (uint8_t)(szeElt * (uint8_t)(inst.s_currIDT+1)),
    (char*)array + (uint8_t)(szeElt *  inst.s_currIDT),
    (uint8_t)(szeElt * (uint8_t)(dimArr-inst.s_currIDT-1))
  );
  STORE_MODELVARS;
  return ret;

}

