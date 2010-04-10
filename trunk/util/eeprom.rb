#! /usr/bin/env ruby


require File.dirname(__FILE__)+"/cstruct.rb"
EE_VERSION=1
MAX_MODELS=16
MAX_MIXERS=20

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

CStruct.defStruct "MixData",<<-"END_TYP"
  uint8_t destCh_srcRaw; //
  int8_t  weight;
  int8_t  swtch_posNeg;
  END_TYP

CStruct.defStruct "ModelData",<<-"END_TYP"
  char      name[10];    // 10
  uint8_t   stickMode;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  ExpoData  expoData[4]; // 3*4
  TrimData  trimData[4]; // 3*4
  LimitData limitData[8];// 3*8
  MixData   mixData[#{MAX_MIXERS}]; //3*20
  END_TYP

CStruct.defStruct "WholeEeprom",<<-"END_TYP"
  EEGeneral eEGeneral;
  ModelData modelData[#{MAX_MODELS}];
  END_TYP

eep=CStruct::WholeEeprom.new(0)

File.open(ARGV[0] || "eeprom.bin"){|f|
  eep.read(f)
}

puts eep
