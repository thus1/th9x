
#ifndef FOLDEDLIST_H
#define FOLDEDLIST_H

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
  struct Line{
    bool   showCh:1;// show the dest chn
    bool   showDat:1;// show the data info
    int8_t chId;    //:4  1..NUM_XCHNOUT  dst chn id             
    int8_t islCh;   //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t islDat;  //:5  1..MAX_MIXERS+NUM_XCHNOUT sel sequence
    int8_t idt;     //:5  0..MAX_MIXERS-1  edit index into mix data tab
  };
  static Line s_lines[MAX_MIXERS+NUM_XCHNOUT+1];
  static uint8_t s_prepCurrCh; //for construction of s_lines
  static uint8_t s_prepCurrIFL;
  static uint8_t s_prepCurrISL;
  static uint8_t s_prepCurrIDT;  // *

  static uint8_t s_iterOfsIFL;
  static uint8_t s_iterPosIFL;
  static uint8_t s_iterHitIFL;
  static uint8_t s_subISL;
  static uint8_t s_iterMinISL;
  static bool    s_isSelectedCh; // *
  static bool    s_isSelectedDat;// *
  static bool    s_editMode;     // *
  static uint8_t s_currIDTOld;   // *

  static uint8_t s_currIDT;
  static uint8_t s_currDestCh;   // *
  static bool    s_currInsMode;  // *


  static void init();
  static void addDat(uint8_t ch, uint8_t idx);
  static void show();
  static bool fill(uint8_t ch); //helper func for construction

  static Line* firstLine(int8_t sub);
  static Line* nextLine(uint8_t lines);

  static int8_t numSeqs(){return s_prepCurrISL;};
#define FoldedListDup      1
#define FoldedListEdit     2
#define FoldedListNew      3
#define FoldedListSwap     4
#define FoldedListCntUp    5
#define FoldedListCntDown  6
  static uint8_t doEvent(uint8_t event, bool subChanged, void*array,uint8_t dimArr, uint8_t szeElt);

};

#endif
