#!/usr/bin/env ruby
# -*- mode: ruby -*-
#!ruby
#$Id: fxText2.rb 91006 2010-09-23 09:59:22Z ceu\husteret $


if $0 == __FILE__
  $FOX_VER||="fox16"
  $: << File.dirname(__FILE__)
  require $FOX_VER
  include Fox
end
require "pp"

class FXText
  def col(color)
    if color.is_a? String
      color=~/(\w+)?:?(\w+)?/
      fgcol,bgcol=$1,$2
    else
      fgcol=color
    end
    #color=fxcolorfromname(color) if color.is_a? String
    if !@hsh
      @hs=[]
      @hsh={}
      self.styled = true
      self.hiliteStyles = @hs
    end
    if !@hsh[color]
      h = FXHiliteStyle.new
      h.normalForeColor = fgcol || self.foreColor
      h.normalBackColor = bgcol || self.backColor
      h.selectForeColor = self.selTextColor
      h.selectBackColor = self.selBackColor
      h.hiliteForeColor = self.hiliteTextColor
      h.hiliteBackColor = self.hiliteBackColor
      h.activeBackColor = self.activeBackColor
      h.style = 0
      @hs<<h
      @hsh[color]=@hs.length
      self.hiliteStyles = @hs
    end
    @hsh[color]
  end
  def addColTxt(txt, color=nil)
    #txt=txt.tr("\x7f-\xff",".")
    if txt=~/[\x7f-\xff]/
      txt=txt.unpack("C*").pack("U*") 
      puts txt
    end
    i=color ? col(color) : 0
    appendStyledText txt,i
  end
end

class FXText2 < FXText
  def initialize(*args)
    super *args
    # @posArr=[]
    # @currHigh=nil #SEL_LEFTBUTTONPRESS
    clean
    #connect(SEL_FOCUS_SELF){ |sender,sel,event|
    connect(SEL_LEFTBUTTONRELEASE){ |sender,sel,event|
      #puts ""
      if event.click_count==2 and @currHigh
        p,l,arg,block=@currHigh
        setSelection(p, l) 
        block.call(sender,sel,event,arg)
        1
      else
        0
      end
    }
    connect(SEL_RIGHTBUTTONRELEASE){ |sender,sel,event|
      if @currHigh
        p,l,arg,block=@currHigh
        setSelection(p, l) 
        block.call(sender,sel,event,arg)
      else
        0
      end
    }
    connect(SEL_ENTER){ 
      onPoll()     
    }
    connect(SEL_DELETED){ |sender,sel,event|  
      #pp event,event.methods.sort
      #trackDeletes(event[0],event[1]) fox 1.0
      trackDeletes(event.pos,event.ndel)
    } 
    connect(SEL_INSERTED){|sender,sel,event|  #kommt nicht in fox16 -> SEL_REPLACED
    #  trackInserts(event[0],event[1]) fox 1.0
      trackInserts(event.pos,event.nins)
    } 
    connect(SEL_REPLACED){|sender,sel,event|  
      #puts "SEL_REPLACED event.pos=#{event.pos},event.nins=#{event.nins} event.ndel=#{event.ndel}"
      trackInserts(event.pos,event.nins-event.ndel)
    } 
    connect(SEL_LEAVE){ 
      stopPoll()   
      @currHigh=nil
      killHighlight()
    }
  end
  def stopPoll()
    getApp().removeTimeout(@pollTmr) if@pollTmr
    @pollTmr=nil
  end
  def onPoll()
    stopPoll()
    x,y,b=cursorPosition() 
    pos=positionAt(x, y) 
    #pp pos,x,y,b
    @currHigh=nil
    if pos
      @posArr.each{|arr| p,l,arg,block=arr
        if pos>=p and pos < p+l
          setHighlight(p, l)
          #block.call(arg)
          #hit=true
          @currHigh=arr
          break
        end
      }
    end
    killHighlight() if !@currHigh
    @pollTmr= getApp().addTimeout(100){onPoll}
  end
  private :stopPoll, :onPoll
  def addCmd(pos,len,arg,&block)
    @posArr<<[pos,len,arg,block]
  end
  def trackInserts(p1,n) #after insert
    puts "def trackInserts(p1=#{p1},n=#{n})"
    @posArr.each{ |mark| pos,len,arg,block=mark # @posArr[i]
      #          [pos, len [
      #1                     p1         ok
      #2              p1                prolong
      #3  p1                            move         
      if p1< (pos+len)      #2 3
        if p1>= pos         #2
          mark[1]  = len+n
        else
          mark[0]  = pos+n
        end
      end
    }
  end
  def trackDeletes(p1,n) #before delete
    puts "def trackDeletes(p1=#{p1},n=#{n})"
    #super
    p2=p1+n
    dels=[]
    @posArr.each{ |mark| pos,len,arg,block=mark # @posArr[i]
      #          [pos, len [
      #1                     p1   p2    ok
      #2              p1     p2          shorten
      #3           p1   p2               shorten
      #4       p1            p2          remove
      #5       p1    p2                  move+shorten
      #6  p1  p2                         move         
      if p1< (pos+len)      #2-6
        if p1> pos          #2 3
          if p2>=(pos+len)   #2
            #puts "2"
            mark[1]  = p1-pos
          else              #3
            #puts "3"
            mark[1]  = len-n
          end
        else                #4 5 6
          if  p2 >=(pos+len) #4
            dels << mark
            #mark=nil # @posArr.delete(i); i-=1
            #puts "4"
          elsif p2 > pos    #5
            mark[0]  = p1
            mark[1]  = (pos+len-p2)
            #puts "5"
          else              #6
            mark[0]  = pos-n
            #puts "6"
          end
        end
      end
    }
    #l1= @posArr.length
    @posArr -= dels
    #l2= @posArr.length
    #puts "l1-l2=#{l1-l2}"
  end
  def clean()
    stopPoll
    self.text=""
    @posArr=[]
    @currHigh=nil
  end
end



if $0 == __FILE__
  $app = FXApp.new('test', 'thus')
  seed=rand(2**31)
  puts "seed=#{seed}"
  srand(seed)
  mw=FXMainWindow.new($app, "FXMainWindow" , nil, nil, DECOR_ALL, 0, 0, 500, 700)
  #Fox::FXPseudoTarget.startExcCatcher($app,mw)
  $font1 = FXFont.new($app, "fixed", 9, FONTWEIGHT_BOLD)
  $font1.create

  @text = FXText2.new(mw,nil,0,LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
  @text.font     = $font1
  @text.styled   = true
                         
  
  File.open(__FILE__){|fh|
    buf=fh.read
    buf.scan(/(\S+)(\s+)?/){
      p=@text.length
      @text.addColTxt($1,%w(Red Blue Green:Red)[rand(3)])
      l=@text.length-p
      @text.addCmd(p,l,$1){|sender,sel,event,arg| puts "hit '#{arg}'"  }
      @text.appendText($2)
    }
    
  }
  mw.show(PLACEMENT_SCREEN) # Make the main window appear
  $app.create

  $app.run
end
