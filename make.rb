#! /usr/bin/env ruby
require "pp"





PARDEF={}
#PARDEF[:PROG]     = "USBPROG"
PARDEF[:PROG]     = "AVRDUDE"
PARDEF[:TC]       = "TC_PAR1"


#TGT=%w(drehzahl.cpp  MCU=attiny26 CFLAGS=)
#TGT=%w(servo.c  MCU=attiny22     CFLAGS=-xc++)
TGT=%w( DIR=src th9x.cpp sticks_4x1.xbm font_6x1.xbm menus.cpp foldedlist.cpp pulses.cpp pers.cpp file.cpp  lcd.cpp drivers.cpp  MCU=atmega64)




TC_PAR1=%w(
  AVR_PATH=/opt/cross
  USBPROG=usbprog.rb
  AVRDUDE=avrdude
  OBJCOPY=avr-objcopy
  CC=avr-gcc
)

def readAvrdudeConf
  buf=File.read("/etc/avrdude.conf")
  #  buf.gsub!(/#.*?\n/,"") #remove cmt
  mp={}
  buf.split(/\npart/).each{|m| 
    m=~/id\s*=\s*\"(.+?)\"/m; id=$1
    m=~/desc\s*=\s*\"(.+?)\"/m; desc=$1
    m=~/flash.*?\bsize\s*=\s*(\d+);/m; flash_size=$1
    m=~/eeprom.*?\bsize\s*=\s*(\d+);/m; eeprom_size=$1
    mp[desc.downcase.to_sym] = {:id,id,:flashsize,flash_size, :eepromsize,eeprom_size}
  }
  #pp mp
  mp
end
#MCU_PAR={
 # :atmega64 => {:flashsize,0x10000, :eepromsize,0x800},
#}
MCU_PAR=readAvrdudeConf


class Builder
  def bin()

    felf  = "#{@projectName}.elf"
    fbin  = "#{@projectName}.bin"
    mkrb  = File.expand_path(__FILE__)

    @pars[:SOURCES].each{|src|
      case src
      when /(.*)(_\d+x\d+\.xbm)$/
        bse   = $1
        fobj  = bse+".lbm"
        checkDep(fobj,src) {
          sys "xbm2lbm.rb #{src}","util/xbm2lbm.rb #{src}"
        }
      end
    }
    Dir.indir("OBJS"){
      puts "make: Entering directory `#{Dir.pwd}'"
      srces=[]
      objs =[]
      #srces#.map{|s|"../"+s}
      @pars[:SOURCES].each{|src|
        case src
        when /(.*)(\.c|\.cpp)$/
          bse   = $1
          bse.gsub!(/\//,"_") # src.sub(/\.(c|cpp)$/,"")
          fdep  = bse+".d"
          fobj  = bse+".o"
          osrc   = "../"+src
          srces << osrc
          objs  << fobj
          #srcesStr=srces.join(" ")
          deps = [osrc,mkrb]
          if File.exists?(fdep)
            deps += (File.read(fdep).split(/\s+\\?\s*/)[1..-1] || [])
            deps.uniq!
          end
          pp "osrc=",osrc,"deps=",deps if $opt_v>=3
          checkDep(fobj,deps) {
            cmd  = @pars[:CC] 
            cmd += " "+ @pars[:INCLUDE]
            cmd += " "+ @pars[:CFLAGS] 
            cmd += " -o #{fobj}"
            cmd += " -Wno-variadic-macros"
            cmd += " -pedantic-errors"
            cmd += " -MD -c"
            cmd += " -mmcu=#{@pars[:MCU]}"
            cmd += " "+ osrc
            sys "#{@pars[:CC]} #{src}",cmd
          }
        end
      }
      checkDep(felf,objs+[mkrb]) {
        mkStamp("../src/stamp-#{@projectName}.h")
        cmd  = @pars[:CC] 
        cmd += " ../src/stamp.cpp"
        cmd += " -o #{felf}"
        cmd += " -Wno-variadic-macros"
        cmd += " -Wl,-Map=#{@projectName}.map,--cref,-v"
        cmd += " -mmcu=#{@pars[:MCU]}"
        cmd += " "+ @pars[:CFLAGS] 
        cmd += " "+ @pars[:LDFLAGS]
        cmd += " "+ objs.join(" ")
        #$(CC)     $(INCDIR) $(CFLAGS) $(LIB) $(LDFLAGS) -mmcu=$(MCU) -o #{obj} 
        sys "#{@pars[:CC]} "+objs.join(" "),cmd
      }
      checkDep(fbin,felf) {
        cmd  = @pars[:OBJCOPY] 
        cmd += " -O binary #{felf} #{fbin}"
        #      $(BIN) -O binary $< $(@:.rom=.bin)
        sys "#{@pars[:OBJCOPY]} #{fbin}",cmd
        sys "cp #{fbin} #{felf}","cp  #{fbin} #{felf} .."
      }
    }
    return [fbin,felf]
  end 
  def load
    #setup()

    File.open(".#{@projectName}.loadcnt","a"){|f|
      f.puts(Time.new.strftime("%y%m%d_%H%M%S flash"))
    }

    fbin,felf = bin()
    Dir.indir("OBJS"){
      case @pars[:PROG] 
      when "USBPROG"
        sys "usbprog eraseChip",@pars[:USBPROG] +" eraseChip"
        sleep 1
        sys "usbprog wrFlash",@pars[:USBPROG] +" wrFlash #{fbin}"
      when "AVRDUDE"
        typ = MCU_PAR[@pars[:MCU].to_sym][:id]
        #{"attiny22" => "2343",
        #       "attiny45" => "t45",
        #       "attiny13" => "t13",
        #}[@pars[:MCU]]
        sys "avrdude wrFlash",@pars[:AVRDUDE] +" -q -cusbtiny -p #{typ} -U flash:w:#{fbin}:r"
      when "USBTINY"
	typ = @pars[:MCU]
	typ=="attiny10" or raise "unknown typ"
        sys "usbtiny.rb eraseFlash",@pars[:USBTINY] +" eraseFlash"
        sys "usbtiny.rb wrFlash",@pars[:USBTINY] +" wrFlash #{fbin}"
      else
        raise "bad progrmmer"
      end
    }
  end
  alias l load
  def backup_gen(size,uspact,avdact)
    mpars=MCU_PAR[@pars[:MCU].to_sym]
    fn=@dt+avdact
    Dir.indir("BACKUP"){
      case @pars[:PROG] 
      when "USBPROG"
        sys "usbprog #{uspact}", @pars[:USBPROG] +" #{uspact} 0 #{size} #{fn}"
      when "AVRDUDE"
        typ = mpars[:id]
        sys "avrdude #{uspact}",@pars[:AVRDUDE] +" -q -cusbtiny -p #{typ} -U #{avdact}:r:#{fn}:r"
      else
        raise "bad progrmmer"
      end
    }
  end
  def backup_flash()
    backup_gen(MCU_PAR[@pars[:MCU].to_sym][:flashsize],"rdFlash","flash")
  end
  def backup_eeprom()
    backup_gen(MCU_PAR[@pars[:MCU].to_sym][:eepromsize],"rdEeprom","eeprom")
    #pars=MCU_PAR[@pars[:MCU].to_sym]
    #Dir.indir("BACKUP"){
    #  sys "usbprog rdEeprom",@pars[:USBPROG] +" rdEeprom 0 #{pars[:eepromsize]} #{@dt}eeprom"
    #}
  end
  def backup()
    backup_flash()
    backup_eeprom()
  end
  alias be backup_eeprom
  alias bf backup_flash
  alias b  backup
  def dump
    fbin,felf = bin()
    Dir.indir("OBJS"){
      sys "","avr-size         #{felf}"
      sys "","avr-nm      -C  --print-size #{felf}"
      sys "","avr-objdump -C -h -s -dlS #{felf}"
#      sys "","avr-objdump -C -d   #{felf}"
    }
  end

  def setup()
    return if @pars
    #ueberschreibbare default parameter
    @pars=PARDEF
    @pars[:SOURCES]  = ""
    # @pars[:TC]       = "TC_PAR1"
    # @pars[:PROG]     = "USBPROG" # alt: AVRDUDE
    #zuerst alle user specs eintragen, einschl TC
    TGT.each{|expr|
      case expr
      when /(.+?)+=(.*)/
        sym=$1.to_sym
        @pars[sym]+=$2
      when /(.+?)=(.*)/
        sym=$1.to_sym
        @pars[sym]=$2
      else
        @pars[:SOURCES] += " "+expr
      end
    }
    #dann alle specs der toolchainparameter falls nicht ueberschrieben
    eval(@pars[:TC]).each{|expr|
      case expr
      when /(.+?)=(.+)/
        sym=$1.to_sym
        @pars[sym]=$2 unless @pars[sym] #nicht ueberschreiben
      else
        raise "bad TGT opt #{expr}"
      end
    }
    #abgeleitete parameter
    @pars[:CFLAGS] ||= ""
    @pars[:LDFLAGS]||= ""
    @pars[:CFLAGS]  += " -g2 -gdwarf-2 -Os -Wall -pedantic --save-temps"
    @pars[:INCLUDE]||= ""
    @pars[:INCLUDE] +=  "-I. -I#{@pars[:AVR_PATH]}/avr/include"
    @pars[:SOURCES]  =  @pars[:SOURCES].strip.split(/ +/)
    @projectName = @pars[:SOURCES].first.sub(/\.(c|cpp)$/,"")
    if @pars[:DIR] != "."
      @pars[:SOURCES]  =  @pars[:SOURCES].map{|src| @pars[:DIR]+"/"+src}
    end

    ENV["PATH"]= @pars[:AVR_PATH]+"/bin:"+ENV["PATH"]
    pp @pars       if $opt_v>=3
    pp ENV["PATH"] if $opt_v>=3

  end
  def sys(cmt,cmd)
    puts "--- #{cmt}"
    pp cmd      if     $opt_v>=2
    return      if     $opt_n
    ret = system cmd  
    raise "command not found '#{cmd}' '#{$?.inspect}'" if !ret and $?.exitstatus==127
    raise "exitstatus not 0 cmd:'#{cmd}' exitstatus=#{$?.exitstatus}" if $?.exitstatus != 0
  end

  def checkDep(dest,*srces)
    srces.flatten!
    mtimeDest = File.exists?(dest) ? File.mtime(dest) : nil
    srces.each{|src|
      p src if $opt_v>=3
      if !mtimeDest or (mt=File.mtime(src)) > mtimeDest
        puts "#{src} (#{mt}) newer #{dest} (#{mtimeDest})" if $opt_v>=2
        yield
        break
      else
        puts "#{src} (#{mt}) not newer #{dest} (#{mtimeDest})" if $opt_v>=3
      end
    }
  end


  require 'optparse'
  def initialize
    opts=ARGV.options
    prg=File.basename($0)
    opts.banner = "\nUsage: #{prg} [options] \n"
    opts.summary_width=20
    opts.on("","Options:")
    opts.on("-h","--help", "show this message") {puts opts; exit}
    $opt_v  = 1
    opts.on("-q",          "be quiet")   {    $opt_v  = 0  }
    opts.on("-v[lev]",     "increase (set) verbose level") { |v| 
      $opt_v += 1
      $opt_v  = v.to_i   if v =~ /^\d+$/
      $opt_v += v.length if v =~ /^v+$/
    }
    $opt_n  = nil
    opts.on("-n",          "do nothing")   { |$opt_n|  }
    opts.parse!
    @dt=Time.new.strftime("%y%m%d_%H%M%S")
    setup()
    send ARGV[0] || "bin"
  end
  def mkStamp(stf)
    vers=0
    svnvers=""
    begin
      File.read(stf)=~/VERS\s+(\d+)/
      vers=$1.to_i + 1
#<url>https://th9x.googlecode.com/svn/trunk</url>
      info=`svn info --xml ..`
      if info=~/\.com\/svn\/(.*)<\/url>/
        svnvers += $1
      end
#   revision="77">
      if info=~/revision="(\d+)"/
        svnvers += "-r"+($1.to_i+1).to_s
      end
    rescue
    end

    File.open(stf,"w"){|f|
      t=Time.new
      f.puts t.strftime("#define DATE_STR \"%d.%m.%Y\"")
      f.puts t.strftime("#define TIME_STR \"%H:%M:%S\"")
      f.puts "#define SUB_VERS #{vers}-#{ENV['USER'].sub(/husteret/,"thus")}"
      f.puts "#define SVN_VERS \"#{svnvers}\""
    }
  end
end #Builder

class Dir
  def Dir.indir(dir)
    dold=Dir.pwd
    Dir.mkdir(dir) if ! File.directory?(dir)
    Dir.chdir(dir)
    yield
    Dir.chdir(dold)
  end
end

Builder.new
