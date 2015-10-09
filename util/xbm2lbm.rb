#! /usr/bin/env ruby


require 'pp'



def main(xbm,fn_lbm)
  base=xbm.sub(/\.xbm/,"")
  #cols,rows=1,1
  charWidth,charHeight=1,1
  if base.sub! /_(\d+)x(\d+)/,""
    charWidth,charHeight = $1.to_i,$2.to_i
  end
  charHeight==8 or raise "charHeight must be 8"


  File.read(xbm)=~/_width (\d+).*_height (\d+).*\{(.*)\}/m
  xbm_width, xbm_height, xbm_bits=$1.to_i,$2.to_i,$3
  xbm_bits=eval "["+xbm_bits+"]"
  #pp xbm_width,xbm_height,bits

  xbm_width_bytes=(xbm_width+7)/8 #num bytes per row    in xbm
  hb=(xbm_height+7)/8 #num bytes per column in lbm

  out=Array.new(xbm_width*hb,0)
  #pp out

  #xbm-format Bytes horizontal
  # 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 .. (wb-1).7
  #
  # 0--b[0]---7 0--b[1]---7 0--b[2]---7 0--b[3]---7 ..
  # 0--b[wb]--7 0--b[+1]--7  ..
  #
  #lbm-format Bytes vertikal 
  # 
  # 0   0   0   0  0  0  0  0
  # |   |   |   |  |  |  |  |
  # b   b   b   b  b  b  b  b
  #[0] [1] [2] [3] 
  # |   |   |   |  |  |  |  |
  # 7   7   7   7  7  7  7  7

  xbm_height.times{|yp| 
    yb=yp/8;           #vert byte idx lbm
    msk= 1 << (yp%8)   #lbm byte msk, bit0 = oben
    xbm_width.times{|xp| 
      xb=xp/8;         #hor byte idx xpm
      msk2=1 << (xp%8) #xpm byte msk, bit0 = links
      out[yb*xbm_width+xp]|=msk if xbm_bits[xbm_width_bytes*yp+xb]&msk2 != 0
    }
  }
  #pp out

  #cut off blank chars at the end
  while out[-charWidth..-1] == [0]*charWidth
    out[-charWidth..-1] = []
  end

  File.open(fn_lbm,"wb"){|f|
    #col=0
    f.printf("uchar_p APM %s[] = {\n",base.sub(/.*\//,""))
    f.printf("%d,%d,%d,//charWidth,charHeight,bytesPerChar\n",
             charWidth,charHeight,charWidth*charHeight/8,0)
    chars=out.length/charWidth
    chars.times{|ci|
      charWidth.times{|i|
        f.printf("0x%02x,",out[i+ci*charWidth])
      }
      f.printf("// %02x\n",ci+0x20)
    }

#     f.printf("%d,%d,%d,\n",xbm_width/cols,xbm_height/rows,xbm_width/cols*xbm_height/rows/8)
#     rows.times{|row|
#       (hb/rows).times{|yb| yb
#         xbm_width.times{|xp|
#           f.printf("0x%02x,",out[row*xbm_width + yb*xbm_width + xp])
#         }
#         f.puts
#       }
#     }
    f.printf("};\n")
  }
end


main(ARGV[0],ARGV[1])
