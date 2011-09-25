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
    inst.m_prepCurrIFL = 1;
    inst.m_prepCurrIDT = -1;
    memset(inst.m_lines,0,sizeof(inst.m_lines));
    inst.m_lines[0].showHeader=true;
    for( idt=0; idt < dimArr && *arrayElt(idt); idt++)
    {
      uint8_t ch=chProc(arrayElt(idt),0);
      if(idt>0 && ch < inst.m_lines[inst.m_prepCurrIFL-1].chId){
        printf("\nERROR re-sort %d:ch%d <=> %d:ch%d\n",idt-1,ch,idt,inst.m_lines[inst.m_prepCurrIFL-1].chId);
        memswap(inst.arrayElt(idt-1), inst.arrayElt(idt), inst.m_prepSzeElt);
        inst.m_listEdit=false;
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
    }
    inst.m_prepCurrIDT = idt;
  }while(failed);

  inst.fill(numChn+1,idt);
}

bool FoldedList::fill(uint8_t ch, uint8_t idt) //helper func for construction
{
  if(ch > inst.m_prepCurrCh) {
    while(1){
      inst.m_prepCurrCh++;
      if(inst.m_prepCurrCh>=ch) break;
      Line &l=inst.m_lines[inst.m_prepCurrIFL++];
      l.showCh = true;
      l.chId   = inst.m_prepCurrCh;
      l.idt    = idt;//inst.m_prepCurrIDT; //insert behind
      assert(inst.m_prepCurrIFL<=DIM(inst.m_lines));
    }
    return true;
  }else{
    return false;
  }
}
uint8_t FoldedList::findChn(uint8_t chn)
{
  for(uint8_t i=1; i<DIM(inst.m_lines); i++){
    if(inst.m_lines[i].chId==chn) {
      return i;
    }
  }
  return 0;
}
void FoldedList::show(){
#ifdef xSIM
  for(uint8_t i=0; i<14; i++){
    FoldedList::Line* line=&inst.m_lines[i];
//     printf( "chId %2d islCh%c%2d islDat%c%2d idt %d\n",
//             line->chId,
//             line->showCh?'*':' ', line->islCh,
//             line->showDat?'*':' ', line->islDat,
//             line->idt);
  }
#endif
}


uint8_t FoldedList::doEvent(int8_t sub,int8_t subChanged,bool chnNav)
{
  inst.m_subIFL     = sub;        //atueller vert index 0=auf header
  inst.m_subChanged = subChanged; //sub wurde gerade veraendert +x oder -x
  inst.m_chnNav     = chnNav;     //wir sind im chn navi bereich

  if(inst.m_listEdit && subChanged 
     && sub && (sub-subChanged)
     && (sub-subChanged)!=inst.m_prepCurrIFL
  ) //
  {
    int8_t idt2 = inst.m_currIDT+subChanged;
    uint8_t chn1 = inst.m_chProc(arrayElt(inst.m_currIDT),0);
    assert(idt2>=0);
    uint8_t chn2 = idt2>=0 ? inst.m_chProc(arrayElt(idt2),0) : 0;
    if(chn1==chn2){
      memswap(inst.arrayElt(inst.m_currIDT),
              inst.arrayElt(idt2),
              inst.m_prepSzeElt);
    }else{      inst.m_chProc(arrayElt(inst.m_currIDT),chn1+subChanged);
      if(subChanged>0){ //Spezialfall multidat ->
        if(inst.m_currIDT>=1){
          uint8_t chn0 = inst.m_chProc(arrayElt(inst.m_currIDT-1),0);
          if(chn0 == chn1) inst.m_subIFL -= 1;
        }
      }else{            //Spezialfall multidat <-
        if(inst.m_currIDT!=0 && chn2 == (chn1-1)) inst.m_subIFL += 1;
      }
    }
    return 0;

  }

  //ensure selection is at showed ch or dat
  while(inst.m_subIFL>0 && inst.m_subIFL<inst.m_prepCurrIFL) {
    if(chnNav){ //kurz zuvor move left?
      if(inst.m_lines[inst.m_subIFL].showCh) break;
      printf("m_subIFL %d korr1 %d\n",inst.m_subIFL,subChanged>0 ? +1:-1 );
      inst.m_subIFL += subChanged>0 ? +1:-1;
    }else{
      if(inst.m_lines[inst.m_subIFL].showDat) break;
      //nach remove wechsel zu folgezeile
      printf("m_subIFL %d korr2 %d\n",inst.m_subIFL,subChanged>=0 ? +1:-1 );
      inst.m_subIFL += subChanged>=0 ? +1:-1;
    }
  }
  //Notbremse falls nichts selektierbar
  if(chnNav){ 
    //ganz hinten
    if(!inst.m_lines[inst.m_subIFL].showCh) inst.m_subIFL = 0;
  }else{
    if(!inst.m_lines[inst.m_subIFL].showDat) inst.m_chnNav = true;
  }
  inst.m_currIDT     = inst.m_lines[inst.m_subIFL].idt;
  inst.m_currDestCh  = inst.m_lines[inst.m_subIFL].chId;
#define LINES 7
  // make visible current line
  if(inst.m_subIFL){
    int8_t i = inst.m_subIFL - inst.m_iterOfsIFL; 
    if(i<2) 
      inst.m_iterOfsIFL = max(0,inst.m_subIFL-2);
    else if(i>=(LINES-2))
      inst.m_iterOfsIFL = inst.m_subIFL-LINES+2;
  }

  uint8_t ret=0;
  switch(g_event)
  {
    case EVT_ENTRY:
      FoldedList::inst.m_iterOfsIFL=0;
    case EVT_ENTRY_UP:
      inst.m_listEdit=false;
      break;
    case EVT_KEY_BREAK(KEY_MENU):
      if(inst.m_listEdit) break;
      if(inst.m_subIFL<1) break; //menu kopfzeile aktiv
      if(inst.m_chnNav){  //neue Zeile einfuegen
        ret=FoldedListNew;
        goto ret_dup;
      }
      break;
    case EVT_KEY_LONG(KEY_MENU):  // _LONG
      killEvents(); //cut off 
      if(inst.m_listEdit)
      {
        beepKey();
        ret = FoldedListDup;
        goto ret_dup;
      }
      if(inst.m_subIFL<1) break; //menu kopfzeile aktiv
      //if(inst.m_currInsMode){  //neue Zeile einfuegen
      if(inst.m_chnNav){  //neue Zeile einfuegen
        if(! NAVI_ADVANCED) break;
        ret=FoldedListNewEdit;//FoldedListNew;
        goto ret_dup;
      }
      return FoldedListEdit; //Zeile edit
  }

  return 0; 
  
  ret_dup:
  if((uint8_t)(inst.fillLevel())>=inst.m_prepDimArr){
    //printf("currIDT %d dimArr %d\n",inst.m_prepCurrIDT,dimArr);
    beepErr();
    return 0;
  }

  memmove(
    inst.arrayElt(inst.m_currIDT+1),
    inst.arrayElt(inst.m_currIDT),
    (uint8_t)(inst.m_prepSzeElt * (uint8_t)(inst.m_prepDimArr-inst.m_currIDT-1))
  );
  if(ret==FoldedListNew || ret==FoldedListNewEdit)
    memset(inst.arrayElt(inst.m_currIDT),0,inst.m_prepSzeElt);
  STORE_MODELVARS;
  return ret;
}






FoldedList::Line* FoldedList::firstLine()//int8_t sub,bool chnNav,int8_t subChanged){
{
  inst.m_iterPosIFL = inst.m_iterOfsIFL; //iterator
  return nextLine(6);
}
FoldedList::Line* FoldedList::nextLine(uint8_t lines){
  int8_t i = inst.m_iterPosIFL-inst.m_iterOfsIFL;
  Line  *l = &inst.m_lines[inst.m_iterPosIFL];

  //ist schon fertig?
  if(i>=lines  || !(l->showCh || l->showDat || l->showHeader) ) {
    return 0;
  }

  inst.m_isSelectedCh  = inst.m_subIFL > 0 && inst.m_chnNav && inst.m_subIFL==inst.m_iterPosIFL; 
  inst.m_isSelectedDat = inst.m_subIFL > 0 && !inst.m_chnNav && inst.m_subIFL==inst.m_iterPosIFL; 

  inst.m_iterPosIFL++;
  return l;
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


