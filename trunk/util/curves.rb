#! /usr/bin/env ruby

require "gnuplot"
require "pp"
Gnuplot.open do |gp|
#File.open( "gnuplot.dat", "w") do |gp|
  Gnuplot::Plot.new( gp ) do |plot|
  
    #plot.title  "Array Plot Example"
    #plot.ylabel "x"
    #plot.xlabel "x^2"

    yi=[]
    ti=[]
    
    plot.xrange "[0:31]"
    plot.yrange "[0:300]"
    plot.title  "trim curve"
    plot.ylabel "y"
    plot.xlabel "x"
    
    
    x = (0..31).map { |v| v }
    #yi[0] = x.map { |v| v *(v+1)/ 2 }
    #ti[0] = "x^2"
   # y=0
   # d=1
   # y2= []
   # 32.times {|i|  y2[i]=y; y+=d; d+=1 if i&1!=0}

   [0,4,6,8,10].each{|k|
      yi << x.map { |v| (v *(v+3)/ 4)*k/10 + (v*263/31)*(10-k)/10 }
      ti << "k#{k}"
   }
#    yi[2] = x.map { |v| v *(v+3)/ 4 }
p *yi

      plot.data = yi.map{|y|
        Gnuplot::DataSet.new( [x, y] ) { |ds|
 	ds.with = "linespoints"
 	ds.title = ti.shift
       }
                         }
	  #[
    
#       Gnuplot::DataSet.new( [x, y1] ) { |ds|
# 	ds.with = "linespoints"
# 	ds.title = "y1"
#       },
#       Gnuplot::DataSet.new( [x, y2] ) { |ds|
# 	ds.with = "linespoints"
# 	ds.title = "y2"
#       },
#       Gnuplot::DataSet.new( [x, y3] ) { |ds|
# 	ds.with = "linespoints"
# 	ds.title = "y3"
#       }
#    ]


  
  end
end
