#! /usr/bin/env ruby


$: << File.dirname(__FILE__)
require "cstruct.rb"
require 'pp'
require 'optparse'

class String
  def lcut(n) # String
    ret=self[0,n]
    self[0,n]=""
    return ret
  end
end
class Integer
  def sgn() # Integer
    self<0 ? -1 : self==0 ? 0 : 1
  end
end
module CStruct; class CStructBase
  def omitIfWellknown(val) # CStruct;
    if (bin=toBin) == val
      hide()
      return ""
    else
      return bin.inspect + "\n"
    end
  end
end;end

CStruct.alignment=1


# V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4

def idx2val15_100(idx) 
  [0,10,20,30,40,50,55,60,65,70,75,80,85,90,95,100][idx.abs]*idx.sgn
end
def idx2val30_100(idx) 
[0,1,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100][idx.abs]*idx.sgn
end
def idx2val50_150(idx) 
  a=idx.abs
  #a=50 if a>50
[0,1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,
46,48,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,
150,155,160,165,170,175,180,185,190,195,200,205,210,215
][a]*idx.sgn
end
def chnOutTo_s(idx) 
  %w(EOF CH1 CH2 CH3 CH4 CH5 CH6 CH7 CH8 X1 X2 X3 X4)[idx]
end
def chnInTo_s(idx)
  %w(EOF RUD ELE THR AIL P1 P2 P3 MAX FUL X1 X2 X3 X4)[idx]
end
def chnIn192To_s(idx)
  %w(RUD ELE THR AIL P1 P2 P3 p1 p2 p3 MAX CUR CH1 CH2 CH3 CH4 CH5 CH6 CH7 CH8 X1 X2 X3 X4 T1 T2 T3 T4 T5 T6 T7 T8)[idx]
end

def crvTo_s(idx,neg=false) 
  idx==0 ? "    " : "f#{idx}" 
end
def swtchTo_s(idx) 
  return "    " if idx==0 
  sprintf("%s%-3s",idx<0 ? "!":" ",%w(0 THR RUD ELE ID0 ID1 ID2 AIL GEA TRN ON)[idx])
end
def swtch204To_s(idx) 
  return "    " if idx==0 
  sprintf("%s%-3s",idx<0 ? "!":" ",%w(0 THR RUD ELE ID0 ID1 ID2 AIL GEA TRN 
                                      SW1 SW2 SW3 SW4 SW5 SW6 SW7 SW8)[idx])
end
def swVal(v)
  neg = v<0
  s   = ""
  v,s=-v,"-" if neg
  return s+idx2val50_150(v).to_s if v<=50
  return s+chnIn192To_s(v-51)
end

def int5(i5)
  i5&=0x1f
  i5-=0x20 if i5 & 0x10 != 0
  i5
end
def int6(i6)
  i6&=0x3f
  i6-=0x40 if i6 & 0x20 != 0
  i6
end
def int7(i7)
  i7&=0x7f
  i7-=0x80 if i7 & 0x40 != 0
  i7
end

CStruct.defStruct "TrainerData1_r0",<<-"END_TYP"
  uint8_t srcChn:3,swtch:5; //0-7 = ch1-8
  uint8_t weight:6,mode:2;  //off,add-mode,subst-mode
  END_TYP

CStruct.defStruct "TrainerData_r0",<<-"END_TYP"
  int16_t       calib[4];
  TrainerData1_r0  chanMix[4];
  END_TYP
CStruct.defStruct "TrainerData_r192",<<-"END_TYP"
  int16_t       calib[8];
  TrainerData1_r0  chanMix[4];
  END_TYP
CStruct.defStruct "EEGeneral_helper",<<-"END_TYP"
  uint8_t myVers;
  END_TYP
CStruct.defStruct "EEGeneral_r0",<<-"END_TYP"
  uint8_t myVers;
  int16_t calibMid[4];
  int16_t calibSpan[4];
  uint16_t chkSum;
  uint8_t currModel; //0..15
  uint8_t contrast;
  uint8_t vBatWarn;
  int8_t  vBatCalib;  
  int8_t  lightSw;
  TrainerData_r0 trainer;
  uint8_t   view;     //index of subview in main scrren
  uint8_t   warnOpts; //bitset for several warnings
  uint8_t   stickMode;   // 1
  END_TYP


CStruct.defStruct "EEGeneral_r119",<<-"END_TYP"
  uint8_t   myVers;
  int16_t   calibMid[4];
  int16_t   calibSpanNeg[4]; //ge119
  int16_t   calibSpanPos[4]; //ge119
  uint16_t  chkSum;
  uint8_t   currModel; //0..15
  uint8_t   contrast;
  uint8_t   vBatWarn;
  int8_t    vBatCalib;  
  int8_t    lightSw;
  TrainerData_r0 trainer;
  uint8_t   view;     //index of subview in main scrren
#define WARN_THR (!(g_eeGeneral.warnOpts & 0x01))
#define WARN_SW  (!(g_eeGeneral.warnOpts & 0x02))
#define WARN_MEM (!(g_eeGeneral.warnOpts & 0x04))
#define BEEP_VAL ( (g_eeGeneral.warnOpts & 0x18) >>3 )
  uint8_t   warnOpts; //bitset for several warnings
  uint8_t   stickMode;   // 1
  END_TYP


CStruct.defStruct "EEGeneral_r150",<<-"END_TYP"
  uint8_t   myVers;
  int16_t   calibMid[7];             //ge150 4->7
  int16_t   calibSpanNeg[7]; //ge119 //ge150 4->7
  int16_t   calibSpanPos[7]; //ge119 //ge150 4->7
  //uint16_t  chkSum;
  uint8_t   inactivityMin;    //ge150
  uint8_t   resv;             //ge150
  uint8_t   currModel; //0..15
  uint8_t   contrast;
  uint8_t   vBatWarn;
  int8_t    vBatCalib; 
  int8_t    lightSw;
  TrainerData_r0 trainer;
  uint8_t   view2_2_4;  // was view in earlier versions
  uint8_t   warn3_2_3; //bitset for several warnings
  uint8_t   stickMode;   // 1
END_TYP

CStruct.defStruct "EEGeneral_r192",<<-"END_TYP"
  uint8_t   myVers;
  int16_t   calibMid[7];             //ge150 4->7
  int16_t   calibSpanNeg[7]; //ge119 //ge150 4->7
  int16_t   calibSpanPos[7]; //ge119 //ge150 4->7
  //uint16_t  chkSum;
  uint8_t   inactivityMin;    //ge150
  uint8_t   resv;             //ge150
  uint8_t   currModel; //0..15
  uint8_t   contrast;
  uint8_t   vBatWarn;
  int8_t    vBatCalib; 
  int8_t    lightSw;
  TrainerData_r192 trainer;
  uint8_t   view2_2_4;  // was view in earlier versions
  uint8_t   warn3_2_3; //bitset for several warnings
  uint8_t   stickMode;   // 1
END_TYP





MAX_MIXERS_V1 = 20
MAX_MODELS_V4 = 16
MAXFILES_V4   = (1+MAX_MODELS_V4+3)
CStruct.defStruct "ExpoData_r0",<<-"END_TYP"
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
  END_TYP

CStruct.defStruct "ExpoData_r84",<<-"END_TYP"
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
  int8_t  expNormWeight;
  int8_t  expSwWeight;
  END_TYP
CStruct.defStruct "ExpoData_r171",<<-"END_TYP"
  int8_t  exp:5,mode:3; //0=end 1=pos 2=neg 3=both 4=trimNeg
  int8_t  weight:6,chn:2;  //
  int8_t  drSw:5,curve:3; //
  END_TYP

module CStruct; class ExpoData_r171
  def to_sInternal(ofs,nest=0) # CStruct;
    bin=toBin()
    if bin[0,1] == "\0"
      s=omitIfWellknown("\0\0\0")
      #s= (bin=="\0\0\0" ? "" : bin.inspect) + "\n"
    else
      s=sprintf("%3s %s exp_%-4d %3d%% %4s %3s\n",
              %w(EOF >0 <0 1 T-)[mode], 
              %w(RUD ELE THR AIL)[chn],
              idx2val15_100(int5(exp)),
              idx2val30_100(int6(weight)),
              swtch204To_s(drSw), #evtl falsch
              crvTo_s(curve)
            )
    end
    [s,ofs+sizeof()]
  end
end;end
CStruct.defStruct "TrimData_r0",<<-"END_TYP"
  int8_t  trim;    //quadratisch
  int16_t trimDef_lt133;
  END_TYP

CStruct.defStruct "TrimData_r143",<<-"END_TYP"
  int8_t  trim[4];    //quadratisch
  END_TYP
module CStruct; class TrimData_r143
  def to_sInternal(ofs,nest=0) # CStruct;
    [(0...4).map{|i| "#{trim[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end

CStruct.defStruct "LimitData_r0",<<-"END_TYP"
  int8_t  min;
  int8_t  max;
  bool    revert;
  END_TYP

CStruct.defStruct "LimitData_r84",<<-"END_TYP"
  int8_t  min;
  int8_t  max; 
  int8_t  rev:1,offset:7;
  END_TYP
CStruct.defStruct "LimitData_r167",<<-"END_TYP"
  int8_t  min:7,scale:1;
  int8_t  max7; 
  int8_t  revert:1,offset:7;
  END_TYP
module CStruct; class LimitData_r167
  def lim(idx,ofs) # CStruct;
    idx = (idx+ofs) & 0x7f
    idx -= 128    if idx>=64 
    idx2val50_150(idx)
  end
  def to_sInternal(ofs,nest=0) # CStruct;
    s=sprintf("%4d < x < %4d  %s %s ofs %4d\n",
              lim(min,-40),
              lim(max7       ,+40),
              (scale) != 0 ? "scl" : "   ",
              (revert) != 0 ? "rev" : "   ",
              (offset)
            )
    [s,ofs+sizeof()]
  end
end;end

CStruct.defStruct "MixData_r0",<<-"END_TYP"
  uint8_t destCh:4,srcRaw:4; //
  int8_t  weight;
  uint8_t swtch:5,curve:3;
  uint8_t speedUp:4,speedDwn:4;
  END_TYP

module CStruct; class MixData_r0
  def to_sInternal(ofs,nest=0) # CStruct;
    if destCh == 0
      s=omitIfWellknown("\0\0\0\0")
    else
    s=sprintf("%3s %3s %4d%% %s %s dwn%d up%d\n",
            chnOutTo_s(destCh),
            chnInTo_s(srcRaw),
            weight,
            crvTo_s(curve),
            swtchTo_s(swtch),
            speedDwn,
            speedUp
            )
    end
    [s,ofs+sizeof()]
  end
end;end

CStruct.defStruct "MixData_r192",<<-"END_TYP"
  uint8_t destCh:4,mixMode:2; //
  uint8_t srcRaw:5,switchMode:2,curveNeg:1; //
  int8_t  weight;
  uint8_t swtch:5,curve:3;
  uint8_t speedUp:4,speedDwn:4;

  END_TYP
module CStruct; class MixData_r192
  def to_sInternal(ofs,nest=0) # CStruct;
    bin=toBin()
    if bin[0,1] == "\0"
      s=omitIfWellknown("\0\0\0\0\0")
    else
    s=sprintf("%3s %3s %4d%% %s %s dwn%d up%d\n",
            chnOutTo_s(destCh),
            chnIn192To_s(srcRaw),
            weight,
            crvTo_s(curve,curveNeg),
            swtch204To_s(swtch), #evtl falsch
            speedDwn,
            speedUp
            )
    end
    [s,ofs+sizeof()]
  end
end;end

#x=CStruct::MixData_r0.new
#pp x.methods.sort
#pp x.to_s
#exit

CStruct.defStruct "Crv3_V4",<<-"END_TYP"
  int8_t    c[3];
  END_TYP
module CStruct; class Crv3_V4
  def to_sInternal(ofs,nest=0) # CStruct;
    [(0...3).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end
CStruct.defStruct "Crv5_V4",<<-"END_TYP"
  int8_t    c[5];
  END_TYP
module CStruct; class Crv5_V4
  def to_sInternal(ofs,nest=0) # CStruct;
    [(0...5).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end
CStruct.defStruct "Crv9_V4",<<-"END_TYP"
  int8_t    c[9];
  END_TYP
module CStruct; class Crv9_V4
  def to_sInternal(ofs,nest=0) # CStruct;
    [(0...9).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end




CStruct.defStruct "SwitchData_r204",<<-"END_TYP"
  uint8_t sw:3     //0..7 
  uint8_t opCmp:2  //< & | ^ 
  uint8_t opRes:3; //0 => 1=> 0=> !=> & | ^
  int8_t val1; //
  int8_t val2; //
  END_TYP



module CStruct; class SwitchData_r204
  def to_sInternal(ofs,nest=0) # CStruct;
    if opRes==0
      s=omitIfWellknown("\0\0\0")
    else
    s=sprintf("SW%d  %4s %3s %4s   %5s\n",
              sw+1,
              swVal(val1),
              %w(< & | ^)[opCmp],
              swVal(val2),
              %w(0 Set On Off Inv & | ^)[opRes]
            )
    end
    [s,ofs+sizeof()]
  end
end;end



CStruct.defStruct "ModelData_r0",<<-"END_TYP"
  char      name[10];    // 10
  uint8_t   stickMode;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  LimitData_r0 limitData[8];// 3*8
  ExpoData_r0  expoData[4]; // 3*4
  MixData_r0   mixData[#{MAX_MIXERS_V1}]; //4*20
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r0  trimData[4]; // 3*4
  END_TYP


MDVERS84 = 1

CStruct.defStruct "ModelData_helper",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  END_TYP

CStruct.defStruct "ModelData_r84",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol;             // 1
  char      res[3];               // 3
  LimitData_r84 limitData[8];// 4*8
  ExpoData_r84  expoData[4];          // 5*4
  MixData_r0   mixData[25];  //0 4*25
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r0  trimData[4];          // 3*4
  END_TYP

MDVERS143 = 2
CStruct.defStruct "ModelData_r143",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol;             // 1
  char      res[3];               // 3
  LimitData_r84 limitData[8];// 4*8
  ExpoData_r84  expoData[4];          // 5*4
  MixData_r0   mixData[25];  //0 4*25
  Crv3_V4   curves3[3];   // 9
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r143  trimData;    // 3*4 -> 1*4
 END_TYP
  
CStruct.defStruct "ModelData_r167",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol;             // 1
  char      res[3];               // 3
  LimitData_r167 limitData[8];// 4*8
  ExpoData_r84  expoData[4];          // 5*4
  MixData_r0   mixData[25];  //0 4*25
  Crv3_V4   curves3[3];   // 9
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r143  trimData;    // 3*4 -> 1*4

 END_TYP
CStruct.defStruct "ModelData_r171",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol;             // 1
  char      res[3];               // 3
  LimitData_r167 limitData[8];// 4*8
  ExpoData_r171  expoTab[15];      // 5*4 -> 4*15
  MixData_r0   mixData[25];  //0 4*25
  Crv3_V4   curves3[3];   // 9
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r143  trimData;    // 3*4 -> 1*4
 END_TYP
CStruct.defStruct "ModelData_r192",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol;             // 1
  char      res[3];               // 3
  LimitData_r167 limitData[8];// 4*8
  ExpoData_r171  expoTab[15];      // 5*4 -> 4*15
  MixData_r192   mixData[25];  //0 4*25
  Crv3_V4   curves3[3];   // 9
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  TrimData_r143  trimData;    // 3*4 -> 1*4
 END_TYP
CStruct.defStruct "ModelData_r204",<<-"END_TYP"
  char      name[10];             // 10 must be first for eeLoadModelName
  uint8_t   mdVers;               // 1
  uint8_t   tmrMode:3,tmrSw:5;              // 1
  uint16_t  tmrVal;               // 2
  uint8_t   protocol:5,protPar:3;             // 1
  char      res[3];               // 3
  LimitData_r167 limitData[8];// 4*8
  ExpoData_r171  expoTab[15];      // 5*4 -> 4*15
  MixData_r192   mixData[25];  //0 4*25
  Crv3_V4   curves3[3];   // 9
  Crv5_V4   curves5[2];   // 10
  Crv9_V4   curves9[2];   // 18
  SwitchData_r204 switchTab[16];//
  TrimData_r143  trimData;    // 3*4 -> 1*4
 END_TYP
  




CStruct.defStruct "DirEnt_V4",<<-"END_TYP"
  uint8_t  startBlk;
  uint16_t size_typ;
  END_TYP

CStruct.defStruct "EeFs_V4",<<-"END_TYP"
  uint8_t  version;
  uint8_t  mySize;
  uint8_t  freeList;
  uint8_t  bs;
  DirEnt_V4   files[#{MAXFILES_V4}];
  END_TYP




module Codec
  def Codec.encode(buf) # Codec Reader_V4
    buf=buf.dup
    obuf   = ""
    cnt    = 0
    state0 = true
    i_len  = buf.length
    (i_len+1).times{|i|
      nst0 = buf[i] == 0
      nst0 = false if  nst0 && !state0 && buf[i+1]!=0
      if nst0 != state0 || cnt>=0x7f || i==i_len
        if(state0)
          if cnt>0
            cnt|=0x80;
            obuf += cnt.chr
            cnt=0;
          end
        else
          obuf += cnt.chr
          obuf += buf[i-cnt,cnt]
          cnt=0;
        end
        state0 = nst0
      end
      cnt+=1
    }
    obuf
  end
  def Codec.encode2(buf) # Codec Reader_V4
    buf=buf.dup
    obuf   = ""
    cnt2   = 0
    cnt    = 0
    state0 = true
    i_len  = buf.length
    (i_len+1).times{|i|
      nst0 = buf[i] == 0
      # nst0 = false if  nst0 && !state0 && buf[i+1]!=0
      if nst0 != state0 || cnt==0x3f || (cnt2!=0 && cnt==0xf) || i==i_len
        if(state0)
          if cnt!=0
	    if cnt<8 and i!=i_len
	      cnt2=cnt
	    else
	      obuf += (0x40|cnt).chr #emit immediate 01zzzzzz
	    end
          end
        else
	  if cnt2!=0
	    #pp cnt,cnt2
	    obuf += (0x80 | (cnt2<<4) | cnt).chr # 1zzzxxxx
	  else
	    obuf += cnt.chr   #00xxxxxx
	  end
	  obuf += buf[i-cnt,cnt]
	  cnt2=0
        end
	cnt=0;
        state0 = nst0
      end
      cnt+=1
    }
    obuf
  end
  def Codec.decode1(inbuf,len=10000) # Codec Reader_V4
    inbuf=inbuf.dup
    outbuf=""
    while inbuf.length != 0 and len!=0
      ctrl = inbuf.lcut(1)[0]
      if ctrl &0x80 != 0
        ctrl &= 0x7f
        l=[ctrl,len].min
        outbuf += 0.chr * (l)
      else
        l=[ctrl,len].min
        outbuf += inbuf.lcut(l)
      end
      len -= l
    end
    outbuf
  end
  def Codec.decode2(inbuf,len=10000) # Codec Reader_V4
    inbuf=inbuf.dup
    outbuf=""
    zeros=0
    ctrl=0
    while 1 #inbuf.length != 0 and len!=0
      l=[zeros,len].min
      outbuf += 0.chr * l
      zeros  -= l
      len    -= l
      return outbuf if zeros!=0
      l=[ctrl,len].min
      outbuf += inbuf.lcut(l)
      ctrl   -= l
      len    -= l
      return outbuf if ctrl!=0
      return outbuf if inbuf.length == 0

      ctrl = inbuf.lcut(1)[0]
      if ctrl &0x80 != 0
	zeros = (ctrl>>4) & 0x7
	ctrl &= 0x0f
      else
	if ctrl &0x40 != 0
	  zeros = ctrl&0x3f
	  ctrl  = 0
	end
      end
    end
    outbuf
  end
  
end

#x=CStruct::ModelData_r84.new
#x.fromBin("\0"*500)
#puts x 
#  exit
class ErrorBadNextIndex < Exception; end
class Reader_V4
#  def deepCopy(dst,src,key="") # Reader_V4
#    #pp "---",src
#    src.each{|n,val,obj|
#      n=n.sub(/swtch_posNeg/,"swtch5_curve3")
#      n=n.sub(/destCh_srcRaw/,"destCh4_srcRaw4")
#      k2 = key+"/"+n #.to_s
#      if(!dst.child(n))
#        puts "#{k2} not in dst"
#        next
#      end
#      if obj.is_a? CStruct::BaseT
#        dst.child(n).set(val)
#      else
#        deepCopy(dst.child(n),obj,k2)
#      end
#    }
#  end
#  def mod_fromV1(modv1) # Reader_V4
#    modv4=CStruct::ModelData_V4.new()
#    deepCopy(modv4,modv1)
#    modv4.limitData.each{|n,val,obj|
#      obj.min+=100
#      obj.max-=100
#    }
#    modv4.mixData.each{|n,val,obj|
#      if (obj.swtch5_curve3 & 0x1f) != 0
#        obj.swtch5_curve3-=1 if (obj.swtch5_curve3 & 0x1f) <  0x10
#        obj.swtch5_curve3+=1 if (obj.swtch5_curve3 & 0x1f) >= 0x10
#      end
#    }
#    modv4
#    #puts modv4
#  end
  attr_reader :fbuf, :fbufdec
  def Reader_V4.mbuf2name(rawbuf) # Reader_V4
    mbuf=Codec::decode1(rawbuf,11)
    hlp=CStruct::ModelData_helper.new()
    hlp.fromBin(mbuf)
    hlp.name
  end

  def chain_each(i,lim=255) # Reader_V4
    cnt=0
    while i!=0
      nxt=@wholeEEprom[i*16+0]
      #printf("chain %d -> %d \n",i,nxt)
      if block_given?
        break if ! yield( i,cnt,nxt)
      end
      cnt += 1
      break if cnt>=lim
      raise ErrorBadNextIndex.new("bad next index %d"%nxt)  if nxt>=0x80
      i = nxt
    end
  end
  def format # Reader_V4
    @eefs=CStruct::EeFs_V4.new()
    @eefs.version=4
    @eefs.mySize=64
    @eefs.bs=16
    @wholeEEprom = 0.chr*2048
    (5..127).each{|i|
      @wholeEEprom[i*16]=i-1
    }
    @eefs.freeList=127
#    general=CStruct::EEGeneral_r0.new()
#    general.myVers = 1
#    general.contrast = 30
#    general.vBatWarn = 90
#    sum=0
#    4.times{|i|
#      general.calibMid[i]  = 0x200;
#      general.calibSpan[i] = 0x180;
#      sum+=0x200+0x180
#    }
#    general.chkSum = sum & 0xffff;
#    write(0,1,Codec::encode(general.toBin))
  end
  def freeBlks(i) # Reader_V4
    while i!=0
      inxt = @wholeEEprom[i*16]
      @wholeEEprom[i*16] = @eefs.freeList
      @eefs.freeList = i
      i=inxt
    end
  end
  def alloc() # Reader_V4
    ret=@eefs.freeList
    ret != 0 or raise "eeprom full"
    @eefs.freeList=@wholeEEprom[ret*16]
    @wholeEEprom[ret*16]=0
    ret
  end
  def writeFile(fi,typ,buf) # Reader_V4
    buf=buf.dup #dont destroy source
    @eefs.files[fi].startBlk = p = alloc()
    @eefs.files[fi].size_typ = buf.length + (typ << 12 ) 
    while buf.length!=0
      ct=buf.lcut(15)
      @wholeEEprom[p*16+1,ct.length] = ct
      if buf.length!=0
         p=@wholeEEprom[p*16]=alloc
      end
    end
  end
  def rmFile(fi) # Reader_V4
    freeBlks(@eefs.files[fi].startBlk)
    @eefs.files[fi].startBlk = 0
    @eefs.files[fi].size_typ = 0
  end
  def rmAllFiles() # Reader_V4
    MAXFILES_V4.times{|fi|rmFile(fi)}
  end
  def readFile(fi) # Reader_V4
    bi  = @eefs.files[fi].startBlk
    typ = (@eefs.files[fi].size_typ >> 12) & 0xf
    sz  = @eefs.files[fi].size_typ & 0xfff
    buf = ""
    chain_each(bi){ |j,cnt,nxt|
      buf+=@wholeEEprom[j*16+1,15]
      true
    }
    [buf[0,sz],typ,sz]
  end

  #read eeprom, separate header, check integrity
  def readEEprom(f) # Reader_V4
    @wholeEEprom = f.read                                # whole eeprom data
    @eefs        = CStruct::EeFs_V4.new()                # fs-header

    @eefs.fromBin(@wholeEEprom[0,@eefs.sizeof])
    @eefs.mySize == (@eefs.sizeof) or raise "bad size eefs #{@eefs.mySize} != #{(@eefs.sizeof)}"

    checkFat
  end
  attr_reader :spclBlks,:totBlks,:freeBlks,:usedBlks
  def checkFat # Reader_V4
    @totBlks = @wholeEEprom.length/16  
    @spclBlks = 4
    fatInfo     = Array.new(@totBlks,nil) # fat info
    # integrity check all files
    usedBlks=0
    MAXFILES_V4.times{|fi|
      bi  = @eefs.files[fi].startBlk
      sz  = @eefs.files[fi].size_typ & 0xfff
      # buf = ""
      chain_each(bi){ |j,cnt,nxt|
        # buf+=@wholeEEprom[j*16+1,15]
        if fatInfo[j] 
          puts "ERROR multiple use of block #{j}" 
          infoMap
          break
        end
        usedBlks+=1
        fatInfo[j]=(fi+?a).chr+("%02d "%cnt);
        true
      }
      # @fbuf[fi]    = buf[0,sz]
    }
    #check free chain
    freeBlks=0
    chain_each(@eefs.freeList){|j,cnt,nxt| 
      freeBlks+=1
      puts "ERROR used block is also in free chain #{j}" if fatInfo[j] 
      if nxt>=0x80
        puts "ERROR bad chain index #{nxt} at idx#{j} = adr 0x%04x"%(j*16)
        fatInfo[j]="%+3d "%(nxt-j); 
        false
      else
        if nxt==0
          fatInfo[j]="000 "
        else
          fatInfo[j]="%+3d "%(nxt-j)
        end
        true
      end
    }
    fatInfo.each_with_index{|f,i|
      next if i<@spclBlks
      puts "ERROR lost block #{i}" if !f 
    }
    @freeBlks=freeBlks
    @usedBlks=usedBlks
    @usedBlks+@freeBlks+@spclBlks == @totBlks or raise ""
    [fatInfo,freeBlks]
  end

  def eachFile() # Reader_V4
    MAXFILES_V4.times{|fi|
      fb,typ,sz=readFile(fi)
      next if fb == ""
      yield fi,Reader_V4.mbuf2name(fb),fb
    }
  end
  def toBin # Reader_V4
    @eefs.toBin+@wholeEEprom[64..-1]
  end


  def infoMap(arg=nil,full=nil) # Reader_V4
    puts "allocation map"

    fatInfo,freeBlks=checkFat

    fatInfo.each_with_index{|fx,i|
      print fx ? fx : '////'
      puts if i%16==15
    }
    puts
    puts "name sz typ sz2  blocks"
    puts "-----------------------"
    #     a    24  1   40  127, 126,
    MAXFILES_V4.times{|i|
      infoFile(i)  if !arg or arg.to_i == i
    }
    MAXFILES_V4.times{|i|
      infoFileFull(i) if !arg or arg.to_i == i
    } if full
  end
  def info(arg=nil,full=nil) # Reader_V4
    @eefs.each{|n,val,obj|
      printf("%10s %5d 0x%x (%s)\n",n,val,val,obj.class.to_s[9..-1]) if val.is_a? Numeric
    }
    puts
    fatInfo,freeBlks=checkFat
    totbl=fatInfo.length-4
    puts "freeBlks=#{freeBlks}/#{totbl} freeSz=#{freeBlks*(@eefs.bs-1)} totSz=#{totbl*(@eefs.bs-1)}"
    infoMap(arg,full)
  end

  def infoFileTyp(fb) # Reader_V4
    #buf=Codec::decode1(@fbuf[fi],11)
    #fb,typ,sz=readFile(fi)
    buf=Codec::decode1(fb,11)
    return nil,nil if buf == ""
    hlp=CStruct::EEGeneral_helper.new()
    hlp.fromBin(buf)
    case v=hlp.myVers
    when 1  ;   return "EEGeneral_r0              ",1,CStruct::EEGeneral_r0
    when 2  ;   return "EEGeneral_r119            ",1,CStruct::EEGeneral_r119
    when 3  ;   return "EEGeneral_r119_3          ",1,CStruct::EEGeneral_r119
    when 4  ;   return "EEGeneral_r150            ",1,CStruct::EEGeneral_r150
    when 5  ;   return "EEGeneral_r150_5          ",1,CStruct::EEGeneral_r150
    when 6  ;   return "EEGeneral_r192            ",2,CStruct::EEGeneral_r192
    else;
      hlp=CStruct::ModelData_helper.new()
      hlp.fromBin(buf)
      #p hlp
      if hlp.mdVers<=3
        buf=Codec::decode1(fb)
        if buf.length==CStruct::ModelData_r0.new().sizeof
          return 	"ModelData_r0  '#{hlp.name}'",1,CStruct::ModelData_r0
        end
      end

      case hlp.mdVers
      when 1;	return 	"ModelData_r84 '#{hlp.name}'",1,CStruct::ModelData_r84
      when 2; return 	"ModelData_r143'#{hlp.name}'",1,CStruct::ModelData_r143
      when 3; return 	"ModelData_r167'#{hlp.name}'",1,CStruct::ModelData_r167
      when 4; return 	"ModelData_r171'#{hlp.name}'",1,CStruct::ModelData_r171
      when 5; return 	"ModelData_r192'#{hlp.name}'",2,CStruct::ModelData_r192
      when 6; return 	"ModelData_r204'#{hlp.name}'",2,CStruct::ModelData_r204
      else;   return 	"ModelData??   '#{hlp.name}'",0,nil
      end
    end
  end
  def infoFileFull(fi) # Reader_V4
    fb,typ,sz=readFile(fi)
    cmt,dec,cls = infoFileTyp(fb)
    puts "--- File #{fi} '#{cmt}' D#{dec}: ---------------------------------"
    return if !cls
    obj=cls.new
    #obj.fromBin(@fbufdec[fi])
    fbufdec = (dec==1 ? Codec::decode1(fb) : Codec::decode2(fb))
    puts "szRaw=#{fb.length} szDec=#{fbufdec.length}"
    obj.fromBin(fbufdec)
    puts obj
  end
  def infoFile(fi) # Reader_V4
    bi  = @eefs.files[fi].startBlk
    sz  = @eefs.files[fi].size_typ & 0xfff
    typ = @eefs.files[fi].size_typ   >> 12
    fb,typ,sz=readFile(fi)
    cmt,dec,cls = infoFileTyp(fb)
    fbufdec = (dec==1 ? Codec::decode1(fb) : Codec::decode2(fb))
    printf("%s  %4d %2d  %3d %s D#{dec}",(fi+?a).chr,sz,typ,fbufdec ? fbufdec.length : 0,cmt)
    chain_each(bi,10){|j,cnt,nxt|  printf(" %d,",j); true}
    puts
  end
#  def export(dir) # Reader_V4
#    @fbufdec.each_with_index{|buf,i|
#      typ = @eefs.files[i].size_typ   >> 12
#      File.open(dir+("/V4_%02d_%d"%[i,typ]),"wb"){|fh|fh.write(buf)}
#    }
#  end
end



class Main
  def initialize # Main
    opts=ARGV.options
    prg=File.basename($0)
    opts.summary_width=20
    opts.banner = "
Synopsis
    #{prg} [options] cmd
    #{prg}  ls     file [fnum]
    #{prg}  export file [dir=export]
Description
Options
"
    opts.on("-h","--help", "show this message")   {puts opts; exit}
    $opt_v=0
    opts.on("-q",          "be quiet")            {$opt_v  = -1  }
    opts.on("-v[lev]",     "set or increase verbose level (#{$opt_v})") { |v|        $opt_v += 1
      $opt_v  = v.to_i   if v =~ /^\d+$/
      $opt_v += v.length if v =~ /^v+$/
    }
    $opt_ee="eeprom.bin"
    opts.on("-ifile",     "eeprom file (#{$opt_ee})") { |$opt_ee|}
    $opt_o="out.bin"
    opts.on("-ofile",     "output file (#{$opt_o})") { |$opt_o|}
    opts.parse!
    cmd=ARGV.shift || "ls"
    send(cmd)
  end
#  def export() # Main
#    dir  = ARGV[0] || 'export'
#    Dir.mkdir(dir) if !File.directory?(dir)
#    r=read($opt_ee)
#    r.export(dir)
#  end
  def new
    eeWriter=Reader_V4.new
    eeWriter.format() 
    eeWriter.writeFile(1,2,"helloworld")
    eeWriter.info
    File.open(ARGV[0] || "eeprom","wb"){|f| f.write(eeWriter.toBin) }
  end

  def test() # Main
    i  = ARGV[0].to_i
    r=read($opt_ee)
    s1=0
    s2=0
    (0..19).each{|i|
      code1=r.fbuf[i] 
      full=r.fbufdec[i]
      code2=Codec::encode2(full) 
      full2=Codec::decode2(code2) 
      full==full2 or raise "#{full} != #{full2}"
      puts "#{code1[0,10].inspect} #{code2[0,10].inspect}"

      dx=code1.length-code2.length
      s1+=code1.length
      s2+=dx
      puts "f=#{full.length} c1=#{code1.length} c2=#{code2.length} dx=#{dx}"
    }
    pp s1,s2
  end
  def get() # Main
    i  = ARGV[0].to_i
    r=read($opt_ee)
    File.open($opt_o,"wb"){|f| 
      if ARGV[1] =~ /r/
	f.write(r.fbuf[i]) 
      else
	f.write(r.fbufdec[i])
      end
    }
  end
  def ls() # Main
    r=read($opt_ee)
    #puts "eeprom version: #{@vers}"
    r.info(ARGV.shift,$opt_v>1)

    #r.rmFile(1)

    #r.info ARGV.shift
  end
  alias :info :ls
#  def convert # Main
#    dir  = ARGV[0] || 'export'
#    Dir.mkdir(dir) if !File.directory?(dir)
#    dv1=read($opt_ee).data
#    puts dv1.modelData[0]
#    rv4=Reader_V4.new
#    rv4.format
#    16.times{|m|
#      dv4 = rv4.mod_fromV1(dv1.modelData[m])
#      buf = dv4.toBin
#      pp buf
#      buf2 = Codec::encode(buf)
#      buf == Codec::decode1(buf2) or raise
#      pp buf2
#      #File.open(dir+("/V4_%02d_%d"%[m+1,2]),"wb"){|fh|dv4.write(fh)}
#      rv4.write(m+1,2,buf2)
#    }
#    File.open(dir+"/eeprom.gen","wb"){|fh| fh.write( rv4.close) }
#  end
  def read(file) # Main
    File.open(file,"rb"){|f|
      @vers=f.read(1)[0]
      f.seek(0)
      case @vers
      when 1; r=Reader_V1.new; r.readEEprom(f); return r
      when 4; r=Reader_V4.new; r.readEEprom(f); return r
      else
        raise "unknown eeprom version #{@vers}"
      end
    }
  end
end

Main.new if $0==__FILE__
