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


# V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1V1

EE_VERSION_V1=1
MAX_MODELS_V1=16
MAX_MIXERS_V1=20

CStruct.alignment=1
CStruct.defStruct "EEGeneral_V1",<<-"END_TYP"
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


CStruct.defStruct "ExpoData_V1",<<-"END_TYP"
  int8_t  expNorm;
  int8_t  expDr;
  int8_t  drSw;
  END_TYP
CStruct.defStruct "TrimData_V1",<<-"END_TYP"
  int8_t  trim;    //quadratisch
  int16_t trimDef;
  END_TYP
CStruct.defStruct "LimitData_V1",<<-"END_TYP"
  int8_t  min;
  int8_t  max;
  bool    revert;
  END_TYP

CStruct.defStruct "MixData_V1",<<-"END_TYP"
  uint8_t destCh_srcRaw; //
  int8_t  weight;
  int8_t  swtch_posNeg;
  END_TYP

CStruct.defStruct "ModelData_V1",<<-"END_TYP"
  char      name[10];    // 10
  uint8_t   stickMode;   // 1
  uint8_t   tmrMode;     // 1
  uint16_t  tmrVal;      // 2
  uint8_t   protocol;    // 1
  char      res[3];      // 3
  ExpoData_V1  expoData[4]; // 3*4
  TrimData_V1  trimData[4]; // 3*4
  LimitData_V1 limitData[8];// 3*8
  MixData_V1   mixData[#{MAX_MIXERS_V1}]; //3*20
  END_TYP

CStruct.defStruct "WholeEeprom_V1",<<-"END_TYP"
  EEGeneral_V1 eEGeneral;
  ModelData_V1 modelData[#{MAX_MODELS_V1}];
  END_TYP

class Reader_V1
  def read(f)
    @eep=CStruct::WholeEeprom_V1.new()
    @eep.read(f)
  end
  def info
    puts @eep
  end
end


# V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4V4

MAX_MODELS_V4 = 16
MAXFILES_V4   = (1+MAX_MODELS_V4+3)

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


class Reader_V4
  def read(f)
    @eefs=CStruct::EeFs_V4.new()
    @eefs.read(f)
    @eefs.mySize == (@eefs.sizeof) or raise "bad size eefs"
    @bs=@eefs.bs
    @blocks = 0.chr*@eefs.mySize + f.read

    @fat=Array.new(@blocks.length/16,nil)
    @fbuf=[]
    @fbufdec=[]

    MAXFILES_V4.times{|fi|
      bi  = @eefs.files[fi].startBlk
      sz  = @eefs.files[fi].size_typ & 0xfff
      buf=""
      chain_each(bi){ |j,cnt|
        buf+=@blocks[j*16+1,15]
        puts "ERROR multiple use of block #{i}" if @fat[j] 
        @fat[j]=(fi+?a).chr+("%02d "%cnt);
      }
      @fbuf[fi]    = buf[0,sz]
      @fbufdec[fi] = decode(@fbuf[fi])
    }
    #free chain
    @freeBlks=0
    chain_each(@eefs.freeList){|j,cnt| 
      @freeBlks+=1
      puts "ERROR used block is also in free chain #{i}" if @fat[j] 
      @fat[j]=" .  "; 
    }
    @fat.each_with_index{|f,i|
      next if i<4
      puts "ERROR lost block #{i}" if !f 
    }
  end
  def info
    @eefs.each{|n,val,obj|
      printf("%10s %5d 0x%x (%s)\n",n,val,val,obj.class.to_s[9..-1]) if val.is_a? Numeric
    }
    puts
    puts "allocation map freeBlks=#{@freeBlks} freeSz=#{@freeBlks*@bs}"
    @fat.each_with_index{|fx,i|
      print fx ? fx : '////'
      puts if i%16==15
    }
    puts
    puts "name sz typ sz2  blocks"
    puts "-----------------------"
    #     a    24  1   40  127, 126,
    MAXFILES_V4.times{|i|infoFile(i)}
  end

  def decode(inbuf)
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
  def chain_each(i)
    cnt=0
    while i!=0
      yield i,cnt if block_given?
      cnt+=1
      i=@blocks[i*16+0]
    end
  end
  def infoFile(fi)
    bi  = @eefs.files[fi].startBlk
    sz  = @eefs.files[fi].size_typ & 0xfff
    typ = @eefs.files[fi].size_typ   >> 12
    printf("%s  %4d %2d  %3d ",(fi+?a).chr,sz,typ,@fbufdec[fi].length)
    chain_each(bi){|j,cnt|  printf(" %d,",j)}
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
    Dir.mkdir(dir)
    r=read(file)
    r.export(dir)
  end
  def info()
    file = ARGV[0] || 'eeprom.bin'
    r=read(file)
    #puts "eeprom version: #{@vers}"
    r.info
  end
  def read(file)
    File.open(file){|f|
      @vers=f.read(1)[0]
      f.seek(0)
      case @vers
      when 1; r=Reader_V1.new; r.read(f); return r
      when 4; r=Reader_V4.new; r.read(f); return r
      else
        raise "unknown eeprom version #{vers}"
      end
    }
  end
end


Main.new
