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
#ifndef foldedlist_h
#define foldedlist_h


#include "th9x.h"


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
class FoldedList
{
public:
  static FoldedList inst;
  struct Line{
    bool   showCh:1;// show the dest chn
    bool   showDat:1;// show the data info
    int8_t chId;    //:4  1..NUM_XCHNOUT  dst chn id             
    int8_t islCh;   //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t islDat;  //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t idt;     //:5  0..MAX_MIXERS-1  edit index into mix data tab
  };
 private:
#define flstatic
  flstatic Line    s_lines[MAX_MIXERS+NUM_XCHNOUT+1];
  flstatic uint8_t s_prepCurrCh; //for construction of s_lines
//indize:
//
// IDT  data tab
// ISL  select sequence
// IFL  foldedlist
// IFLr rel. foldedlist
  flstatic uint8_t s_prepCurrIFL;
  flstatic uint8_t s_prepCurrISL;
  flstatic uint8_t s_prepCurrIDT;  // *

  flstatic uint8_t s_iterOfsIFL;
  flstatic uint8_t s_iterPosIFL;
  flstatic uint8_t s_iterHitIFL;
  flstatic uint8_t s_subISL;
  flstatic uint8_t s_iterMinISL;
  flstatic bool    s_isSelectedCh; // *
  flstatic bool    s_isSelectedDat;// *
  flstatic bool    s_editMode;     // *
  flstatic uint8_t s_currIDTOld;   // *

  flstatic uint8_t s_currIDT;
  flstatic uint8_t s_currDestCh;   // *
  flstatic bool    s_currInsMode;  // *


 public:  
  static uint8_t fillLevel()    {return inst.s_prepCurrIDT+1;}
  static uint8_t currIDT()      {return inst.s_currIDT;}
  static uint8_t currIDTOld()   {return inst.s_currIDTOld;}
  static uint8_t currDestCh()   {return inst.s_currDestCh;}
  static bool    currInsMode()  {return inst.s_currInsMode;}
  static bool    isSelectedCh() {return inst.s_isSelectedCh;}
  static bool    isSelectedDat(){return inst.s_isSelectedDat;}
  static bool    editMode()     {return inst.s_editMode;}
  static void    editModeOff()  { inst.s_editMode=false;}
  /// iterate one time to fill the list (init loop)
  /// init(); addDat addDat addDat ..
  static void init();
  static void addDat(uint8_t ch, uint8_t idx);
  static void show();           //helper func for debug
  static bool fill(uint8_t ch); //helper func for construction

  /// iterate one time through the filled list (show loop)
  /// with firstLine,nextLine nextLine ..
  static Line* firstLine(int8_t sub);
  static Line* nextLine(uint8_t lines);

  static int8_t numSeqs(){return inst.s_prepCurrISL;};
#define FoldedListDup      1
#define FoldedListEdit     2
#define FoldedListNew      3
#define FoldedListSwap     4
#define FoldedListCntUp    5
#define FoldedListCntDown  6
  static uint8_t doEvent(uint8_t event, bool subChanged, void*array,uint8_t dimArr, uint8_t szeElt);

};

#define FL_INST FoldedList::inst

#endif

