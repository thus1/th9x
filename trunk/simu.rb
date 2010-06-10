#!/usr/bin/env ruby

require 'fox16'
require 'pp'

include Fox



application = FXApp.new("Hello2", "FoxTest")
main = FXMainWindow.new(application, "Hello", nil, nil, DECOR_ALL)

f=main
icon0 = FXPNGIcon.new(application, File.read("PNG/fernkompl_0.png"),0x1)
icon1 = FXPNGIcon.new(application, File.read("PNG/fernkompl_1.png"),0x1)
icon2 = FXPNGIcon.new(application, File.read("PNG/fernkompl_2.png"),0x1)
iconMsk = FXPNGIcon.new(application, File.read("PNG/fernkompl_msk.png"))#,IMAGE_ALPHAGUESS)
w=iconMsk.width
h=iconMsk.height

iconSw0 = []
iconSw1 = []
iconSw2 = []
#8.times{|i| iconSw[i]=FXIcon.new(application,nil,IMAGE_ALPHACOLOR|IMAGE_OWNED|IMAGE_KEEP,w,h)}

data="\xff"*4*w*h
#iconSw0[1]=FXPNGIcon.new(application, data,0xffffffff,IMAGE_ALPHACOLOR)
iconSw0[1]=FXPNGIcon.new(application, File.read("PNG/fernkompl_empty.png"))
iconSw0[1].create
iconSw0[1].restore
0.times{|i| 
  iconSw0[i]=FXPNGIcon.new(application, File.read("PNG/fernkompl_empty.png"),0xffffffff,IMAGE_ALPHACOLOR)
  iconSw0[i].create
  iconSw0[i].restore
  iconSw1[i]=FXPNGIcon.new(application, File.read("PNG/fernkompl_empty.png"),0xffffffff,IMAGE_ALPHACOLOR)
  iconSw1[i].create
  iconSw1[i].restore
  iconSw2[i]=FXPNGIcon.new(application, File.read("PNG/fernkompl_empty.png"),0xffffffff,IMAGE_ALPHACOLOR)
  iconSw2[i].create
  iconSw2[i].restore
}
pp "%x"%iconSw0[1].getPixel(0,0)
#FXDCWindow.new(iconSw[1]){|dc|
#  dc.foreground = 0x0ffffff
#  dc.fillRectangle(0, 0, w, h)
#}
exit
h.times{|y|
  w.times{|x|
    col=iconMsk.getPixel(x,y)
    #8.times{|i| iconSw[i].setPixel(x,y,0)}
    case col
    when 0xffffffff
    else
#    when 0xff1000f0    when 0xff10f0f0
#    when 0xff2000f0    when 0xff20f0f0
#    when 0xff3000f0    when 0xff30f0f0
#    when 0xff4000f0    when 0xff40f0f0   when 0xff40a0f0
#    when 0xff5000f0    when 0xff50f0f0
#    when 0xff6000f0    when 0xff60f0f0
#    when 0xff7000f0    when 0xff70f0f0
      iconSw0[col>>20 & 0xf].setPixel(x,y,icon0.getPixel(x,y)^1)
      iconSw1[col>>20 & 0xf].setPixel(x,y,icon1.getPixel(x,y)^1)
      iconSw2[col>>20 & 0xf].setPixel(x,y,icon2.getPixel(x,y)^1)
      #iconSw1[col>>20 & 0xf].setPixel(x,y,icon2.getPixel(x,y)&0xffff5555)
      #iconSw1[col>>20 & 0xf].setPixel(x,y,col)
#      raise "unknown col 0x%x"%col
    end
  }
}
8.times{|i| 
  iconSw0[i].transparentColor=0xffffffff
  iconSw0[i].render
  iconSw1[i].render
}
#iconSw[1].create
icon0.create
#icon0.transparentColor=0xfffffffe
pp iconMsk.transparentColor
iconMsk.create
FXDCWindow.new(icon0){|dc|
  #dc.drawIcon(iconMsk,0,0)
  #dc.drawImage(iconSw[1],0,0)
  dc.drawIcon(iconSw1[1],0,0)
  dc.drawIcon(iconSw1[3],0,0)
  dc.drawIcon(iconSw1[5],0,0)
  dc.drawIcon(iconSw1[6],0,0)
  dc.drawIcon(iconSw1[7],0,0)
}

iconD = FXPNGIcon.new(application, File.read("PNG/snapshotM0-gr.png"))
stick = FXPNGIcon.new(application, File.read("PNG/stick.png"))


l1=FXImageFrame.new(f, icon0, FRAME_NONE,0,0,750,900)
#l1=FXImageFrame.new(f, iconSw1[1], FRAME_NONE,0,0,750,900)
l2=FXImageFrame.new(f, iconD,FRAME_NONE|LAYOUT_FIX_X|LAYOUT_FIX_Y,235,660,0,0)
l3=FXLabel.new(f, "",stick,LAYOUT_FIX_X|LAYOUT_FIX_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,440,400,30,30)
l3.connect(SEL_LEFTBUTTONPRESS){|send,sel,evt|
  puts "lbpress"
  $pos0=[l3.x-evt.root_x,l3.y-evt.root_y]
  l3.grab
  #l3.enable
  0
}
l3.connect(SEL_LEFTBUTTONRELEASE){
  puts "lbrel"
  l3.ungrab
  0
}
l3.connect(SEL_MOTION){|send,sel,evt|
  puts "SEL_MOTION",evt.win_x
  if l3.grabbed?
    l3.position(evt.root_x+$pos0[0], evt.root_y+$pos0[1],30,30)
  end
  0
}


b2=FXButton.new(f, "&Hello, World2!", nil, application, FXApp::ID_QUIT,
BUTTON_NORMAL|LAYOUT_EXPLICIT,30,40,100,40)

[
 [140,250,0x111111],
 [118,170,0xeeeeee],
 [564,170,0xeeeeee],
].each{|x,y,col|

  b3=FXKnob.new(f,nil,0,LAYOUT_EXPLICIT,x,y,50,50)
  b3.backColor  =col
  b3.lineColor  =0xffffff-col
  b3.baseColor  =0xfff
  b3.borderColor=0xfff
  b3.hiliteColor=0xffffff-col
  b3.shadowColor=0xffffff-col
}
[
 [76,711,30,30,ARROW_LEFT],
 [158,711,30,30,ARROW_RIGHT],
 [119,668,30,30,ARROW_UP],
 [119,750,30,30,ARROW_DOWN],
 [575,693,50,30,ARROW_LEFT],
 [575,750,50,30,ARROW_LEFT],
 [279,440,20,20,ARROW_UP],
 [432,440,20,20,ARROW_UP],
 [432,486,20,20,ARROW_DOWN],
 [279,486,20,20,ARROW_DOWN],
 [144,571,20,20,ARROW_LEFT],
 [185,571,20,20,ARROW_RIGHT],
 [520,573,20,20,ARROW_LEFT],
 [566,573,20,20,ARROW_RIGHT],
].each{|x,y,w,h,dir|
  ab=FXArrowButton.new(f,nil,0,dir|LAYOUT_EXPLICIT,x,y,w,h)
  ab.backColor  =0x010101
  ab.arrowColor =0x444444
  ab.baseColor  =0x444444
  ab.borderColor=0x111111
  ab.hiliteColor=0x222222
  ab.shadowColor=0x111111
}


application.create
main.show(PLACEMENT_SCREEN)
application.run
