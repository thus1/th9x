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


void FoldedList::init(void*array,uint8_t dimArr, uint8_t szeElt, ChProc* chProc,uint8_t numChn)
{
  inst.m_prepArray   =array;
  inst.m_prepDimArr  =dimArr;
  inst.m_prepSzeElt  =szeElt;
  inst.m_chProc      =chProc;
  inst.m_numChn      =numChn;
  // inst.m_iterOfsIFL   = 0; only on entry

  bool failed;
  uint8_t idt;
  do{
    failed=false;
    inst.m_prepCurrCh  = 0;
    inst.m_prepCurrIFL = 0;
    inst.m_prepCurrISL = 1;
    //inst.m_prepCurrIDT = -1;
    memset(inst.m_lines,0,sizeof(inst.m_lines));
    for( idt=0; idt < dimArr && *arrayElt(idt); idt++)
    {
      uint8_t ch=chProc(arrayElt(idt),0);
      if(idt>0 && ch < inst.m_lines[inst.m_prepCurrIFL-1].chId){
        printf("resort %d:ch%d <=> %d:ch%d\n",idt-1,ch,idt,inst.m_lines[inst.m_prepCurrIFL-1].chId);
        memswap(inst.arrayElt(idt-1), inst.arrayElt(idt), inst.m_prepSzeElt);
        inst.m_editMode=false;
        failed = true;
        eeDirty(EE_MODEL);
        break; //data ist resorted, try once more
      }
      bool ret=fill(ch,idt);
      Line &l=inst.m_lines[inst.m_prepCurrIFL++];
      l.showCh   = ret;//true;
      l.chId     = inst.m_prepCurrCh;
      l.idt      = idt;//inst.m_prepCurrIDT = idt;
      l.showDat  = true;
      l.islDat   = inst.m_prepCurrISL++;
    }
    inst.m_prepCurrIDT = idt;
  }while(failed);

  inst.fill(numChn+1,idt);
  //inst.m_prepCurrIDT++;
}

bool FoldedList::fill(uint8_t ch, uint8_t idt) //helper func for construction
{
  if(ch > inst.m_prepCurrCh) {
    while(1){
      if(inst.m_prepCurrIFL>0) inst.m_lines[inst.m_prepCurrIFL-1].islCh=inst.m_prepCurrISL++;
      inst.m_prepCurrCh++;
      if(inst.m_prepCurrCh>=ch) break;
      Line &l=inst.m_lines[inst.m_prepCurrIFL++];
      l.showCh = true;
      l.chId   = inst.m_prepCurrCh;
      l.idt    = idt-1;//inst.m_prepCurrIDT; //insert behind
      //inst.m_prepCurrIFL++;
      assert(inst.m_prepCurrIFL<=DIM(inst.m_lines));
    }
    return true;
  }else{
    return false;
  }
}
uint8_t FoldedList::findChn(uint8_t chn)
{
  for(uint8_t i=0; i<DIM(inst.m_lines); i++){
    if(inst.m_lines[i].chId==chn) {
      if(inst.m_lines[i].islDat) return inst.m_lines[i].islDat;
      else                       return inst.m_lines[i].islCh;
    }
  }
  return 0;
}
void FoldedList::show(){
#ifdef SIM
  //for(uint8_t i=0; i<DIM(inst.m_mixTab); i++){
  for(uint8_t i=0; i<14; i++){
    //MixTab *mt=inst.m_mixTab+i;
    FoldedList::Line* line=&inst.m_lines[i];
    printf( "chId %2d islCh%c%2d islDat%c%2d idt %d\n",
            line->chId,
            line->showCh?'*':' ', line->islCh,
            line->showDat?'*':' ', line->islDat,
            line->idt);
  }
#endif
}
FoldedList::Line* FoldedList::firstLine(int8_t sub){
  inst.m_currIDTOld = inst.m_currIDT;
  inst.m_subISL     = sub;
  inst.m_iterPosIFL = inst.m_iterOfsIFL;
  Line *l=&inst.m_lines[inst.m_iterPosIFL];
  inst.m_iterMinISL = l->islDat ? l->islDat : l->islCh;
  inst.m_iterHitIFL = 0;
  return nextLine(6);
}
FoldedList::Line* FoldedList::nextLine(uint8_t lines){
  int8_t i = inst.m_iterPosIFL-inst.m_iterOfsIFL;
  Line  *l = &inst.m_lines[inst.m_iterPosIFL];
  if(i>=lines  || !(l->showCh || l->showDat) ) {
    //Line *l=&inst.m_lines[inst.m_iterPosIFL-1];
    l--;
    uint8_t iterMaxISL = l->islCh ? l->islCh : l->islDat;

    //printf("inst.m_subISL%d,inst.m_iterOfsIFL%d,inst.m_iterHitIFL%d,inst.m_iterMinISL%d,iterMax%d\n",inst.m_subISL,inst.m_iterOfsIFL,inst.m_iterHitIFL,inst.m_iterMinISL,iterMax);
    if( inst.m_subISL!=0 &&  inst.m_iterHitIFL==0) { //versuche die Marke zu finden
      if(inst.m_subISL < inst.m_iterMinISL)      inst.m_iterOfsIFL = max(0,inst.m_iterOfsIFL-1);
      if(inst.m_subISL > iterMaxISL)      inst.m_iterOfsIFL++;
    }
    else if(inst.m_iterHitIFL<=2)          inst.m_iterOfsIFL = max(0,inst.m_iterOfsIFL-1);
    else if(inst.m_iterHitIFL>=(lines-1) && i>=lines)  inst.m_iterOfsIFL++;
    return 0;
  }
  inst.m_isSelectedCh  = inst.m_subISL > 0 && inst.m_subISL == l->islCh; 
  inst.m_isSelectedDat = inst.m_subISL > 0 && inst.m_subISL == l->islDat; 

  if(inst.m_isSelectedCh){ //handle CHx is selected 
    inst.m_currIDT     = l->idt+1;
    inst.m_currInsMode = true;
    inst.m_currDestCh  = l->chId;
    inst.m_iterHitIFL  = i+1;
    // printf("inst.m_currMixIdx=%d\n",inst.m_currMixIdx);
  }
  if(inst.m_isSelectedDat){ //handle dat is selected 
    inst.m_currIDT     = l->idt;
    inst.m_currInsMode = false;
    inst.m_currDestCh  = l->chId;
    inst.m_iterHitIFL  = i+1;
    // printf("inst.m_currMixIdx=%d\n",inst.m_currMixIdx);
  }
  inst.m_iterPosIFL++;
  return l;
}

uint8_t FoldedList::doEvent(uint8_t event, bool subChanged)
//, void*array,uint8_t dimArr, uint8_t szeElt)
{
  uint8_t ret=0;
  switch(event)
  {
    case EVT_ENTRY:
      FoldedList::inst.m_iterOfsIFL=0;
    case EVT_ENTRY_UP:
      inst.m_editMode=false;
      break;
    case  EVT_KEY_FIRST(KEY_EXIT):
      if(inst.m_editMode){
        inst.m_editMode = false;
        beepKey();
        killEvents(event); //cut off MSTATE_CHECK (KEY_BREAK)
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):
      if(inst.m_currInsMode) break;
      killEvents(event); //cut off 
      if(inst.m_editMode)
      {
        beepKey();
        ret = FoldedListDup;
        goto ret_dup;
      }
      inst.m_editMode=true;
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(inst.m_subISL<1) break;
      if(inst.m_currInsMode){
        ret=FoldedListNew;
        goto ret_dup;
      }
      return FoldedListEdit;
  }

  if(inst.m_editMode && subChanged) // && inst.m_currIDTOld != inst.m_currMixIdx)
  {
    STORE_MODELVARS;
    if(inst.m_currInsMode){
      uint8_t chn = inst.m_chProc(arrayElt(currIDTOld()),0);
      if( inst.m_currIDTOld <  inst.m_currIDT){ //? FoldedListCntUp//         ExpoData_r171  *ed = &g_model.expoTab[FL_INST.currIDTOld()];
//         if(ed->chn < 3) ed->chn++; 
//         else FL_INST.editModeOff();
        if(chn < inst.m_numChn) chn++;
        else inst.editModeOff();
      }else{ //: FoldedListCntDown;
        if(chn > 1) chn--;
        else inst.editModeOff();
      }
      inst.m_chProc(arrayElt(currIDTOld()),chn);
      return 0;
      //      return inst.m_currIDTOld <  inst.m_currIDT ? FoldedListCntUp : FoldedListCntDown;
    }else{
      //swap
      if( (inst.m_currIDTOld<inst.fillLevel()) && (inst.m_currIDT<inst.fillLevel())){
        printf("swap %d %d %d\n",inst.m_currIDTOld,inst.m_currIDT,inst.m_prepCurrIDT);
        memswap(inst.arrayElt(inst.m_currIDT),
                inst.arrayElt(inst.m_currIDTOld),
                inst.m_prepSzeElt);
        return FoldedListSwap;
      }else{
        inst.m_editMode=false;
      }
    }
  }
  return 0; 
  
  ret_dup:
  if((uint8_t)(inst.fillLevel())>=inst.m_prepDimArr){
    //printf("currIDT %d dimArr %d\n",inst.m_prepCurrIDT,dimArr);
    beepErr();
    return 0;
  }

  //memmove(
  //  (char*)array + (uint8_t)(szeElt * (uint8_t)(inst.m_currIDT+1)),
  //  (char*)array + (uint8_t)(szeElt *  inst.m_currIDT),
  //  (uint8_t)(szeElt * (uint8_t)(dimArr-inst.m_currIDT-1))
  memmove(
    inst.arrayElt(inst.m_currIDT+1),
    inst.arrayElt(inst.m_currIDT),
    (uint8_t)(inst.m_prepSzeElt * (uint8_t)(inst.m_prepDimArr-inst.m_currIDT-1))
  );
  if(ret==FoldedListNew)
    memset(inst.arrayElt(inst.m_currIDT),0,inst.m_prepSzeElt);
  STORE_MODELVARS;
  return ret;
}
void FoldedList::rmCurrLine()
{
  memmove(
    inst.arrayElt(inst.m_currIDT),
    inst.arrayElt(inst.m_currIDT+1),
    (uint8_t)(inst.m_prepSzeElt * (uint8_t)(inst.m_prepDimArr-inst.m_currIDT-1))
  );
  memset(inst.arrayElt(inst.m_prepDimArr-1),0,inst.m_prepSzeElt);
  STORE_MODELVARS;
}


