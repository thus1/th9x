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
#define MAX_MODELS 12
#define MAX_MIXERS 20


typedef struct t_TrainerData1 {
  uint8_t srcChn:3; //0-7 = ch1-8
  int8_t  swtch:5;
  uint8_t weight:6;
  uint8_t mode:2;   //off,add-mode,subst-mode
} __attribute__((packed)) TrainerData1; //

typedef struct t_TrainerData {
  int16_t       calib[4];
  TrainerData1  chanMix[4];
} __attribute__((packed)) TrainerData; //





//eeprom modelspec
typedef struct t_ExpoData {
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
} __attribute__((packed)) ExpoData;
typedef struct t_TrimData {
  int8_t  trim;    //quadratisch
  int16_t trimDef;
} __attribute__((packed)) TrimData;
typedef struct t_LimitData {
  int8_t  min;
  int8_t  max;
  bool    revert;
} __attribute__((packed)) LimitData;
typedef struct t_MixData {
  uint8_t destCh:4; //
  uint8_t srcRaw:4; //0=off
  int8_t  weight;
  int8_t  swtch:5;
  uint8_t curve:3; //0=symmetrisch 1=x>0 2=x<0 pos 3=|x|  4-6=curv1-3
  uint8_t speed:4;         // Servogeschwindigkeit aus Tabelle (10ms Cycle)
  uint8_t speedDir:2;      // 00 nichts 11 beide richtungen 01 nur hoch 10 nur runter
  //uint8_t tableIdx:2;      // Index Kennlinie
} __attribute__((packed)) MixData;



typedef struct t_EEGeneral {
  uint8_t version;
  uint8_t contrast;
  uint8_t vBatWarn;
  uint8_t currModel;
  int16_t calibMid[4];
  int16_t calibSpan[4];
  uint16_t chkSum;
  uint8_t sizeGeneral;
  uint8_t sizeModel;
  uint8_t numModels;
  int8_t  lightSw;
  int8_t  vBatCalib;  
  int8_t  table[3][9];   // 27
  uint8_t resv[5];  
  TrainerData trainer;
} __attribute__((packed)) EEGeneral;


typedef struct t_ModelData {
  char      name[10];    // 10
  uint8_t   stickMode;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  LimitData limitData[8];// 3*8
  ExpoData  expoData[4]; // 3*4
  MixData   mixData[MAX_MIXERS]; //3*20
  TrimData  trimData[4]; // 3*4
} __attribute__((packed)) ModelData; //126


#define TOTAL_EEPROM_USAGE (sizeof(ModelData)*MAX_MODELS + sizeof(EEGeneral))


extern EEGeneral g_eeGeneral;
extern ModelData g_model;












#endif
/*eof*/
