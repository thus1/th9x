#! /usr/bin/env ruby
require 'gnuplot-thus'

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
  def filter141(val,sft)
    out=@temp[0] >> sft
    @temp[0] += val-out
    out
  end
  def filterErez(val)
    out= @temp[0] = (@temp[0]+@temp[1]) / 2
    @temp[1] = (@temp[1]+@temp[2]) / 2
    @temp[2] = (@temp[2]+@temp[3]) / 2
    @temp[3] = (@temp[3]+val) / 2
    out
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
      valn=@temp[i]/4
      @temp[i] +=  val - valn
      val=valn
    }
    val
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
  W=100
  WM=10
  WP=10
  H=100
  HM=5
  HP=5
  def plotSet(yin)
    d=0#10
    @curves=[]
    addCurve("stimulation",yin){|y| y }
    addCurve("f141" ,yin){|y| filter141(y,4)-d*1}
    addCurve("ferez",yin){|y| filterErez(y)-d*2}
    addCurve("f143_1",yin){|y| filterR143(y,1)-d*3}
    addCurve("f143_2",yin){|y| filterR143(y,2)-d*3}
    addCurve("f143_3",yin){|y| filterR143(y,3)-d*3}
    addCurve("f143_4",yin){|y| filterR143(y,4)-d*3}
  end

  def initialize
    x=(-WM...(W)).to_a
    
    grade = 4
    noise = 1#0
    @y0=[0]*WM + [H]*W
    @y1=[0]*WM + [40,0]*(W/2)
    #@y2=[0]*11 + ([0]*W).map{rand(noise)+100-noise/2}
    @y2=[0]*11 + [100] + [0]*(W-1)
    @y2=[0]*11; 
    y=0
10.times{|i| @y2 +=  ([y]*5); y+=1}
10.times{|i| @y2 +=  ([y]*5); y-=1}
    #@y2=@y0

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
        plotSet(@y0)     
        plot.data = @curves.map{|name,ya|
          Gnuplot::DataSet.new( [x,ya] ) { |ds|
            ds.with = "lines"
            ds.title = "#{name}"
            ds.linewidth = 2
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
      Gnuplot::Plot.new( gp ) { |plot|
        
        plot.xrange "[-#{WM}:#{W+WP}]"
        plot.yrange "[-#{HM}:#{H+HP}]"
        
        plotSet(@y2)     
        plot.data = @curves.map{|name,ya|
          Gnuplot::DataSet.new( [x,ya] ) { |ds|
            ds.with = "lines"
            ds.title = "#{name}"
            ds.linewidth = 2
          }
        }
      }
      #gp.puts
      #gp.puts "pause 100"
      sleep 100
    }
    #}
  end
end

Main.new
  
