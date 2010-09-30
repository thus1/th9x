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

 This file contains any upper level code for data persistency.
 The Layer below is file.cpp and then drivers.cpp

 */

#include "th9x.h"


EFile theFile;  //used for any file operation
EFile theFile2; //sometimes we need two files 

#define FILE_TYP_GENERAL 1
#define FILE_TYP_MODEL   2
#define partCopy(sizeDst,sizeSrc)                         \
      pSrc -= (sizeSrc);                                  \
      pDst -= (sizeDst);                                  \
      memmove(pDst, pSrc, (sizeSrc));                     \
      memset (pDst+(sizeSrc), 0,  (sizeDst)-(sizeSrc));
#define fullCopy(size) partCopy(size,size)
void generalDefault()
{
  memset(&g_eeGeneral,0,sizeof(g_eeGeneral));
  g_eeGeneral.myVers   =  GENVERS150;
  g_eeGeneral.currModel=  0;
  g_eeGeneral.contrast = 30;
  g_eeGeneral.vBatWarn = 90;
  g_eeGeneral.stickMode=  1;
  //int16_t sum=0;
  for (int i = 0; i < 7; ++i) {
    g_eeGeneral.calibMid[i]     = 0x200;
    g_eeGeneral.calibSpanNeg[i] = 0x180;
    g_eeGeneral.calibSpanPos[i] = 0x180;
  }
  //g_eeGeneral.chkSum = sum;
}
bool eeLoadGeneral()
{
  theFile.openRd(FILE_GENERAL);
  uint8_t sz = theFile.readRlc((uint8_t*)&g_eeGeneral, sizeof(g_eeGeneral));
  //uint16_t sum=0;
  if( sz == sizeof(EEGeneral_r0) && g_eeGeneral.myVers == GENVERS0 ){
    printf("converting EEGeneral data from < 119\n");
    char* pSrc = ((char*)&g_eeGeneral) + sizeof(EEGeneral_r0);//Pointers behind the end
    char* pDst = ((char*)&g_eeGeneral) + sizeof(EEGeneral_r119);
    fullCopy(sizeof(EEGeneral_r0)-offsetof(EEGeneral_r0,calibSpan));
    //for(uint8_t i=0; i<12;i++) sum+=g_eeGeneral.calibMid[i];
    //g_eeGeneral.chkSum = sum;
    sz = sizeof(EEGeneral_r119);
    EEGeneral_r119*p119= (EEGeneral_r119*)&g_eeGeneral;
    p119->myVers  = GENVERS119;
  }
  if( sz == sizeof(EEGeneral_r119) && g_eeGeneral.myVers == GENVERS119){
    printf("converting EEGeneral data from 119 to 119_3\n");
    EEGeneral_r119*p119= (EEGeneral_r119*)&g_eeGeneral;
    p119->adcFilt = 2;
    p119->thr0pos = 1; //upper 6 bits of adc value
    p119->myVers  = GENVERS119_3;
  }
  if( sz == sizeof(EEGeneral_r119) && g_eeGeneral.myVers == GENVERS119_3){
    printf("converting EEGeneral data from 119_3 to 150\n");
    char* pSrc = ((char*)&g_eeGeneral) + sizeof(EEGeneral_r119);//Pters behind the end
    char* pDst = ((char*)&g_eeGeneral) + sizeof(EEGeneral_r150);
    fullCopy(sizeof(EEGeneral_r119)-offsetof(EEGeneral_r119,chkSum));
    partCopy(7*2,4*2); //calibSpanPos
    partCopy(7*2,4*2); //calibSpanNeg
    partCopy(7*2,4*2); //calibMid
    EEGeneral_r150*p150= (EEGeneral_r150*)&g_eeGeneral;
    p150->inactivityMin = 0;
    p150->resv = 0;
    for(uint8_t i=4; i<7;i++){
      p150->calibMid[i]     = 0x200;
      p150->calibSpanNeg[i] = 0x180;
      p150->calibSpanPos[i] = 0x180;
    }
    
    sz = sizeof(EEGeneral_r150);
    p150->myVers  = GENVERS150;
  }
  if( sz == sizeof(EEGeneral_r150) && g_eeGeneral.myVers == GENVERS150){
    //    for(int i=0; i<12;i++) sum+=g_eeGeneral.calibMid[i];
    //#ifdef SIM
    //    if(g_eeGeneral.chkSum != sum)  printf("bad g_eeGeneral.chkSum == sum\n");
    //#endif  
    //    return g_eeGeneral.chkSum == sum;
    return true;
  }
  printf("bad g_eeGeneral\n");
  return false;
}
#define CM(x) convertMode(x)


uint8_t modelMixerDefaults=6;
prog_char* modelMixerDefaultName(uint8_t typ)
{
  switch(typ)
  {
    case 0: return PSTR("Empty");
    case 1: return PSTR("Simple 4-Ch");
    case 2: return PSTR("V-Tail");
    case 3: return PSTR("Elevon/Delta");
    case 4: return PSTR("eCCPM");
    case 5: return PSTR("Sim Calib");
  }
  return 0;
}
void modelMixerDefault(uint8_t typ)
{
  memset(&g_model.mixData[0],0,sizeof(g_model.mixData));
  MixData_r0 *md=&g_model.mixData[0];
  switch (typ){
    //Simple 4-Ch
    case 0:
      break;
    case 1:
      // rud ele thr ail
      for(uint8_t i= 0; i<4; i++){
        md->destCh = i+1;       md->srcRaw = CM(i)+1;        md->weight = 100;
        md++;
      }
      break;
    
      //V-Tail
    case 2:
      md->destCh = STK_RUD+1;   md->srcRaw = CM(STK_RUD)+1;  md->weight = 100; md++;
      md->destCh = STK_RUD+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight =-100; md++;
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_RUD)+1;  md->weight = 100; md++;
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight = 100; md++;
      md->destCh = STK_THR+1;   md->srcRaw = CM(STK_THR)+1;  md->weight = 100;
      break;

      //Elevon\\Delta
    case 3:
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight = 100; md++;
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_AIL)+1;  md->weight = 100; md++;
      md->destCh = STK_THR+1;   md->srcRaw = CM(STK_THR)+1;  md->weight = 100; md++;
      md->destCh = STK_AIL+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight = 100; md++;
      md->destCh = STK_AIL+1;   md->srcRaw = CM(STK_AIL)+1;  md->weight =-100;
      break;

      //eCCPM
    case 4:
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight = 72; md++;
      md->destCh = STK_ELE+1;   md->srcRaw = CM(STK_THR)+1;  md->weight = 55; md++;
      md->destCh = STK_AIL+1;   md->srcRaw = CM(STK_ELE)+1;  md->weight = 36; md++;
      md->destCh = STK_AIL+1;   md->srcRaw = CM(STK_AIL)+1;  md->weight = 62; md++;
      md->destCh = STK_AIL+1;   md->srcRaw = CM(STK_THR)+1;  md->weight = 55; md++;
      md->destCh = 6;           md->srcRaw = CM(STK_ELE)+1;  md->weight = 36; md++;
      md->destCh = 6;           md->srcRaw = CM(STK_AIL)+1;  md->weight = 62; md++;
      md->destCh = 6;           md->srcRaw = CM(STK_THR)+1;  md->weight = 55; md++;
      // Sim Calib
    case 5:
      for(uint8_t i= 0; i<8; i++){
        md->destCh = i+1;       md->srcRaw = 8;/*MAX*/       md->weight = 100; 
        md->swtch  = 1+SW_ID0-SW_BASE;
        md++;
        md->destCh = i+1;       md->srcRaw = 8;/*MAX*/       md->weight =-100; 
        md->swtch  = 1+SW_ID2-SW_BASE;
        md++;
      }
      break;
  
  }
}
void modelDefault(uint8_t id)
{
  memset(&g_model,0,sizeof(g_model));
  strcpy_P(g_model.name,PSTR("MODEL     "));
  g_model.name[5]='0'+(id+1)/10;
  g_model.name[6]='0'+(id+1)%10;
  g_model.mdVers = 0; //MDVERS143;
  modelMixerDefault(id==0 ? 1 : 0);
}
void eeLoadModelName(uint8_t id,char*buf,uint8_t len)
{
  if(id<MAX_MODELS)
  {
    //eeprom_read_block(buf,(void*)modelEeOfs(id),sizeof(g_model.name));
    theFile.openRd(FILE_MODEL(id));
    memset(buf,' ',len);
    if(theFile.readRlc((uint8_t*)buf,sizeof(g_model.name)+1) == (sizeof(g_model.name)+1) )
    {
      uint8_t  vers = buf[sizeof(g_model.name)];
      uint16_t sz   = theFile.size();
      buf[sizeof(g_model.name)]=' ';
      buf+=len;
      *--buf='0'+vers%10; vers/=10;
      *--buf='0'+vers%10;
      *--buf='V';
        --buf;
      while(sz){   --buf; *buf='0'+sz%10;   sz/=10;}
    }
  }
}
int8_t trimRevert(int16_t val)
{
  uint8_t idx = 0;
  bool    neg = val<0; val=abs(val);
  while(val>0){
    idx++;
    val-=idx;
  }
  return neg ? -idx : idx;
}
void eeLoadModel(uint8_t id)
{
  if(id>=MAX_MODELS) return; //paranoia

  theFile.openRd(FILE_MODEL(id));
  uint8_t sz = theFile.readRlc((uint8_t*)&g_model, sizeof(g_model)); 

  if( sz == sizeof(ModelData_r0) ){
#ifdef SIM
    printf("converting model data t0 r84\n");
#endif
    char* pSrc = ((char*)&g_model) + sizeof(ModelData_r0); //Pointers behind the end
    char* pDst = ((char*)&g_model) + sizeof(ModelData_r84);
    ModelData_r84 *model84 = (ModelData_r84*)&g_model;
#define sizeof84(memb) sizeof(((ModelData_r84*)0)->memb)
    fullCopy(sizeof84(trimData)+sizeof84(curves9)+sizeof84(curves5));

    partCopy(sizeof84(mixData), sizeof(MixData_r0)*20);

    for(uint8_t i=0; i<DIM(model84->expoData); i++){
      partCopy(sizeof(ExpoData_r84), sizeof(ExpoData_r0));
    }
    sz = sizeof(ModelData_r84);
    model84->mdVers = MDVERS84;
  }

  if( sz == sizeof(ModelData_r84) && g_model.mdVers == MDVERS84) {
    printf("converting model data from r84 to r143\n");
    ModelData_r84  *model84  = (ModelData_r84*)&g_model;
    ModelData_r143 *model143 = (ModelData_r143*)&g_model;
    for(int8_t i=3; i>=0; i--){
      int16_t val = trimExp(model84->trimData[i].trim) + model84->trimData[i].trimDef_lt133;
      model143->trimData[i].trim = trimRevert(val);
    }
    memmove(&model143->curves5, &model84->curves5, sizeof(model84->curves5)+sizeof(model84->curves9));
    memset(model143->curves3, 0, sizeof(model143->curves3));
    model143->curves3[0][2] =  100;
    model143->curves3[2][0] =  100;
    model143->curves3[2][2] =  100;
    model143->curves3[1][0] = -100;
    sz = sizeof(ModelData_r143);
    model84->mdVers = MDVERS143;
  }
  
  if( sz == sizeof(ModelData_r143) && g_model.mdVers == MDVERS143) {
    return;
  }

  printf("bad model%d data using default\n",id+1);
  modelDefault(id);

}

bool eeDuplicateModel(uint8_t id)
{
  uint8_t i;
  for( i=id+1; i<MAX_MODELS; i++)
  {
    if(! EFile::exists(FILE_MODEL(i))) break;
  }
  if(i==MAX_MODELS) return false; //no free space in directory left

  theFile.openRd(FILE_MODEL(id));
  theFile2.create(FILE_MODEL(i),FILE_TYP_MODEL,200);
  uint8_t buf[15];
  uint8_t l;
  while((l=theFile.read(buf,15)))
  {
    theFile2.write(buf,l);
    wdt_reset();
  }
  theFile2.closeTrunc();
  //todo error handling
  return true;
}
void eeReadAll()
{
  if(!EeFsOpen()  || 
     EeFsck() < 0 || 
     !eeLoadGeneral()
  )
  {
#ifdef SIM
    printf("bad eeprom contents\n");
#else
    alert(PSTR("Bad EEprom Data"));
#endif
    EeFsFormat();
    generalDefault();
    theFile.writeRlc(FILE_GENERAL,FILE_TYP_GENERAL,(uint8_t*)&g_eeGeneral, 
                     sizeof(g_eeGeneral),200);

    modelDefault(0);
    theFile.writeRlc(FILE_MODEL(0),FILE_TYP_MODEL,(uint8_t*)&g_model, 
                     sizeof(g_model),200);
  }
  eeLoadModel(g_eeGeneral.currModel);
}


static uint8_t  s_eeDirtyMsk;
static uint16_t s_eeDirtyTime10ms;
void eeDirty(uint8_t msk)
{
  if(!msk) return;
  s_eeDirtyMsk      |= msk;
  s_eeDirtyTime10ms  = g_tmr10ms;
}
#define WRITE_DELAY_10MS 100
void eeCheck(bool immediately)
{
  uint8_t msk  = s_eeDirtyMsk;
  if(!msk) return;
  if( !immediately && ((g_tmr10ms - s_eeDirtyTime10ms) < WRITE_DELAY_10MS)) return;
  s_eeDirtyMsk = 0;
  if(msk & EE_GENERAL){
    if(theFile.writeRlc(FILE_TMP, FILE_TYP_GENERAL, (uint8_t*)&g_eeGeneral, 
                        sizeof(g_eeGeneral),20) == sizeof(g_eeGeneral))
    {   
      EFile::swap(FILE_GENERAL,FILE_TMP);
    }else{
      if(theFile.errno()==ERR_TMO){
        s_eeDirtyMsk |= EE_GENERAL; //try again
        s_eeDirtyTime10ms = g_tmr10ms - WRITE_DELAY_10MS;
        printf("writing aborted GENERAL\n");
      }else{
        alert(PSTR("EEPROM overflow"));
      }
    }
    //first finish GENERAL, then MODEL !!avoid Toggle effect
  }
  else if(msk & EE_MODEL){
    g_model.mdVers = MDVERS143;
    if(theFile.writeRlc(FILE_TMP, FILE_TYP_MODEL, (uint8_t*)&g_model, 
                        sizeof(g_model),20) == sizeof(g_model))
    {
      EFile::swap(FILE_MODEL(g_eeGeneral.currModel),FILE_TMP);
    }else{
      if(theFile.errno()==ERR_TMO){
        s_eeDirtyMsk |= EE_MODEL; //try again
        s_eeDirtyTime10ms = g_tmr10ms - WRITE_DELAY_10MS;
        printf("writing aborted MODEL\n");
      }else{
        alert(PSTR("EEPROM overflow"));
      }
    }
  }
  beepWarn1();
}
