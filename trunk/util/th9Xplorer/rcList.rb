require "fxList2"
require "eeprom"
require "fileutils"
include FileUtils



SELUSER_RCLOADED=1000


class FXListRcItem < FXListGenericItem
    #attr_accessor :txt, :icon, :lev #, :list
    #attr_reader :txt, :icon, :lev #, :list
  LPAD=4

  def empty?
    not @name
  end
  def select(what=true)
    #puts "select #{what} #{empty?}"
    super if ! empty?
  end

  def initialize(nr)#,lev)#,isDir)
    @nr=nr
    @selected=false
    set(nil,nil,nil)
  end
  def set(icon,name,size)#,lev)#,isDir)
    # @name,@icon,@lev,@isDir=name,icon,lev,isDir
    @icon,@name,@size=icon,name,size
  end

  # D      Dir
  # |- D   SubDir
  # |  |-F
  # |  |-F
  # |  \-D
  # |    |-F
  # |    |-F
  # |    \-F
  # |- F   File
  # |- F   File
  # \- F   File
  #
  #IDT = 15
  def draw(dc,x,y,w,h,i,data)
    white  = FXRGB(255,255,255)
    white2 = FXRGB(225,240,235)
    bgCol = i%2==0 ? white  : white2
    cdiff = white-bgCol
    fgCol = list.textColor;
    #i%2==0 ? list.backColor : FXRGB(240,245,250))
    if selected? #and data != 1
      bgCol = list.selbackColor 
      fgCol = list.seltextColor;
    end
    dc.setForeground(data== :Nr ? $app.baseColor-cdiff : bgCol)
    dc.fillRectangle(x,y,w,h);
    x+=LPAD

    dc.setForeground(fgCol);
    font=list.font
    th=font.getFontHeight()
    asc=font.getFontAscent()
    dc.setFont(font);
    case data
    when :Icon
      dc.drawIcon(@icon,x,y) if @icon
    when :Nr
      dc.drawText(x,y+(h-th)/2+asc,"%2d"%@nr) if @nr
    when :Name
      if @name
        dc.drawText(x,y+(h-th)/2+asc,@name)
      else
        dc.setForeground(i%2==0 ? white2  : white)
        dc.drawText(x,y+(h-th)/2+asc,"e m p t y")
      end
    when :Size
      dc.drawText(x,y+(h-th)/2+asc,@size.to_s)if @size
    end

    #dc.fillRectangle(x+2,y,5,9);
    #printf "%08x %08x",list.seltextColor,list.textColor
    #dc.setForeground( list.textColor );

  end
  def getHeight()
    # puts "h1=#{list.font.getFontHeight()} h2=#{@icon.height}"
    #return @h if @h
    #@h=list.font.getFontHeight()+2
    #@h=[@icon.height+2,@h].max if @icon
    #@h
    20
  end
  def handle(hindex,dx,dy,sender,sel,event)
    #return super if hindex== #click at icon
    false
  end
end



class RcList < FXGroupBox
  def initialize(parent,prefDialog)
    @prefDialog=prefDialog
    #gbr=FXGroupBox.new(parent, "RC" ,LAYOUT_FILL_Y|GROUPBOX_NORMAL|GROUPBOX_TITLE_CENTER|FRAME_RIDGE, 0,0,0,0, 0,0,0,0, 0,0) # x y w h  l r t b  h v
    gbr=self
    @myId = "rcList#{rand(10000)}"
    super(parent, "RC" ,LAYOUT_FILL_Y|GROUPBOX_NORMAL|GROUPBOX_TITLE_CENTER|FRAME_RIDGE, 0,0,0,0, 10,10,25,5, 0,0) # x y w h  l r t b  h v


    @list = FXList2.new(gbr,LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN,@myId,nil,0,0,0,16*20+26,0,0,0,0,0,0)
    @list.backColor = parent.backColor
    @list.appendHeader("Nr",  nil, 25, :Nr)
    @list.appendHeader("",  iconFromDat("flag.png"), 24, :Icon)
    @list.appendHeader("Modelname",  nil, 100,:Name)
    @list.appendHeader("Size",  nil, 40,:Size)
    # @list.connect(SEL_KEYPRESS){|sender,sel,event|
    #  @keyDispatcher.onKeypress(event.code,event.state,event.time)
    #}
    #@list.clear

    @userConnects={}
    @rcItems=[]
    16.times{|i|
      @rcItems[i]=it=FXListRcItem.new(i+1)
      @list.appendItem(nil,it) 
    }
    
    hfb=FXHorizontalFrame.new(gbr, LAYOUT_CENTER_X, 0,0,0,0, 10,10,10,10, 40,20)

    FXArrowButton.new(hfb,nil,0,FRAME_RAISED|FRAME_THICK|ARROW_UP){|a|
      a.arrowSize=30
      a.connect(SEL_COMMAND) {
        rcLoad()
        checkUserConnects(self,MKUINT(0,SELUSER_RCLOADED),nil)
      }
    }

    FXArrowButton.new(hfb,nil,0,FRAME_RAISED|FRAME_THICK|ARROW_DOWN){|a|
      a.arrowSize=30
      a.connect(SEL_COMMAND) {
        rcSave()
      }
    }
    

    FXLabel.new(gbr,"",$icnth9x,LAYOUT_CENTER_X)

    
    @mpop = FXPopup.new(self)
    #FXMenuCaption.new(@mpop,"Caption")
    #FXMenuSeparator.new(@mpop)
    FXMenuCommand.new(@mpop,"Rename..").connect(SEL_COMMAND){|sender,sel,event|
      @list.items.each_with_index{|item,i|
        if item.selected?
          name,ctent = @rcFiles[i+1]
          s = name
          s = FXInputDialog.getString(s, self, "Rename File","from: #{s} to:",nil) 
          if s and s != name
            @rcFiles[i+1][0] = s
            # @fileSys.mv item.path(),item.path(s)
          end
        end
      }
      @list.killSelection()
      refresh()
    }
    FXMenuCommand.new(@mpop,"Delete").connect(SEL_COMMAND){|sender,sel,event|
      @list.items.each_with_index{|item,i|
        if item.selected?
          @rcFiles[i+1]=[nil,""]
        end
      }
      @list.killSelection()
      refresh()
    }

    @list.connect(SEL_RIGHTBUTTONPRESS){|sender,sel,data|
      @mpop.create
      item,index,hindex,dx,dy=@list.getItemAtCsr()
      if item 
        if  ! item.selected?
          @list.killSelection()
          item.select
        end
        x, y, buttons = getRoot().getCursorPosition()
        @mpop.popup(nil, x+10, y-4)
      end
    }



  #drag vvvvvvvvvvvvvvvvv
    @list.connect(SEL_DND_REQUEST){|sender,sel,data|
      # drag-src: daten an drop target ausliefern
      #mode,sidx,*idxRest = data
      #ret  = @rcFiles[sidx+1]
      mode,*idxRest = data
      ret=[]
      idxRest.each{|sidx|
        ret << @rcFiles[sidx+1]
        @list.selectItem(sidx,false)
        if mode == DRAG_MOVE
          @rcFiles[sidx+1]=[nil,""] 
          # puts "move deletes orig"
          break #move only the first of selection
        end
      }
      refresh()
      ret
    }
  #drag ^^^^^^^^^^^^^^^^^^
  #drop vvvvvvvvvvvvvvvvv
    @list.connect(SEL_DND_MOTION){|sender,sel,data|
      # drop-tgt: action an drag-src liefern
      tgtIndex,tgtItem,srcId = data
      #puts "#{@myId} MOTION #{srcId} #{tgtItem}"
      ret=DRAG_REJECT
      if tgtItem and tgtItem.empty?
	if srcId==@myId
          #puts "#{@myId} == #{srcId}"
	  ret=DRAG_MOVE
	else
          #puts "#{@myId} != #{srcId}"
	  ret=DRAG_COPY
	end
      end
      ret
    }

    @list.connect(SEL_DND_DROP){|sender,sel,data|
      # drop-tgt: drop ausfuehren
      #puts "SEL_DND_DROP"
      # dsti,name_contents = data
      #puts "dsti=#{dsti}"
      # @rcFiles[dsti+1]=name_contents
      # @list.selectItem(dsti,true)
      dsti,list = data
      list.each{|name_contents| #=name_contents
        @list.selectItem(dsti,true)
        @rcFiles[dsti+1]=name_contents
        dsti+=1
      }

      #pp @rcFiles
      refresh()
    }
  #drop ^^^^^^^^^^^^^^^^^^
    @rcFiles=Array.new(20)
  end
  def connect(sel,*args,&block)
    #if [SEL_LEFTBUTTONPRESS,
    #    SEL_LEFTBUTTONRELEASE,
    #    SEL_MOTION,
    #    SEL_CLICKED,
    #    SEL_DND_DROP, SEL_DND_REQUEST, SEL_DND_MOTION
    #   ].include?(sel)
    @userConnects[sel]=block
    #else
    #  @canvas.connect(sel,*args,&block)
    #end
  end
  def checkUserConnects(sender,sel,event)
    puts "def checkUserConnects(sender,#{sel},event)"
    sel=FXSELTYPE(sel)
    pp  @userConnects
    if @userConnects[sel]
      return @userConnects[sel].call(sender,sel,event)
    end
  end
   def getFiles
    @rcFiles[1..16]
  end
#  def sysPd(cmd)
#    pd = FXProgressDialog.new(self, "caption", "label",PROGRESSDIALOG_NORMAL|PROGRESSBAR_HORIZONTAL)
#    pd.create
#    pd.show
#    sleep 0.1
#    IO.popen(cmd){|f|
#      while !f.eof
#	s=f.gets
#	puts s
#	$log.appendText(s)
#	pd.increment(10)
#      end
##    }
#  end
  def dudeBase()
    cmd  = ""
    cmd += @prefDialog.getVal(:AVRDUDEPATH)
    cmd += " -C " + @prefDialog.getVal(:AVRDUDECONF)
    cmd += " " + @prefDialog.getVal(:AVRDUDEPROGARGS)
  end
  def rcSave()
    rm_f "eeTmp"

    if $opt_t
      sys dudeBase + " -p 2343 -Ueeprom:r:eeTmp:r"
      cp "../eeprom.bin","eeTmp"
    else
      sys dudeBase + " -p m64 -Ueeprom:r:eeTmp:r"
    end
    eeReader=Reader_V4.new
    File.open("eeTmp"){|f| eeReader.readEEprom(f); }
    
    eeWriter=Reader_V4.new
    eeWriter.format() 

    [0,18,19].each{|fi| #retain admin files (18,19 are unknown usage)
      fb,typ,sz= eeReader.readFile(fi)
      eeWriter.writeFile(fi,typ,fb) if fb.length!=0
    }
    (1..16).each{|idx|
      name,contents = @rcFiles[idx]
      eeWriter.writeFile(idx,2,contents) if contents and contents.length!=0
    }
    eeWriter.info
    
    File.open("eeTmp","w"){|f| f.write(eeWriter.toBin) }
    if $opt_t
      cp "eeTmp","../eeprom.bin"
      sys dudeBase + " -p 2343 -Ueeprom:r:eeTmp:r"
    else
      sys dudeBase + " -p m64 -Ueeprom:w:eeTmp:r"
    end
    
  end
  def rcLoad()
    #/etc/udev/rules.d:  PRODUCT=="USBasp",    MODE="0666", OPTIONS="last_rule"
    #sys("echo hello2;sleep 1; echo hello3; sleep 1")
    rm_f "eeTmp"

    if $opt_t
      sys dudeBase + " -p 2343 -Ueeprom:r:eeTmp:r"
      cp "../eeprom.bin","eeTmp"
    else
      sys dudeBase + " -p m64 -Ueeprom:r:eeTmp:r"
    end

    eeReader=Reader_V4.new
    File.open("eeTmp"){|f| eeReader.readEEprom(f); }
    
    eeReader.eachFile{|idx,name,contents|
      name=name.strip.tr("\s","_")
      @rcFiles[idx] = [name,contents]
    }
    refresh()
  end
  def refresh()
    16.times{|i|
      name,contents=@rcFiles[i+1]
      if name
        @rcItems[i].set($minidoc,name,contents.length)
      else
        @rcItems[i].set(nil,nil,nil)
      end
    }
    @list.update
  end
end
