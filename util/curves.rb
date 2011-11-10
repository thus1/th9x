#! /usr/bin/env ruby

require "gnuplot"
require "pp"


def plotTrim
  Gnuplot.open do |gp|
    #File.open( "gnuplot.dat", "wb") do |gp|
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
    end
  end
end

def exp3(x,k)
  k*x*x*x + (1-k)*x
end

EPS=1e-5
def binsrch(y,xl,xr)
  while (xr-xl)>EPS
    xm=(xl+xr)/2
    #ym=exp3(xm,k)
    ym=yield xm
    #p [xl,xm,xr,ym,y]
    if ym>y
      xr=xm
    else
      xl=xm
    end
  end
  xl
end

def exp3U(y,k)
  binsrch(y,0.0,1.0){|x|exp3(x,k)}
end

#p exp3U(0.5,0)
#exit
def plotExp
  Gnuplot.open do |gp|
    #File.open( "gnuplot.dat", "wb") do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      
      yi=[]
      ti=[]
      
      plot.xrange "[0:1]"
      plot.yrange "[0:1]"
      plot.title  "exp"
      plot.ylabel "y,10dx/dy"
      plot.xlabel "x,k"
      
    
      xa = (0..100).map { |v| v.to_f/100 }
      
      0.step(1,0.20){|k|
	yi << xa.map { |x| exp3(x,k)  }
	ti << "k#{k}"
      }
     
      #[0.01,0.03,0.05,0.1].each{|dy|
      [0.01,0.03,0.1,0.3,0.5,0.8,1].each{|dy|
	#10dx/dy
	yi << xa.map { |k| exp3U(dy,k)/dy/10  }
	ti << "dy#{dy}"

	dxy0=exp3U(dy,0)/dy
	dxy1=exp3U(dy,1)/dy
	printf("%5.2f %5.1f %5.1f -----\n",dy,dxy0,dxy1)
	qdxy=(dxy1/dxy0)**(1.0/15)
	dxy=1
	kil=0
	16.times{|i|
	  ki=binsrch(dxy,0.0,1.0){|ki| exp3U(dy,ki)/dy}
	  printf("%5.1f %5.1f %5.2f %5.2f\n",dxy,exp3U(dy,ki)/dy,ki,(ki-kil)*100)
	  kil=ki
	  dxy*=qdxy
	}

      }

      #exit
      #p yi[-1]
      plot.data = yi.map{|y|
        Gnuplot::DataSet.new( [xa, y] ) { |ds|
	  ds.with = "linespoints"
	  ds.title = ti.shift
	}
      }
    end
  end
end


plotExp
