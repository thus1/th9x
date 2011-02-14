#! /usr/bin/env ruby


require File.dirname(__FILE__)+"/cstruct.rb"
require 'pp'
require 'optparse'

class String
  def lcut(n)
    ret=self[0,n]
    self[0,n]=""
    return ret
  end
end
class Integer
  def sgn()
    self<0 ? -1 : self==0 ? 0 : 1
  end
end
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
def crvTo_s(idx) 
  idx==0?"    " : "Crv#{idx}" 
end
def swtchTo_s(idx) 
  return "    " if idx==0 
  sprintf("%s%-3s",idx<0 ? "!":" ",%w(0 THR RUD ELE ID0 ID1 ID2 AIL GEA TRN ON)[idx])
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
  uint8_t srcChn3_swtch5; //0-7 = ch1-8
  uint8_t weight6_mode2;  //off,add-mode,subst-mode
  END_TYP

CStruct.defStruct "TrainerData_r0",<<-"END_TYP"
  int16_t       calib[4];
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
  int8_t  exp5_mode3; //0=end 1=pos 2=neg 3=both 4=trimNeg
  int8_t  weight6_chn2;  //
  int8_t  drSw5_curve3; //
  END_TYP

module CStruct; class ExpoData_r171
  def to_sInternal(ofs,nest=0)
    s=sprintf("%3s %s %4de %3d%% %4s %3s\n",
              %w(EOF >0 <0 1 T-)[exp5_mode3>>5], 
              %w(RUD ELE THR AIL)[weight6_chn2>>6],
              idx2val15_100(int5(exp5_mode3)),
              idx2val30_100(int6(weight6_chn2)),
              swtchTo_s(drSw5_curve3&0x1f),
              crvTo_s(drSw5_curve3>>5)
            )
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
  def to_sInternal(ofs,nest=0)
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
  int8_t  rev_offset;
  END_TYP
CStruct.defStruct "LimitData_r167",<<-"END_TYP"
  int8_t  min7_scale1;
  int8_t  max7; 
  int8_t  revert1_offset7;
  END_TYP
module CStruct; class LimitData_r167
  def lim(idx,ofs)
    #puts "#{idx} #{ofs}"
    idx = (idx+ofs) & 0x7f
    idx -= 128    if idx>=64 
    #puts "#{idx} #{ofs}"
    idx2val50_150(idx)
  end
  def to_sInternal(ofs,nest=0)
    s=sprintf("%4d < x < %4d  %s %s ofs %4d\n",
              lim(min7_scale1,-40),
              lim(max7       ,+40),
              (min7_scale1>>7) != 0 ? "scl" : "   ",
              (revert1_offset7&1) != 0 ? "rev" : "   ",
              (revert1_offset7/2)
            )
    [s,ofs+sizeof()]
  end
end;end

CStruct.defStruct "MixData_r0",<<-"END_TYP"
  uint8_t destCh4_srcRaw4; //
  int8_t  weight;
  uint8_t  swtch5_curve3;
  uint8_t  speedUp4_speedDwn4;
  END_TYP



module CStruct; class MixData_r0
  def to_sInternal(ofs,nest=0)
    s=sprintf("%3s %3s %4d%% %s %s dwn%d up%d\n",
            chnOutTo_s((destCh4_srcRaw4&0xf)),
            chnInTo_s((destCh4_srcRaw4>>4)),
            weight,
            crvTo_s(swtch5_curve3>>5),
            swtchTo_s(swtch5_curve3&0x1f),
            speedUp4_speedDwn4>>4,
            speedUp4_speedDwn4&0xf
            )
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
  def to_sInternal(ofs,nest=0)
    [(0...3).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end
CStruct.defStruct "Crv5_V4",<<-"END_TYP"
  int8_t    c[5];
  END_TYP
module CStruct; class Crv5_V4
  def to_sInternal(ofs,nest=0)
    [(0...5).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
  end
end;end
CStruct.defStruct "Crv9_V4",<<-"END_TYP"
  int8_t    c[9];
  END_TYP
module CStruct; class Crv9_V4
  def to_sInternal(ofs,nest=0)
    [(0...9).map{|i| "#{c[i]}"}.join(",")+"\n",ofs+sizeof()]
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

  
  
class ErrorBadNextIndex < Exception; end
class Reader_V4
  def deepCopy(dst,src,key="")
    #pp "---",src
    src.each{|n,val,obj|
      n=n.sub(/swtch_posNeg/,"swtch5_curve3")
      n=n.sub(/destCh_srcRaw/,"destCh4_srcRaw4")
      k2 = key+"/"+n #.to_s
      if(!dst.child(n))
        puts "#{k2} not in dst"
        next
      end
      if obj.is_a? CStruct::BaseT
        dst.child(n).set(val)
      else
        deepCopy(dst.child(n),obj,k2)
      end
    }
  end
  def mod_fromV1(modv1)
    modv4=CStruct::ModelData_V4.new()
    deepCopy(modv4,modv1)
    modv4.limitData.each{|n,val,obj|
      obj.min+=100
      obj.max-=100
    }
    modv4.mixData.each{|n,val,obj|
      if (obj.swtch5_curve3 & 0x1f) != 0
        obj.swtch5_curve3-=1 if (obj.swtch5_curve3 & 0x1f) <  0x10
        obj.swtch5_curve3+=1 if (obj.swtch5_curve3 & 0x1f) >= 0x10
      end
    }
    modv4
    #puts modv4
  end
  def read(f)
    @eefs=CStruct::EeFs_V4.new()
    @eefs.read(f)
    @eefs.mySize == (@eefs.sizeof) or raise "bad size eefs #{@eefs.mySize} != #{(@eefs.sizeof)}"
    @bs=@eefs.bs
    @blocks = 0.chr*@eefs.mySize + f.read

    @fat=Array.new(@blocks.length/16,nil)
    @fbuf=[]
    @fbufdec=[]

    MAXFILES_V4.times{|fi|
      bi  = @eefs.files[fi].startBlk
      sz  = @eefs.files[fi].size_typ & 0xfff
      buf=""
      chain_each(bi){ |j,cnt,nxt|
        buf+=@blocks[j*16+1,15]
        if @fat[j] 
          puts "ERROR multiple use of block #{j}" 
          infoMap
          break
        end
        @fat[j]=(fi+?a).chr+("%02d "%cnt);
        true
      }
      @fbuf[fi]    = buf[0,sz]
      @fbufdec[fi] = decode(@fbuf[fi])
    }
    #free chain
    @freeBlks=0
    chain_each(@eefs.freeList){|j,cnt,nxt| 
      @freeBlks+=1
      puts "ERROR used block is also in free chain #{j}" if @fat[j] 
      if nxt>=0x80
        puts "ERROR bad chain index #{nxt} at idx#{j} = adr 0x%04x"%(j*16)
        @fat[j]="%+3d "%(nxt-j); 
        false
      else
        @fat[j]="%+3d "%(nxt-j); 
        true
      end
    }
    @fat.each_with_index{|f,i|
      next if i<4
      puts "ERROR lost block #{i}" if !f 
    }
  end
  def format
    @eefs=CStruct::EeFs_V4.new()
    @eefs.version=4
    @eefs.mySize=64
    @eefs.bs=16
    @blocks = 0.chr*2048
    (5..127).each{|i|
      @blocks[i*16]=i-1
    }
    @eefs.freeList=127
    general=CStruct::EEGeneral_V4.new()
    general.myVers = 1
    general.contrast = 30
    general.vBatWarn = 90
    sum=0
    4.times{|i|
      general.calibMid[i]  = 0x200;
      general.calibSpan[i] = 0x180;
      sum+=0x200+0x180
    }
    general.chkSum = sum & 0xffff;
    write(0,1,encode(general.toBin))
  end
  def alloc()
    ret=@eefs.freeList
    @eefs.freeList=@blocks[ret*16]
    @blocks[ret*16]=0
    ret
  end
  def write(fi,typ,buf)
    @eefs.files[fi].startBlk = p = alloc()
    @eefs.files[fi].size_typ = buf.length + (typ << 12 ) 
    while buf.length!=0
      ct=buf.lcut(15)
      @blocks[p*16+1,ct.length] = ct
      if buf.length!=0
         p=@blocks[p*16]=alloc
      end
    end
  end
  def close
    @eefs.toBin+@blocks[64..-1]
  end

  def infoMap
    puts "allocation map"
    @fat.each_with_index{|fx,i|
      print fx ? fx : '////'
      puts if i%16==15
    }
    puts
    puts "name sz typ sz2  blocks"
    puts "-----------------------"
    #     a    24  1   40  127, 126,
    MAXFILES_V4.times{|i|infoFile(i)}
    MAXFILES_V4.times{|i|infoFileFull(i)} if $opt_v>=1
  end
  def info
    @eefs.each{|n,val,obj|
      printf("%10s %5d 0x%x (%s)\n",n,val,val,obj.class.to_s[9..-1]) if val.is_a? Numeric
    }
    puts
    puts "freeBlks=#{@freeBlks} freeSz=#{@freeBlks*@bs}"
    infoMap
  end

  def encode(buf)
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
  def decode(inbuf)
    inbuf=inbuf.dup
    outbuf=""
    while inbuf.length != 0
      ctrl = inbuf.lcut(1)[0]
      if ctrl &0x80 != 0
        outbuf += 0.chr * (ctrl&0x7f)
      else
        outbuf += inbuf.lcut(ctrl)
      end
    end
    outbuf
  end
  def chain_each(i,lim=255)
    cnt=0
    while i!=0
      nxt=@blocks[i*16+0]
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
  def infoFileTyp(fi)
    buf=@fbufdec[fi]
    return nil,nil if buf == ""
    hlp=CStruct::EEGeneral_helper.new()
    hlp.fromBin(buf)
    case v=hlp.myVers
    when 1  ;   return "EEGeneral_r0              ",CStruct::EEGeneral_r0
    when 2  ;   return "EEGeneral_r119            ",CStruct::EEGeneral_r119
    when 3  ;   return "EEGeneral_r119_3          ",CStruct::EEGeneral_r119
    when 4  ;   return "EEGeneral_r150            ",CStruct::EEGeneral_r150
    when 5  ;   return "EEGeneral_r150_5          ",CStruct::EEGeneral_r150
    else;
      hlp=CStruct::ModelData_helper.new()
      hlp.fromBin(buf)
      #p hlp
      if buf.length==CStruct::ModelData_r0.new().sizeof
	return 			"ModelData_r0  '#{hlp.name}'",CStruct::ModelData_r0
      else
	case hlp.mdVers
	when 1;	return 	"ModelData_r84 '#{hlp.name}'",CStruct::ModelData_r84
	when 2; return 	"ModelData_r143'#{hlp.name}'",CStruct::ModelData_r143
	when 3; return 	"ModelData_r167'#{hlp.name}'",CStruct::ModelData_r167
	when 4; return 	"ModelData_r171'#{hlp.name}'",CStruct::ModelData_r171
	else;     	return 	"ModelData??   '#{hlp.name}'",nil
	end
      end
    end
  end
  def infoFileFull(fi)
    cmt,cls = infoFileTyp(fi)
    puts "--- File #{fi} '#{cmt}': ---------------------------------"
    return if !cls
    obj=cls.new
    obj.fromBin(@fbufdec[fi])
    puts obj
  end
  def infoFile(fi)
    bi  = @eefs.files[fi].startBlk
    sz  = @eefs.files[fi].size_typ & 0xfff
    typ = @eefs.files[fi].size_typ   >> 12
    cmt,cls = infoFileTyp(fi)

    printf("%s  %4d %2d  %3d %s",(fi+?a).chr,sz,typ,@fbufdec[fi] ? @fbufdec[fi].length : 0,cmt)
    chain_each(bi,10){|j,cnt,nxt|  printf(" %d,",j); true}
    puts
  end
  def export(dir)
    @fbufdec.each_with_index{|buf,i|
      typ = @eefs.files[i].size_typ   >> 12
      File.open(dir+("/V4_%02d_%d"%[i,typ]),"w"){|fh|fh.write(buf)}
    }
  end
end



class Main
  def initialize
    opts=ARGV.options
    prg=File.basename($0)
    opts.summary_width=20
    opts.banner = "
Synopsis
    #{prg} [options] cmd
    #{prg}  info   file
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
    opts.parse!
    cmd=ARGV.shift || "info"
    send(cmd)
  end
  def export()
    file = ARGV[0] || 'eeprom.bin'
    dir  = ARGV[1] || 'export'
    Dir.mkdir(dir) if !File.directory?(dir)
    r=read(file)
    r.export(dir)
  end
  def info()
    file = ARGV[0] || 'eeprom.bin'
    r=read(file)
    #puts "eeprom version: #{@vers}"
    r.info
  end
  def convert
    file = ARGV[0] || 'eeprom.bin'
    dir  = ARGV[1] || 'export'
    Dir.mkdir(dir) if !File.directory?(dir)
    dv1=read(file).data
    puts dv1.modelData[0]
    rv4=Reader_V4.new
    rv4.format
    16.times{|m|
      dv4 = rv4.mod_fromV1(dv1.modelData[m])
      buf = dv4.toBin
      pp buf
      buf2 = rv4.encode(buf)
      buf == rv4.decode(buf2) or raise
      pp buf2
      #File.open(dir+("/V4_%02d_%d"%[m+1,2]),"w"){|fh|dv4.write(fh)}
      rv4.write(m+1,2,buf2)
    }
    File.open(dir+"/eeprom.gen","w"){|fh| fh.write( rv4.close) }
  end
  def read(file)
    File.open(file){|f|
      @vers=f.read(1)[0]
      f.seek(0)
      case @vers
      when 1; r=Reader_V1.new; r.read(f); return r
      when 4; r=Reader_V4.new; r.read(f); return r
      else
        raise "unknown eeprom version #{@vers}"
      end
    }
  end
end


Main.new
