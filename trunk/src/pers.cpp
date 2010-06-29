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

void generalDefault()
{
  memset(&g_eeGeneral,0,sizeof(g_eeGeneral));
  g_eeGeneral.myVers   =  1;
  g_eeGeneral.currModel=  0;
  g_eeGeneral.contrast = 30;
  g_eeGeneral.vBatWarn = 90;
  g_eeGeneral.stickMode=  1;
  int16_t sum=0;
  for (int i = 0; i < 4; ++i) {
    sum += g_eeGeneral.calibMid[i]  = 0x200;
    sum += g_eeGeneral.calibSpan[i] = 0x180;
  }
  g_eeGeneral.chkSum = sum;
}
bool eeLoadGeneral()
{
  theFile.openRd(FILE_GENERAL);
  theFile.readRlc((uint8_t*)&g_eeGeneral, sizeof(EEGeneral));
  uint16_t sum=0;
  for(int i=0; i<8;i++) sum+=g_eeGeneral.calibMid[i];
#ifdef SIM
  if(g_eeGeneral.myVers != 1)    printf("bad g_eeGeneral.myVers == 1\n");
  if(g_eeGeneral.chkSum != sum)  printf("bad g_eeGeneral.chkSum == sum\n");
#endif  
  return g_eeGeneral.myVers == 1 && g_eeGeneral.chkSum == sum;
}

void modelDefault(uint8_t id)
{
  memset(&g_model,0,sizeof(g_model));
  strcpy_P(g_model.name,PSTR("MODEL     "));
  //g_model.stickMode=1;
  g_model.name[5]='0'+(id+1)/10;
  g_model.name[6]='0'+(id+1)%10;
  for(uint8_t i= 0; i<4; i++){
    //     0   1   2   3
    //0 1 rud ele thr ail
    //1 2 rud thr ele ail
    //2 3 ail ele thr rud
    //3 4 ail thr ele rud
    g_model.mixData[i].destCh = i+1;
    g_model.mixData[i].srcRaw = i+1;
    g_model.mixData[i].weight = 100;
  }
  if(g_eeGeneral.stickMode & 1){
    g_model.mixData[1].srcRaw = 3;
    g_model.mixData[2].srcRaw = 2;
  }
  if(g_eeGeneral.stickMode & 2){
    g_model.mixData[0].srcRaw = 4;
    g_model.mixData[3].srcRaw = 1;
  }
}
void eeLoadModelName(uint8_t id,char*buf,uint8_t len)
{
  if(id<MAX_MODELS)
  {
    //eeprom_read_block(buf,(void*)modelEeOfs(id),sizeof(g_model.name));
    theFile.openRd(FILE_MODEL(id));
    memset(buf,' ',len);
    if(theFile.readRlc((uint8_t*)buf,sizeof(g_model.name)) == sizeof(g_model.name) )
    {
      uint16_t sz=theFile.size();
      buf+=len;
      while(sz){ --buf; *buf='0'+sz%10; sz/=10;}
    }
  }
}
void eeLoadModel(uint8_t id)
{
  if(id<MAX_MODELS)
  {
    theFile.openRd(FILE_MODEL(id));
    uint8_t sz = theFile.readRlc((uint8_t*)&g_model, sizeof(g_model)); 
    if( sz == sizeof(g_model) ) return;

#if 0
    if( sz == sizeof(ModelData_lt84) ){
#ifdef SIM
      printf("converting model data from < 84\n");
#endif
#define model_lt84 ((char*)&g_model)
#define OFS(memb)    (int)(((ModelData*)0)->memb)
#define OFS84(memb)  (int)(((ModelData_lt84*)0)->memb)
      int dbot;
      int stop  = sizeof(ModelData_lt84);
      int sbot; 
      sbot   = OFS84(mixData);      dbot  = OFS(mixData);
      memmove(((char*)&g_model)+dbot, model_lt84+sbot, stop-sbot); stop=sbot;

      sbot  = OFS84(expoData); 
      while(stop > sbot){
        dbot -= sizeof(ExpoData);
        stop -= sizeof(ExpoData_lt84);
        memset (((char*)&g_model)+dbot, 0, sizeof(ExpoData) );
        memmove(((char*)&g_model)+dbot, model_lt84+stop,sizeof(ExpoData_lt84));
      }
      sbot  = OFS84(limitData); 
      while(stop > sbot){
        dbot -= sizeof(LimitData);
        stop  -= sizeof(LimitData_lt84);
        memset (((char*)&g_model)+dbot, 0, sizeof(LimitData) );
        memmove(((char*)&g_model)+dbot, model_lt84+stop,sizeof(LimitData_lt84));
      }
    }
#endif

#ifdef SIM
    printf("bad model%d data using default\n",id+1);
#endif
    modelDefault(id);
  }
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
                     sizeof(EEGeneral),200);

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
                        sizeof(EEGeneral),20) == sizeof(EEGeneral))
    {   
      EFile::swap(FILE_GENERAL,FILE_TMP);
    }else{
      if(theFile.errno()==ERR_TMO){
        s_eeDirtyMsk |= EE_GENERAL; //try again
        s_eeDirtyTime10ms = g_tmr10ms - WRITE_DELAY_10MS;
#ifdef SIM
        printf("writing aborted GENERAL\n");
#endif
      }else{
        alert(PSTR("EEPROM overflow"));
      }
    }
    //first finish GENERAL, then MODEL !!avoid Toggle effect
  }
  else if(msk & EE_MODEL){
    if(theFile.writeRlc(FILE_TMP, FILE_TYP_MODEL, (uint8_t*)&g_model, 
                        sizeof(g_model),20) == sizeof(g_model))
    {
      EFile::swap(FILE_MODEL(g_eeGeneral.currModel),FILE_TMP);
    }else{
      if(theFile.errno()==ERR_TMO){
        s_eeDirtyMsk |= EE_MODEL; //try again
        s_eeDirtyTime10ms = g_tmr10ms - WRITE_DELAY_10MS;
#ifdef SIM
        printf("writing aborted MODEL\n");
#endif
      }else{
        alert(PSTR("EEPROM overflow"));
      }
    }
  }
  beepWarn1();
}
