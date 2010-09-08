#! /usr/bin/env ruby
require 'gnuplot'

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
  def filter1(val,sft)
    out=@temp[0] >> sft
    @temp[0] += val-out
    out
  end
  def filter2(val,sft)
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
  def filter34(val,sft2)
    sft2.times{|i|
      valn=@temp[i]/4
      @temp[i] +=  val - valn
      val=valn
    }
    # valn=@temp[1]/4
    # @temp[1] +=  val - valn
    # val=valn
    # valn=@temp[2]/4
    # @temp[2] +=  val - valn
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
  HM=10
  HP=30
  def initialize
    x=(-WM...(W)).to_a
    @curves=[]#  [1,x] ]
    
    grade = 4
    noise = 1#0
    @y0=[0]*WM + [H]*W
    @y1=[0]*WM + [40,0]*(W/2)
    @y2=[0]*11 + ([0]*W).map{rand(noise)+100-noise/2}
    #@y2=@y0

    #addCurve("y0",@y0)     {|y| y           }

    #addCurve("f1_#{grade}",@y0){|y| filter1(y,grade)}
    #addCurve("f3_#{grade}",@y0){|y| filter3(y,grade)}
    #addCurve("f4_#{grade}",@y0){|y| filter4(y,grade)}

    #addCurve("f1_#{grade}1",@y1){|y| filter1(y,grade)}
    #addCurve("f3_#{grade}1",@y1){|y| filter3(y,grade)}
    #addCurve("f4_#{grade}1",@y1){|y| filter4(y,grade)}

    d=0#10
    addCurve("n#{noise}",@y2){|y| y +10 }
    addCurve("f1_#{grade}_n#{ noise}",@y2){|y| filter1(y,grade)-d*1}
    addCurve("f2_#{grade}_n#{ noise}",@y2){|y| filter2(y,grade)-d*2}
    addCurve("f341_#{grade}_n#{noise}",@y2){|y| filter34(y,1)-d*3}
    addCurve("f342_#{grade}_n#{noise}",@y2){|y| filter34(y,2)-d*3}
    addCurve("f343_#{grade}_n#{noise}",@y2){|y| filter34(y,3)-d*3}
    addCurve("f4_#{grade-1}_n#{ noise}",@y2){|y| filter4(y,grade-1)-d*4}
    addCurve("f4_#{grade}_n#{ noise}",@y2){|y| filter4(y,grade)-d*4}
    
    
    # File.open( "gnuplot.dat", "w") do |gp|
    Gnuplot.open { |gp|
    #File.open( "gnuplot.dat", "w") { |gp|
      Gnuplot::Plot.new( gp ) { |plot|
        
        plot.xrange "[-#{WM}:#{W+WP}]"
        plot.yrange "[-#{HM}:#{H+HP}]"
        
        plot.data = @curves.map{|name,ya|
          Gnuplot::DataSet.new( [x,ya] ) { |ds|
            ds.with = "lines"
            ds.title = "#{name}"
            ds.linewidth = 1
          }
        }
      }
      #gp.puts
      #gp.puts "pause 100"
    }
  end
end

Main.new
  
