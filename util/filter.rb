#! /usr/bin/env ruby
require 'gnuplot'

#  class Array # contains n-tuples [x,y],[x,y],[x,y]
#    def to_gplot
#      collect { |a| a.join(" ") }.join("\n") + "\ne"
#    end
#    def to_gsplot
#      raise
#    end
#  end
=begin
ISR(ADC_vect, ISR_NOBLOCK)
{
  static uint8_t  chan;
  //static uint16_t s_ana[8];
  static uint8_t s_ana[8*4*2];

  ADCSRA  = 0; //reset adconv, 13>25 cycles

  // s_anaFilt[chan] = s_ana[chan] / 16;
  // s_ana[chan]    += ADC - s_anaFilt[chan]; //

  uint16_t v=ADC;

  uint16_t *filt = (uint16_t*)(s_ana+(uint8_t)(chan*4*2));
  for(uint8_t i=3; i>0; i--,filt++){
    uint16_t vn = *filt / 4; //0,16,23,28 vals to 99%
    *filt += v - vn; // *3/4
    v=vn;
  }
  s_anaFilt[chan] = v;



  chan    = (chan + 1) & 0x7;
  ADMUX   =  chan | (1<<REFS0);  // Multiplexer stellen
  STARTADCONV;                  //16MHz/128/25 = 5000 Conv/sec
}
=end

class Main

  def init
    @temp=[0]*100
  end
  def filter141(val,sft) # gleitender mw  sum + val - sum / 2**sft
    out=@temp[0] >> sft
    @temp[0] += val-out
    out
  end
  def filterErez(val,sel=0)
    @temp[3] = (@temp[3] / 2 + @temp[2])
    @temp[2] = (@temp[2] / 2 + @temp[1])
    @temp[1] = (@temp[1] / 2 + @temp[0])
    @temp[0] = (@temp[0] / 2 + val) 
    @temp[sel] >> (sel+1)
  end
  def filterErezInv(val,sel=0)
    @temp[0] = (@temp[0] / 2 + val) 
    @temp[1] = (@temp[1] / 2 + @temp[0])
    @temp[2] = (@temp[2] / 2 + @temp[1])
    @temp[3] = (@temp[3] / 2 + @temp[2])
    @temp[sel] >> (sel+1)
  end
  def filterErez_orig(val,sel=0)
    @temp[3] = (@temp[3]+@temp[2]) / 2
    @temp[2] = (@temp[2]+@temp[1]) / 2
    @temp[1] = (@temp[1]+@temp[0]) / 2
    @temp[0] = (@temp[0]+val)      / 2
    @temp[sel]
  end
  def filterErez_Hyst(val,par,hyst=nil)
    @temp[0] = (@temp[0] / 2 + val) 
    @temp[1] = (@temp[1] / 2 + @temp[0])
    @temp[2] = (@temp[2] / 2 + @temp[1])
    @temp[3] = (@temp[3] / 2 + @temp[2])
    ret=@temp[par] >> (par+1)

    if hyst
      dh=ret-@temp[4]
      if(dh > 1 or dh<0)
        @temp[4] = ret;
      else
        ret = @temp[4];
      end
    end
    ret
  end
  def filterGw_Hyst(val,par,hyst=nil)
    ret = @temp[0] >> (2+par)
    @temp[0] += val - ret
    @temp[1]  = ret

    if hyst
      dh=ret-@temp[2] +@temp[3]
      if(dh > 1 or dh<0)
        @temp[2] = ret;
        @temp[3] = dh>0 ? 1 : 0
      else
        ret = @temp[2];
      end
    end
    ret
  end
  def filter3(val,sft)
    sft/=2
    #val=val.to_f
    sft.times{|i|
      val=@temp[i] = (@temp[i]*3+val+2) / 4
    }
    val
  end
  def filterR143(val,rep)
    rep.times{|i|
      valn=@temp[i] / 4
      @temp[i] +=  val - valn
      val=valn
    }
    val
  end
  def filterR143_x(val,div,rep)
    val = val*2+1
    rep.times{|i|
      @temp[i] =  (val + @temp[i]*(div-1) ) / div
      val=@temp[i]
    }
    val/2
  end
  def filter4(val,sft)
    n=1<<sft
    @temp[n]=val
    @temp.shift
    x=0
    (n).times{|i|
      x+=@temp[i]
    }
    (x+n/2)/n
  end

  def addCurve(name,y0)
    init
    @curves << [name,y0.map{|y| yield y }]
  end
  W=500
  WM=10
  WP=10
  H=100
  HM=5
  HP=5
  def plotSet(yin,d=5)
    @curves=[]
    dy=0
    addCurve("stimulation",yin){|y| y-dy }; dy+=d
     #addCurve("f141-4" ,yin){|y| filter141(y,4)-dy}; dy+=d
     #addCurve("f141-3" ,yin){|y| filter141(y,3)-dy}; dy+=d
     #addCurve("f141-2" ,yin){|y| filter141(y,2)-dy}; dy+=d
     #addCurve("f141-1" ,yin){|y| filter141(y,1)-dy}; dy+=d
#     addCurve("ferez-2",yin){|y| filterErez(y,3)-dy}; dy+=d
#     addCurve("ferez-0-inv",yin){|y| filterErezInv(y,0)-dy}; dy+=d
#     addCurve("ferez-1-inv",yin){|y| filterErezInv(y,1)-dy}; dy+=d
#     addCurve("ferez-2-inv",yin){|y| filterErezInv(y,2)-dy}; dy+=d
#     addCurve("ferez-3-inv",yin){|y| filterErezInv(y,3)-dy}; dy+=d
#     addCurve("ferez-3",yin){|y| filterErez(y,3)-dy}; dy+=d
#     addCurve("ferez-2-orig",yin){|y| filterErez_orig(y,2)-dy}; dy+=d
     addCurve("ferez-3-orig",yin){|y| filterErez_orig(y,3)-dy}; dy+=d
     #addCurve("ferez-2",yin){|y| filterErez(y,2)-dy}; dy+=d
     #addCurve("ferez-3",yin){|y| filterErez(y,3)-dy}; dy+=d
#     addCurve("f143_1",yin){|y| filterR143(y,1)-dy}; dy+=d
#     addCurve("f143_2",yin){|y| filterR143(y,2)-dy}; dy+=d
#     addCurve("f143_3",yin){|y| filterR143(y,3)-dy}; dy+=d
     addCurve("f143x_4_2",yin){|y| filterR143_x(y,4,2)-dy}; dy+=d
#     addCurve("f143x_2_4",yin){|y| filterR143_x(y,2,4)-dy}; dy+=d
     addCurve("fgw0-hyst1",yin){|y| filterGw_Hyst(y,0,1)-dy}; dy+=d
     addCurve("fgw1-hyst1",yin){|y| filterGw_Hyst(y,1,1)-dy}; dy+=d
     #addCurve("fgw1-hyst0",yin){|y| filterGw_Hyst(y,1,nil)-dy}; dy+=d
     addCurve("fgw2-hyst1",yin){|y| filterGw_Hyst(y,2,1)-dy}; dy+=d
     addCurve("fgw3-hyst1",yin){|y| filterGw_Hyst(y,3,1)-dy}; dy+=d
     addCurve("fez3-hyst1",yin){|y| filterErez_Hyst(y,3,1)-dy}; dy+=d
  end

  def initialize
  end
  def plot
    x=(-WM...(W)).to_a
    
    grade = 4
    noise = 10
    @y0=[0]*WM + [H]*W
    @y1=[0]*WM + [40,0]*(W/2)
    @y0=[0]*11 + ([0]*W).map{(rand(0)*noise).to_i+100-noise/2}
    # @y2=[0]*11 + [100] + [0]*(W-1)
    @y2=[0]*11; 
    y=H*80/100
    10.times{|i| @y2 +=  ([y]*(W/20)); y+=1}
    10.times{|i| @y2 +=  ([y]*(W/20)); y-=1}

    @y2=@y2.map{|y|y+(rand(0)*noise).to_i-noise/2}
    
    ##@y2=@y0

    #addCurve("y0",@y0)     {|y| y           }

    #addCurve("f1_#{grade}",@y0){|y| filter1(y,grade)}
    #addCurve("f3_#{grade}",@y0){|y| filter3(y,grade)}
    #addCurve("f4_#{grade}",@y0){|y| filter4(y,grade)}

    #addCurve("f1_#{grade}1",@y1){|y| filter1(y,grade)}
    #addCurve("f3_#{grade}1",@y1){|y| filter3(y,grade)}
    #addCurve("f4_#{grade}1",@y1){|y| filter4(y,grade)}

    #addCurve("f4_#{grade-1}_n#{ noise}",@y2){|y| filter4(y,grade-1)-d*4}
    #addCurve("f4_#{grade}_n#{ noise}",@y2){|y| filter4(y,grade)-d*4}
    
    
    #File.open( "gnuplot.dat", "wb") { |gp|
    Thread.new{
    Gnuplot.open() { |gp|
      Gnuplot::Plot.new( gp ) { |plot|
        
        plot.xrange "[-#{WM}:#{W+WP}]"
        plot.yrange "[-#{HM}:#{H+HP}]"
        plotSet(@y2,0)     
        plot.data = @curves.map{|name,ya|
          Gnuplot::DataSet.new( [x,ya] ) { |ds|
            ds.with = "lines"
            ds.title = "#{name}"
            #ds.linewidth = 1
          }
        }
      }
      #gp.puts
      #gp.puts "pause 100"
      sleep 100
    }
    }
    #Thread.new{
    Gnuplot.open { |gp|
      #File.open( "gnuplot.dat", "wb") { |gp|
      Gnuplot::Plot.new( gp ) { |plot|
        
        plot.xrange "[-#{WM}:#{W+WP}]"
        plot.yrange "[-#{HM}:#{H+HP}]"
        
        plotSet(@y2)     
#p @curves
        #plot.data = @curves.map{|name,ya|
        @curves.each{|name,ya|
          #p name,x.zip(ya)
          #plot.data << Gnuplot::DataSet.new( x.zip(ya) ) { |ds|
          plot.data << Gnuplot::DataSet.new( [x,ya] ) { |ds|
            ds.with = "lines"
            ds.title = "#{name}"
            #ds.linewidth = 1
          }
        }
      }
      gp.puts
      #gp.puts "pause 100"
      #sleep 100
    }
    #}
  end
  def loop
    system('stty raw -echo') # => Raw mode, no echo
    at_exit{
      system('stty -raw echo') # => Reset terminal mode
    }
    @temp=[0]*4
    y=10
    1000.times {
      #char = (STDIN.read_nonblock(1).ord rescue nil)
      char = STDIN.read(1)
      case char
        when "q","\003"; exit
        when /\d/; y=100*(char.ord-"0".ord)
        when "+"; y+=1
        when "-"; y-=1
      end
      #ret=filterR143(y,3) 
      ret=filterErez(y,2)
      #ret=filterErez_orig(y,3)
      p [y]+@temp+[ret]
      print "\r"
    }
  end
end

#Main.new.loop
Main.new.plot


  
