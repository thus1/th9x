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
#ifndef eeprom_h
#define eeprom_h


//eeprom data
#define EE_VERSION 2
#define MAX_MODELS 16
#define MAX_MIXERS 20


typedef struct t_TrainerData1 {
  uint8_t srcChn:3; //0-7 = ch1-8
  int8_t  swtch:5;
  int8_t  studWeight:6;
  uint8_t mode:2;   //off,add-mode,subst-mode
} __attribute__((packed)) TrainerData1; //

typedef struct t_TrainerData {
  int16_t       calib[4];
  TrainerData1  chanMix[4];
} __attribute__((packed)) TrainerData; //







//eeprom modelspec

typedef struct t_LimitData_lt84 {
  int8_t  min;
  int8_t  max;
  bool    revert;
} __attribute__((packed)) LimitData_lt84;
typedef struct t_ExpoData_lt84 {
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
} __attribute__((packed)) ExpoData_lt84;


typedef struct t_ExpoData {
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
  int8_t  expNormWeight;
  int8_t  expSwWeight;
} __attribute__((packed)) ExpoData;
typedef struct t_TrimData {
  int8_t  trim;    //quadratisch
  int16_t trimDef;
} __attribute__((packed)) TrimData;
typedef struct t_LimitData {
  int8_t  min;
  int8_t  max;
  bool    revert;
  int8_t  offset;
} __attribute__((packed)) LimitData;
typedef struct t_MixData {
  uint8_t destCh:4; //        1..NUM_CHNOUT,X1-X4
  uint8_t srcRaw:4; //0=off   1..8      ,X1-X4
  int8_t  weight;
  int8_t  swtch:5;
  uint8_t curve:3; //0=symmetrisch 1=no neg 2=no pos
  uint8_t speedUp:4;         // Servogeschwindigkeit aus Tabelle (10ms Cycle)
  uint8_t speedDown:4;      // 0 nichts
} __attribute__((packed)) MixData;






typedef struct t_EEGeneral {
  uint8_t   myVers;
  int16_t   calibMid[4];
  int16_t   calibSpan[4];
  uint16_t  chkSum;
  uint8_t   currModel; //0..15
  uint8_t   contrast;
  uint8_t   vBatWarn;
  int8_t    vBatCalib;  
  int8_t    lightSw;
  TrainerData trainer;
  uint8_t   view;     //index of subview in main scrren
#define WARN_THR (!(g_eeGeneral.warnOpts & 0x01))
#define WARN_SW  (!(g_eeGeneral.warnOpts & 0x02))
#define WARN_MEM (!(g_eeGeneral.warnOpts & 0x04))
#define BEEP_VAL (  g_eeGeneral.warnOpts & 0x08 ? 0 : 1)
  uint8_t   warnOpts; //bitset for several warnings
  uint8_t   stickMode;   // 1
} __attribute__((packed)) EEGeneral;

typedef struct t_ModelData_lt84 {
  char      name[10];    // 10 must be first for eeLoadModelName
  uint8_t   stickModex;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  LimitData_lt84 limitData[NUM_CHNOUT];// 3*8
  ExpoData_lt84  expoData[4]; // 3*4
  MixData   mixData[MAX_MIXERS]; //4*20
  int8_t    curves5[2][5];   // 10
  int8_t    curves9[2][9];   // 18
  TrimData  trimData[4]; // 3*4
} __attribute__((packed)) ModelData_lt84; //174

typedef struct t_ModelData {
  char      name[10];    // 10 must be first for eeLoadModelName
  uint8_t   stickModex;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  LimitData limitData[NUM_CHNOUT];// 4*8
  ExpoData  expoData[4]; // 5*4
  MixData   mixData[MAX_MIXERS]; //4*20
  int8_t    curves5[2][5];   // 10
  int8_t    curves9[2][9];   // 18
  TrimData  trimData[4]; // 3*4
} __attribute__((packed)) ModelData; //190


#define TOTAL_EEPROM_USAGE (sizeof(ModelData)*MAX_MODELS + sizeof(EEGeneral))


extern EEGeneral g_eeGeneral;
extern ModelData g_model;












#endif
/*eof*/
