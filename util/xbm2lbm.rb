#! /usr/bin/env ruby


require 'pp'



def main(xbm)
  base=xbm.sub(/\.xbm/,"")
  cols,rows=1,1
  if base.sub! /_(\d+)x(\d+)/,""
    rows,cols = $1.to_i,$2.to_i
  end

  File.read(xbm)=~/_width (\d+).*_height (\d+).*\{(.*)\}/m
  w,h,xbm_bits=$1.to_i,$2.to_i,$3
  xbm_bits=eval "["+xbm_bits+"]"
  #pp w,h,bits

  wb=(w+7)/8 #num bytes per row    in xbm
  hb=(h+7)/8 #num bytes per column in lbm

  out=Array.new(w*hb,0)
  #pp out

  #xbm-format Bytes horizontal
  # 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 .. (wb-1).7
  #
  # ---------
  # ---------
  #
  #lbm-format Bytes vertikal 
  # 
  # | | | | | | | |
  # | | | | | | | |
  # | | | | | | | |

  h.times{|yp| 
    yb=yp/8;           #vert byte idx lbm
    msk= 1 << (yp%8)   #lbm byte msk, bit0 = oben
    w.times{|xp| 
      xb=xp/8;         #hor byte idx xpm
      msk2=1 << (xp%8) #xpm byte msk, bit0 = links
      out[yb*w+xp]|=msk if xbm_bits[wb*yp+xb]&msk2 != 0
    }
  }
  #pp out

#prog_uchar img_4sticks_18x8[] = {
##include "sticks_lcd.h"
#};
  while out[-5..-1] == [0,0,0,0,0]
    out[-5..-1] = []
  end

  File.open("#{base}.lbm","wb"){|f|
    #col=0
    f.printf("uchar_p APM %s[] = {\n",base.sub(/.*\//,""))
    f.printf("%d,%d,%d,\n",0,0,0)
    chars=out.length/5
    chars.times{|ci|
      5.times{|i|
        f.printf("0x%02x,",out[i+ci*5])
      }
      f.printf("// %02x\n",ci+0x20)
    }

#     f.printf("%d,%d,%d,\n",w/cols,h/rows,w/cols*h/rows/8)
#     rows.times{|row|
#       (hb/rows).times{|yb| yb
#         w.times{|xp|
#           f.printf("0x%02x,",out[row*w + yb*w + xp])
#         }
#         f.puts
#       }
#     }
    f.printf("};\n")
  }
end


main(ARGV[0])
