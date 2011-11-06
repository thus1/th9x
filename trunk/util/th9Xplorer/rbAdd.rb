#!/usr/bin/env ruby

IS_WINDOWS = (RUBY_PLATFORM   =~ /cygwin|mingw|mswin32/)
THUS       =  ENV["LOGNAME"]=~/^(husteret|thus)$/

Thread.abort_on_exception= true
$opt_v=0 if !$opt_v
$cntWarn
$cntErr
$errors=[]
$warnings=[]
def warn(msg,*args)
  m=sprintf("WARNING "+msg,*args)
  puts m
  $warnings<<m
end
def err(msg,*args)
  m=sprintf("ERROR "+msg,*args)
  puts m
  $errors<<m
end
def statusLine(msg)
  if $statusLine
    $statusLine.normalText=msg
    $statusLine.text=msg
  else
    puts msg
  end
end
alias glob_warn warn
alias glob_err  err


#require 'ftools' #makedirs
require 'fileutils' #mkdir_p
def initTmpDir(path,*subdirs)
  tmpa=path.compact.uniq
  #pp tmpa
  dir=nil
  tmpa.each{|tmp|  
    tmp
    next if ! File.directory?(tmp)
    begin
      #File.makedirs(tmp)
      #FileUtils.mkdir_p(tmp)
      dir  = File.join(tmp,*subdirs).gsub(/\\/,"/")
      #puts "try #{dir}"
      FileUtils.mkdir_p(dir)
    rescue
    end
    break if File.directory?(dir)   
    dir=nil
  }
  dir or raise "cannot find tmp-dir"
  #File.makedirs(dir,true)
  dir
end
def initTmpDirs
  File.umask(2)
#  $TMP_CACHEDIR=initTmpDir([ ENV['SVNTREE_CACHE'], 
#                             (IS_WINDOWS ? nil:"/var"),
#                             ENV['ALLUSERSPROFILE'], #only WINDOWS
#                             ENV['TMP'], 
#                             ENV['TEMP'],
#                             ENV['TMPDIR'], 
#                             (IS_WINDOWS ? "c:\\temp":"/tmp")
#                           ],"svntree","cache")
  $TMP_FILEDIR=initTmpDir([  ENV['TMP'], 
                             ENV['TEMP'],
                             ENV['TMPDIR'], 
                             (IS_WINDOWS ? "c:\\temp":"/tmp")
                           ],"th9xExplorer","tmpfiles")
#  puts "TMP_CACHEDIR = #{$TMP_CACHEDIR}"
  puts "TMP_FILEDIR  = #{$TMP_FILEDIR}"
  now=Time.now
#  Dir[$TMP_CACHEDIR+"/*"].each{|p| 
#    FileUtils.rm_f(p) if (now-File.mtime(p)) > 3600*24*100 
#  }
  Dir[$TMP_FILEDIR+"/*" ].each{|p| 
    FileUtils.rm_f(p,{:verbose=>true}) if (now-File.mtime(p)) > 10*60 #10min    
  }


end


def tmpFile(pref="tmp")
  $TMP_FILEDIR or raise
  File.join $TMP_FILEDIR,pref+Time.new.to_s.tr(" :.","")
end
def tmpRevFile(bn,rev)
  $TMP_FILEDIR or raise
  File.join $TMP_FILEDIR,bn.sub(/(\..*|$)/,"-#{rev}\\1")
end


$origStderr = $stderr.dup
$origStdout = $stdout.dup


def sysCommon(cmd,fout,ferr,block)
  #puts "def sysCommon(cmd,fout,ferr,block)"
  vcmd      = cmd.join(" ")
  puts   (fout ? "'>'" : ">") + vcmd if $opt_v>=1
  $log.appendText("\n> " +vcmd+"\n")

  $stdout.reopen(fout) if fout
  $stderr.reopen(ferr)
  begin
    ret=system *cmd; $stderr.flush; $stdout.flush;
  rescue
    raise "error in system command '#{cmd.inspect}' $!=#{$!}"
  end
  $stderr.reopen($origStderr)
  $stdout.reopen($origStdout) if fout

  $log.addColTxt(IO.read(fout),"green") if fout
  $log.addColTxt(IO.read(ferr),"red"  ) if ferr
  #puts "cmd finished: ",vcmd
  #if $?.nil? # unter windows wenn 'command not found'
  #  raise "command not found '#{vcmd}'"
  #end
  #pp ret, $?

  return nil if ret and $?.exitstatus == 0
  err =ferr ? IO.read(ferr) : ""
  err+="\n" if err.length > 0
  err+="system command failed: '#{vcmd}'\n"
  err+="exitstatus:"+(ret ? $?.exitstatus.to_s : "no" )+"\n"

  
  puts   err if $opt_v>=1
  if block
    return (block.call(vcmd,err) or err) #
  else
    raise err
  end
end
def sys(*cmd,&block)
  #puts "sys #{*cmd}"
  sysCommon(cmd,tmpFile("sys_out"),tmpFile("sys_err"),block)
end
def sysbt(*cmd,&block)
  tfout = tmpFile("sys_out")
  sysCommon(cmd,tfout = tmpFile("sys_out"),tmpFile("sys_err"),block)
  IO.read(tfout)
end
def edit(file,line=1)
  puts "def edit(file,line=1)"
  if IS_WINDOWS
    Thread.new { 
      #sys "SET"
      sys "c:\\Program Files\\TextPad 4\\TextPad.exe",file+"(#{line})"
    }
  else
    sys "e",file+":#{line}"
  end
end

def txtWrap(firstIndent,indent,len,txt)
  txt=txt.dup
  idt=firstIndent
  out=""
  while txt.length>0
    out+=idt
    lmax=len-idt.length
    lmax > 0 or raise "len '#{len}' smaller than indent"
    lmin=[lmax/2,1].max #at least 1 char
    if nil
    elsif txt.sub!(/\A(.{0,#{lmax}})(\n|\z)/,"")      #\n has highest priority
    elsif txt.sub!(/\A(.{#{lmin},#{lmax}}[.,]\s)\s*/,"")#search punctuation
    elsif txt.sub!(/\A(.{#{lmin},#{lmax}})\s+/,"")#search space after min len
    elsif txt.sub!(/\A(.{1,#{lmax}})/,"")        #break without space
    else
      raise "unexpected case #{lmax},#{lmin}>#{txt}<"
    end
    out+=$1+"\n"
    idt=indent
  end
  return out
end

class Regexp
  def Regexp.fromGlob(globExp)
=begin simple version
    #http://www.unix.org.ua/orelly/perl/cookbook/ch06_10.htm :
    patmap = {
        '*' => '.*',
        '?' => '.',
        '[' => '[',
        ']' => ']',
    }
    globExp=globExp.gsub( /(.)/ ) {|m| patmap[m] || Regexp.quote(m) }
    return '^' + globExp + '$'
=end 
    res=""
    brck=""
    state=:BASE
    globExp.each_byte{|b| c=b.chr
      case state
      when :BASE
        case c
        when '\\'             ;  state=:QUOTE
        when '?'              ;  res+="."
        when '*'              ;  res+=".*"
        when '['              ;  state=:BRCK;     brck=""
        else                  ;  res+=Regexp.quote(c)
        end
      when :QUOTE
        case c
        when '\\','?','*','[' ;  res+=Regexp.quote(c)
        else                  ;  res+='\\'+Regexp.quote(c)
        end
        state=:BASE
      when :BRCK
        case c
        when '!'              ; brck += brck=="" ? '^' : c
        when ']'
          if brck=="" or brck=="^"
            brck+=c
          else
            res+='['+brck+']'
            brck=""
            state=:BASE
          end
        else
          brck+=c
        end
      end
    }
    state==:BASE or raise "bad end state #{state}"
    /^#{res}$/
  end
end

class String
  def headOforEq?(largerString)
    length<=largerString.length and self==largerString[0,length]
  end
  def headOf?(largerString)
    length<largerString.length and self==largerString[0,length]
  end
  def cutHead(head)
    self[0,head.length] == head or raise "'#{head}' not head of '#{to_s}'"
    self[head.length..-1]
  end
end


class SortedArray < Array
  def initialize(*args,&block)
    super
    @eltFactory=block
  end
  def findEntry(key) #must be a reference
    newElt=@eltFactory.call(key)
    lower = -1
    upper = self.length 
    while lower + 1 != upper
      mid = ((lower + upper) / 2)
      if yield(newElt,self[mid]) > 0
        lower = mid
      else 
        upper = mid
      end
    end
    entry = self[upper]
    if entry
      if yield(newElt,entry) != 0
        self[upper,0]=[newElt]
        entry=newElt
      end
    else
      self[upper,0]=[newElt]
      entry=newElt
    end
    entry
  end
end

class Exception
  # usage:
  #   begin
  #   rescue
  #     $!.add("MSG add aa")
  #   end
  def add(msg)
    c=Kernel.caller
    b=backtrace()
    b[(b.length-(c.length-1)),0]=[msg,c[0]]
    raise #re-raise this exception
  end
  def show
    print asStr()
  end
  def asStr
    "\n"+message+"\n"+
    (backtrace() or []).map{|e| (e=~/^[^:]+:\d+/ ? "  " : "") + e + "\n" }.join
  end
  def hierStr()
    anc=self.class.ancestors
    anc=anc.find_all{|c|c.class==Class}
    if i=anc.index(Exception)
      anc=anc[0,i+1]
    end
    anc.map{|c|c.to_s}.join(" < ")
  end
end

class Timer
  @@timers=[]
  def initialize(what)
    @what=what
    @t0=Time.now
    @tpart=@t0
    @@timers<<self
    @parts=[]
    if block_given?
      yield self
      stop
    end
  end
  def Timer.block(what)
    t=Timer.new(what)
    ret=yield t
    t.stop
    ret
  end
  def part(up)
    t=Time.now
    @parts<<[t-@tpart,up]
    @tpart=t
  end
  def stop
    @dt=Time.now-@t0
  end
  def show
    if @dt #maybe not stoppen when exception occurs
      printf("%-15s: %fs\n",@what,@dt) 
      if @parts.length>0
        min=max=@parts[0][0]
        @parts.each{|t,up|
          min=[t,min].min
          max=[t,max].max
        }
        histo=Array.new(10,0)
        histos=Array.new(10,0)
        histou=Array.new(10,nil)
        sum=0
        @parts.each{|t,up|
          i=0;
          while i<9 and t < max / (1<<i)
            i+=1
          end
          histo[i]+=1
          histos[i]+=t
          histou[i]||=[]
          histou[i] << up
          sum+=t
        }
        printf("  max=%f min=%f\n",max,min)
        histo.each_with_index{|n,i|
          prc=histos[i]*100/sum
          printf("  >= %f  %5i (%f)\n",max/(1<<i),n,prc)
          if prc>10
            histou[i].each{|up|
              print up,", "
            }
            puts
          end
          
        }
        
      end
    end
  end
  def Timer.show
    @@timers.each{|t| t.show }
    @@timers=[]
  end
end

class Dir
  def Dir.indir(dir,&block)
    cwd = Dir.getwd()
    begin
      Dir.chdir(dir)
      result = block.call() if block_given?
    ensure
      Dir.chdir(cwd)
    end
    return result
  end
end

class Logger
  @@instance=nil
  def initialize
    @@instance=self
    at_exit{
      #$ttimes.each{|k,dts|
      #  tsum=0
      #  dts.each{|dt|tsum+=dt}
      #  printf("%f %5d %20s\n",tsum,dts.length,k)
      #}
    }
  end
  def Logger.wrap(bndg,method)
    #logger = (@@instance||=Logger.new)
    morig="orig_"+method
    print "Wrapping #{method} to #{morig}\n"
    eval <<"EOT",bndg
    alias #{morig} #{method}
    def #{method}(*args,&bl)
      t=Time.now
      ret=#{morig}(*args,&bl)
      dt=Time.now-t
      ars=args.map{|a|a.to_s}.join(", ")
      printf("  %f #{method}(\#{ars})=\#{ret.inspect}\n",dt)
      ret
    end
EOT
    #$ttimes["#{m}"]<<dt

  end
end



class Object
  def ext
    methods.each{|m|
      if m=~/(\w+)=$/ and  respond_to?(v=$1)
        begin
          eval "@#{v}=#{v}" 
        rescue
        end
      end
    }
    self
  end
end

def findInPath(relf,pathArr)
  pathArr.each{|p| p+="/"+relf
    return p if File.exists?(p)
  }
  nil
end
$ReloadInfo={} 
$Reloadtime=Time.new
$globalBinding=binding
def checkReload
  $".each{ |f| #"
    if ri=$ReloadInfo[f]
      if File.mtime(ri[0]) > $Reloadtime
        puts "reloading #{f}"  
        #Kernel::load f
        eval "load '#{f}'", $globalBinding
      end
    else
      if p=findInPath(f,$:)
        # puts "found #{p}"
      else
        puts "ERROR not found #{f} in #{$:}"
      end
      $ReloadInfo[f]=[p,File.mtime(p)]
    end
  }
  $Reloadtime=Time.new
end


if $0 == __FILE__
  $global_ignores = %w(*.o *.lo *.la #*# .*.rej *.rej .*~ *~ .#* .DS_Store)

  require 'irb'
  module IRB
    IRB.setup(nil)
    irb = Irb.new(WorkSpace.new($ctx))
    @CONF[:MAIN_CONTEXT] = irb.context
    trap("SIGINT") do
      irb.signal_handle
    end
    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end

end
