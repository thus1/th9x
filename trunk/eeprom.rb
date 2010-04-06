#! /usr/bin/env ruby


require "/home/thus/bin/cstruct.rb"

CStruct.alignment=1
CStruct.defStruct "EEGeneral",<<-"END_TYP"
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
  uint8_t resv[5];  
  END_TYP


CStruct.defStruct "ExpoData",<<-"END_TYP"
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
  END_TYP
CStruct.defStruct "TrimData",<<-"END_TYP"
  int8_t  trim;    //quadratisch
  int16_t trimDef;
  END_TYP
CStruct.defStruct "LimitData",<<-"END_TYP"
  int8_t  min;
  int8_t  max;
  bool    revert;
  END_TYP
#CStruct.defStruct "MixData",<<-"END_TYP"
#  uint8_t destCh:4; //
#  uint8_t srcRaw:4; //0=off
#  int8_t  weight;
#  int8_t  swtch:5;
#  uint8_t posNeg:2; //0=symmetrisch 1=no neg 2=no pos
#  uint8_t res:1;    //
#  END_TYP

CStruct.defStruct "MixData",<<-"END_TYP"
  uint8_t destCh_srcRaw; //
  int8_t  weight;
  int8_t  swtch_posNeg;
  END_TYP

CStruct.defStruct "ModelData",<<-"END_TYP"
  char      name[10];    // 10
  uint8_t   stickMode;   // 1
  char      res[7];      // 7
  ExpoData  expoData[4]; // 3*4
  TrimData  trimData[4]; // 3*4
  LimitData limitData[8];// 3*8
  MixData   mixData[20]; //3*20
  END_TYP

CStruct.defStruct "WholeEeprom",<<-"END_TYP"
  EEGeneral eEGeneral;
  ModelData modelData[16];
  END_TYP

eep=CStruct::WholeEeprom.new

File.open(ARGV[0]){|f|
  eep.read(f)
}

puts eep
