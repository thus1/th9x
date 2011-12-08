#!/usr/bin/env ruby
# -*- mode: ruby -*-
#!ruby
#$Id: fxList2.rb,v 1.1 2006/05/12 14:43:25 husteret Exp $

$: << File.dirname(__FILE__)
require "foxAdd"
require "pp"
include Fox

=begin
 todo
 - @list entfernen !! appendItem geht nur wenn Reihenfolge depth first

drag and drop


drag src                                drop target
-----------                             -----------
SEL_LEFTBUTTONPRESS
SEL_MOTION: 
 1 x grab,beginDrag(types)
 N x handleDrag,           ----------> 
                                        SEL_DND_MOTION
                                        offeredDNDType?
                                        
               SEL_DND_REQUEST <-----   getDNDData(dndTypeIdentify)
               setDNDData      ----->


     didAccept             <----------  acceptDrop
     dragCursor  


SEL_LEFTBUTTONRELEASE
     endDrag,             ----------> 
                                        SEL_DND_DROP
               SEL_DND_REQUEST <-----   getDNDData(dndTypeRcData)
               setDNDData      ----->

     dragCursor,ungrab





=end






module AutoScroll
  # Zugriff auf user-class:
  # - @sb, @canvas, app(), self
  # - onSbMoved, onMotion
  FUDGE=20
  def autoScrollStart(inside=true)
    return unless @sb
    @autoScrollInside = inside
    if !@autoScrollTmr
      @autoScrollTmr=app().addTimeout(200,method(:autoScrollTmr))
    end
  end
  def autoScrollStop()
    app().removeTimeout(@autoScrollTmr) if @autoScrollTmr
    @autoScrollTmr=nil
  end
  def autoScrollTmr(sender,sel,ptr)
    autoScrollStop()
    return unless @sb
    x,y,but=@canvas.cursorPosition() 
    #puts "autoScrollTmry(x=#{x},y=#{y},but=#{but})"
    if (dy = FUDGE-y) < 0
      dy = @canvas.height()-FUDGE-y
      dy = 0 if dy > 0
    end
    @sb.position -= dy*3
    @canvas.setCursorPosition(x,y+dy) 

    onSbMoved()#self,MKUINT(0,55),@sb.position) #verschiebe inhalt
    onMotion(self,MKUINT(0,SEL_COMMAND),@sb.position) #handle dragging
  end
end

class FXList2 < FXVerticalFrame #FXScrollWindow#Area
  include AutoScroll
  attr_reader :font, :textColor, :foreColor ,:selbackColor ,:seltextColor, :items
  def initialize(parent,opts,id,sb,*args)
@parent=parent
    puts "#{@parent.class}"
    @id=id
    super parent,opts,*args
    @header1 = FXHeader.new(self, nil, 0,
                            HEADER_RESIZE|
                            FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|
                            LAYOUT_FIX_HEIGHT,0,0,20,20)
    @header1.connect(SEL_CHANGED){ @canvas.update  }

    hf=FXHorizontalFrame.new(self,LAYOUT_FILL_X|LAYOUT_FILL_Y,*[0]*10)
    
    hf2=FXHorizontalFrame.new(hf,LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN,*[0]*10)
    @canvas = FXCanvas.new(hf2, nil, 0, # 0)
                           FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT,0,0,300,200)

    @sb=nil
    if sb
      @sb=FXScrollBar.new(hf, nil, 0,SCROLLBAR_VERTICAL|LAYOUT_FILL_Y)
      # @sb.connect(SEL_COMMAND){ @canvas.update  } 
      #SEL_COMMANDfuer wheel-scroll,  SEL_CHANGED fuer drag-scroll
      # @sb.watchAllSels
      @sb.connect(SEL_COMMAND,method(:onSbMoved))
      @sb.connect(SEL_CHANGED,method(:onSbMoved))
    end

    @canvas.connect(SEL_PAINT,method(:onPaint)) #{|x,y,z|onPaint x,y,z}
    @canvas.connect(SEL_MOUSEWHEEL){|sender,sel,ptr|  
      @sb.handle(sender,sel,ptr) if @sb
      1 
    }
    #drag vvvvvvvvvvvvvvv
    @canvas.connect(SEL_LEFTBUTTONPRESS,  method(:onLeftbuttonpress))
    @canvas.connect(SEL_MOTION,           method(:onMotion))
    @canvas.connect(SEL_LEFTBUTTONRELEASE,method(:onLeftbuttonrelease))
    @canvas.connect(SEL_DND_REQUEST,      method(:onDndRequest))
    #drag ^^^^^^^^^^^^^^^^^^
    #drop vvvvvvvvvvvvvvvvv
    @canvas.dropEnable()
    @canvas.connect(SEL_DND_ENTER,        method(:onDndEnter))
    @canvas.connect(SEL_DND_MOTION,       method(:onDnd_Drop_Motion))
    @canvas.connect(SEL_DND_DROP,         method(:onDnd_Drop_Motion))
    #drop ^^^^^^^^^^^^^^^^^^^^^^



    @canvas.connect(SEL_CONFIGURE){      _sbUpdate    }
    @userConnects={}
    # @canvas.connect(SEL_RIGHTBUTTONPRESS,method(:onRightBtnPress))
    
    
    #watchAllSELs(self,%W(SEL_UPDATE SEL_FOCUSIN SEL_FOCUSOUT))
    @items        = []
    @rootItems    = []
    @font         = getApp().normalFont
    @textColor    = getApp().foreColor
    @foreColor    = getApp().foreColor
    @selbackColor = getApp().selbackColor
    @seltextColor = getApp().selforeColor
    # @currItem   =nil
    @height=0
    @nocsr=@canvas.dragCursor
  end

  def update(*args)
    @canvas.update(*args)
  end
  def create
    super
    _recalcHeight
  end
  def dirtyHeight
    #puts "def dirtyHeight"
    @height = nil
  end
  def _checkHeight
    _recalcHeight if ! @height
  end
  def _rch(hs,items,lev="")
    items.each{|it|
      last = items.last==it
      @items<<it
      it.yPos=hs
      it.lev = lev + (last ? "'" : "|")
      hs+=it.getHeight() if !it.hidden
      hs=_rch(hs,it.childs, lev + (last ? " " : "|"))
    }
    hs
  end
  def _recalcHeight
    #puts "def _recalcHeight"
    hs=0
    @items=[]
    hs=_rch(hs,@rootItems)

    if @height!=hs
      @height=hs
      _sbUpdate()
    end
  end
  def sbPos
    @sb ? @sb.position : 0
  end
  def getState()
    [sbPos]
  end
  def setState(state)
    pos,=state
    _recalcHeight #macht _sbUpdate()
    return unless @sb
    @sb.position=pos #scrollpos wieder herstellen
    onSbMoved()
  end
  def _sbUpdate()
    #puts "_sbUpdate @height=#{@height}"
    #lastp=@sb.position
    return unless @sb
    @sb.range = @height || 1 # !! evtl aendert sich position
    @sb.line  = 16 #nicht groesser sonst wird smooth gescrollt
    @sb.page  = @canvas.height # !! evtl aendert sich position
    @sb.position=@sb.position # !! evtl aendert sich position
    onSbMoved()#nil,MKUINT(0,77),@sb.position) #if lastp!=@sb.position #onSbMoved hat pos-cache
  end
  def connect(sel,*args,&block)
    if [SEL_LEFTBUTTONPRESS,
        SEL_LEFTBUTTONRELEASE,
        SEL_MOTION,
        SEL_CLICKED,
        SEL_DND_DROP, SEL_DND_REQUEST, SEL_DND_MOTION
       ].include?(sel)
      @userConnects[sel]=block
    else
      @canvas.connect(sel,*args,&block)
    end
  end
  def checkUserConnects(sender,sel,event)
    sel=FXSELTYPE(sel)
    if @userConnects[sel]
      return @userConnects[sel].call(sender,sel,event)
    end
  end
  def collapseSubtrees
    @rootItems.each{|it|
      it.collapseSubtrees
    }
  end
  def appendHeader(name,icon,size,data)
    @header1.appendItem(name,icon,size,data)#("Name", nil, 150,1)
  end
  def appendItem(parent,it)
    it.init(self,parent)
    @rootItems<<it if parent.nil?
    dirtyHeight
    # @items<<it
  end
  def clear()
    dirtyHeight
    _sbUpdate()
    @items     = []
    @rootItems = []
  end
  def reverse_each()
    @items.reverse_each{|it| yield it }
  end
  def rootItem()
    @items[0]
  end
  def each()
    @items.each{|it| yield it }
  end

  def getHindex(x1)#welche splate, rest dx
    x=0
    @header1.each{|hitem|
      dx=x1-x
      if dx>0 and dx < hitem.size
        return [hitem.data,dx] 
      end
      x+=hitem.size
    }
    nil
  end
  def getItemAtCsr()
    x, y, buttons = @canvas.cursorPosition()
    getItemAt(x,y)
  end
  def getItemAt(x1,y)
    
    y+=sbPos
    iy=findItemId(y)
    #puts "def getItemAt(#{x1},#{y}) #{iy}"
    if iy >= 0
      it=@items[iy]
      hindex,dx=getHindex(x1)
      return [it,iy,hindex,dx,y-it.yPos] if hindex
    end
    return nil
  end

  def findItemId(absY)
    _checkHeight()
    lower = -1
    upper = @items.length 
    while lower + 1 != upper
      mid = ((lower + upper) / 2)
      if absY>@items[mid].yPos
        lower = mid
      else 
        upper = mid
      end
    end      
    if lower > 0
      it=@items[lower]
      return -1 if it.hidden or absY > (it.yPos + it.getHeight())
    end

    #lower + 1 == upper
    # [lower].y < y <= [upper].y
    lower
  end
  def onPaint(sender,sel,event)
    #puts "def onPaint(sender,sel,event) sbPos=#{sbPos}"
    #checkHeight() done in findItemId
    event_y  = event.rect.y
    event_yh = event_y+event.rect.h
    w = width
    i = findItemId(sbPos)
    y = -sbPos #!!! nach findItemId wegen checkHeight()
    #puts "def onPaint2(sender,sel,event) sbPos=#{sbPos} h=#{event.rect.h}"
    i = 0 if i<0
    
    y+= @items[i].yPos if @items[i] #evtl ist liste leer
    FXDCWindow.new(@canvas,event){|dc|
      while i<@items.length; it=@items[i]; i+=1
        next if it.hidden
        h=it.getHeight();
        break if y >= event_yh
        if event_y<y+h
          #printf(" %d",i)
          dc.setClipRectangle(0, y, width, h)
          it.draw(dc,0,y,width,h,i,nil)
          x=0
          @header1.each{|hit|
            dc.setClipRectangle(x, y, hit.size, h)
            it.draw(dc,x,y,hit.size,h,i,hit.data)
            x+=hit.size
          }
        end
        y+=h
      end
    }
    #puts
    if y < event_yh
      FXDCWindow.new(@canvas,event){|dc|
        #puts "y=#{y} ry=#{event.rect.y}  rh=#{event.rect.h}"
        dc.setForeground(fxcolorfromname('DarkGray'))#backColor)
        dc.fillRectangle(event.rect.x, y, event.rect.w, event.rect.y+event.rect.h-y)
      }
    end
  end
  def updateItem(it,y,h)
    #puts "def updateItem(it=#{it},y=#{y},h=#{h})"
    @canvas.update(0,y - sbPos,@canvas.width,h)
  end
  def selectItem(i,what=true)
    it=@items[i]
    it.select(what)
  end
  def selectAll(val=true)
    @items.length.times{|i| selectItem(i,val) }
    # @items.each_with_index{|item,idx| updateItem(idx)if item.select(val)}
  end

  def killSelection()
    selectAll(false)
    # @items.length.times{|i| selectItem(i,false) }
  end
  def selectRange(a,b,val=true)
    a,b = b,a if b<a
    (a..b).each{|i|  selectItem(i,val)   }
    #(a..b).each{|i|  updateItem(i) if @items[i].select(val)   }
  end
  

  #drag vvvvvvvvvvvvvvv
  def onLeftbuttonpress(sender,sel,event)
    # @mousepressed=true
    #return  unless i = event2idx(event) and @items[i]

    checkUserConnects(sender,sel,event)
    #grab();
    #pp event.ext
    item,index,hindex,dx,dy=getItemAt(event.win_x,event.win_y) 
    item or return
    # @canvas.update
    return if item.handle(hindex,dx,dy,sender,sel,event)
    return if checkUserConnects(self,MKUINT(0,SEL_CLICKED),[event,item])


    action = nil
    desel  = true
    if prevsel=item.selected?
      action = :MAYBE_DRAG
    else
      action = :SEL
    end
    if (event.state & 4) != 0 #ctrl erweitere selection ohne drag
      action = :SEL
      desel  = false
    elsif (event.state & 1) != 0 #sft
      action = :SEL_ZRANGE
    end

    case action
    when :MAYBE_DRAG
      @mode          = :MAYBE_DRAG
      @releaseAction = proc{  #in case of not Dragging only select
        selectAll(false)
        selectRange(index,index,true)
      #puts "selectRange"
      }
    when :SEL, :SEL_ZRANGE
      @mode          = :SEL_RANGE
      autoScrollStart(false)
      #p x,y,i
      selectAll(false) if desel

      if action==:SEL_ZRANGE
        @mode          = :SEL_ZRANGE
        @lastSel ||= index
        selectRange(@lastSel,index)
      else
        #puts "selectRange(#{index},index,:TOG)"
        selectRange(index,index,:TOG)
        #updateItem(i) if @items[i].select(:TOG)
      end
      @lastSel=index
    end
    #changeCurr(index) if !slideShow? or (event.state & 5) == 0
  end
  def onMotion(sender,sel,event) #mouse motion
    #puts "SEL_MOTION #{@mode} #{@canvas.dragging?} #{@parent.class}"
    checkUserConnects(sender,sel,event)
    #if @mode == :MAYBE_DRAG
    if @mode == :MAYBE_DRAG or @mode == :SEL_ZRANGE or @mode == :SEL_RANGE
      @mode          = :DRAGING
      @releaseAction = nil
      @canvas.grab
      # @canvas.beginDrag([$urilistType,$dndTypeRcData])
      @canvas.beginDrag([$dndTypeIdentify,$dndTypeRcData])
      autoScrollStart(true)
    end
    case @mode 
    when :DRAGING
      #puts ":DRAGING"
      #pp event.ext

      x,y,b=@canvas.root.cursorPosition()# ! event hat nicht immer koordinaten 
      #x,y=@canvas.root.translateCoordinatesFrom(@canvas,x,y)

      #puts "handleDrag x=#{x} y=#{y} "
      # @canvas.handleDrag(event.root_x, event.root_y)#invoke SEl_DND_reMOTION? at target 
      @canvas.handleDrag(x,y)#invoke SEl_DND_MOTION? at target 
      acc=@canvas.didAccept
      #puts "didAccept = #{acc}"
      csr=case acc
          when DRAG_COPY;   DEF_DNDCOPY_CURSOR
          when DRAG_MOVE;   DEF_DNDMOVE_CURSOR
          when DRAG_LINK;   DEF_DNDLINK_CURSOR
          else;             DEF_DNDSTOP_CURSOR
           end
      csr = getApp().getDefaultCursor(csr) or raise "missing cursor"
      @canvas.dragCursor = csr
    when :SEL_ZRANGE
      raise "oops1"
      if i = event2idx(event) and @items[i]
        selectRange(@lastSel,i)
      end
    when :SEL_RANGE
      raise "oops2"
      if i = event2idx(event) and @items[i]
        selectRange(i,i,true)
      end
    end
    1
  end
  def onLeftbuttonrelease(sender,sel,event)
    #puts "onLeftbuttonrelease"
    autoScrollStop()
    if @releaseAction
      #puts "releaseAction"
      @releaseAction.call 
    end
    if @mode == :DRAGING #@canvas.dragging?
      #puts "canvas.endDrag win_x=#{event.win_x}win_y=#{event.win_y}"
      case @canvas.endDrag
      when DRAG_COPY
        #puts "DRAG_COPY"
      when DRAG_MOVE
        #puts "DRAG_MOVE #{DRAG_MOVE}"
        # @fxpdir.reload
        #setDir(@fxpdir)
      when DRAG_LINK
        #puts "DRAG_LINK"
      end
      #p ["endDrag2",@canvas.endDrag]
      
      @canvas.dragCursor=@nocsr
      @canvas.ungrab
    end

    @releaseAction = nil
    @mode          = nil
    # @mousepressed=false
  end
  def onDndRequest(sender,sel,event)
    case event.target 
    when $dndTypeIdentify
      @canvas.setDNDData(FROM_DRAGNDROP, $dndTypeIdentify,Marshal.dump({:srcid=>@id}))
    when $dndTypeRcData
      #puts "def onDndRequest(sender,sel,event) dndTypeRcData"
      data={:droptyp => @canvas.didAccept}#move or copy ..
      @items.each_with_index{|item,i|
        next if !item.selected?
        data[:srcidx]=i
        item.select(false)
        break
      }
      data=checkUserConnects(self,MKUINT(0,SEL_DND_REQUEST),data)
      @canvas.setDNDData(FROM_DRAGNDROP, $dndTypeRcData, Marshal.dump(data))
    else
      raise "unknown request #{event.target} != #{$dndTypeIdentify},#{$dndTypeRcData}"
    end
  end
  #drag ^^^^^^^^^^^^^^^^^^
  #drop vvvvvvvvvvvvvvvvv

  def onDndEnter(sender,sel,event)#SEL_DND_ENTER.  
    #This message is received when the cursor first enters the Widget
    #killSelection()
  end
  def onDnd_Drop_Motion(sender,sel,event)#SEL_DND_MOTION,SEL_DND_DROP
    selt=FXSELTYPE(sel)
    #pp event.ext
    # bug??? win_x win_y hat flalschen bezugspunkt bei SEL_DND_DROP
    #item,index,hindex,dx,dy = if selt==SEL_DND_MOTION
    #                            getItemAt(event.win_x,event.win_y) 
    #                          else
    #                            getItemAt(event.last_x,event.last_y) 
    #                          end
    x,y=@canvas.translateCoordinatesFrom(@canvas.root,event.root_x,event.root_y)  
    item,index,hindex,dx,dy = getItemAt(x,y) 
    
    #puts "def onDnd_Drop_Motion(#{selt},#{x}.#{y},#{index})"

    #puts "onDndDropMotion #{@parent.class} #{$SEL2NAME[selt]} #{index}"
    if  item and
        !(item.selected?) and
        @canvas.offeredDNDType?(FROM_DRAGNDROP, $dndTypeIdentify) and
        @canvas.offeredDNDType?(FROM_DRAGNDROP, $dndTypeRcData)
      #puts " event2idx = #{i}"
      if selt==SEL_DND_MOTION
	if idData = @canvas.getDNDData(FROM_DRAGNDROP, $dndTypeIdentify)
          #pp idData

          data = Marshal.load(idData)
          data[:dstidx],data[:dstitem] = index,item
          acc=checkUserConnects(self,MKUINT(0,SEL_DND_MOTION),data)#[index,item]+data)
            if (event.state     & 4)!= 0 #ctrl
              acc=DRAG_COPY
            elsif (event.state & 1) != 0 #sft
              acc=DRAG_MOVE
            end
            #puts "acceptDrop #{acc}"
	    @canvas.acceptDrop(acc)
            return
          #end
        end
      else #SEL_DND_DROP
        #puts "getDNDData(FROM_DRAGNDROP >"
        while data = @canvas.getDNDData(FROM_DRAGNDROP, $dndTypeRcData)
          data = Marshal.load(data)    
          data[:dstidx]=index
          more=checkUserConnects(self,MKUINT(0,SEL_DND_DROP),data)#[index,data])
          break if !more
        end
        return 
      end
    end
    if selt==SEL_DND_MOTION
      @canvas.acceptDrop(DRAG_REJECT) 
    end
  end
  #drop ^^^^^^^^^^^^^^^^^^










  def onSbMoved(*args)#sender,sel2,new_y) #scroll the canvas
    #puts "def onSbMoved(sender,sel=#{FXSELTYPE(sel2)},new_y=#{new_y}) pos_y=#{@lastPos_y} sbPos=#{sbPos}"
    new_y   = sbPos
    dy      = (@lastPos_y||0) - new_y
    #puts "onSbMoved #[sel2] @lastPos_y=#{@lastPos_y} new_y=#{new_y} dy=#{dy}"
    if dy != 0
      @lastPos_y  = new_y
      @canvas.scroll(0,0,@canvas.width,@canvas.height,0,dy);
      #onMotion(sender,sel2,new_y)
    end
  end

end
class FXListGenericItem
  BG_WHITE1 = FXRGB(255,255,255)
  BG_WHITE2 = FXRGB(225,240,235)

  attr_reader   :list      #meine liste
  attr_reader   :parent    #mein parent-dir
  attr_accessor :childs    #meine kinder
  attr_accessor :yPos
  attr_accessor :hidden    #ich bin unsichtbar
  attr_accessor :collapsed #dieses dir ist eingeklappt -> alle childs sind hidden
  attr_accessor :lev       #hierarchy lines

  def init(list,parent) #wird von liste bedient
    @list,@parent=list,parent
    parent.childs << self  if parent
    @childs=[]
    @yPos=0
    @hidden=false
    @collapsed=false
  end
  IDT  = 15 # indent width
  EXPS =  8 # size of expander Box
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
  def drawTreeIcon(dc,x,y,w,h,icon,bgCol) #,expander=nil)#,icn2=nil)
    x0,y0=x,y
    x1=nil
    y1=y+h/2
    dc.fillStyle = FILL_STIPPLED#);
    dc.stipple   = STIPPLE_GRAY#,pos_x&1,pos_y&1);
    lev.each_byte{|c|
      x1=x+IDT/2
      case c.chr
      when " "
      when "'";  dc.drawLine(x1, y, x1, y+h/2) # ' vertik
      when "|";  dc.drawLine(x1, y, x1, y+h)   # | vertik
      end
      x+=IDT
    }
    dc.drawLine(x1, y1, x-1, y1) #horiz
    dc.fillStyle=FILL_SOLID
    if @childs.length>0 #expander
      #dc.fillColor=
      fgCol=dc.getForeground()
      dc.setForeground(bgCol)
      @xExp=x1-EXPS/2
      @yExp=y1-EXPS/2
      dc.fillRectangle(@xExp,@yExp,EXPS,EXPS)
      dc.setForeground(fgCol)
      dc.drawRectangle(@xExp,@yExp,EXPS,EXPS)
      @xExp-=x0
      @yExp-=y0
      dc.drawLine(x1-2,y1,x1+2,y1) #horiz
      dc.drawLine(x1,y1-2,x1,y1+2) if @collapsed #vert
    end

    #dc.drawRectangle(x1-5, y+h/2-5, 10, 10)
    if icon
      dc.drawIcon(icon, x, y+(h-icon.height)/2) 
      x+=icon.width
    end
    #dc.drawIcon(icn2, x, y+(h-icon.height)/2) if icn2
    x
  end
  def drawNumIcon(dc,x,y,w,h,nr,icon=nil)
    bgCol  = nr%2==0 ? BG_WHITE1 : BG_WHITE2
    dimcol = FXRGB(60,60,60)
    fgCol = list.textColor;
 
    if icon
      dc.setForeground(bgCol- dimcol)
      dc.fillRectangle(x,y,icon.width,h);

      dc.drawIcon(icon, x, y+(h-icon.height)/2) 
      x+=icon.width
      w-=icon.width
    end
    

    font = list.font
    th   = font.getFontHeight()
    asc  = font.getFontAscent()
    wt   = 1+5+font.getTextWidth("99")

    #if selected? #and data != 1
    #  bgCol = list.selbackColor 
    #  fgCol = list.seltextColor;
    #end
    dc.setForeground(bgCol- dimcol)#$app.baseColor-cdiff)
    dc.fillRectangle(x,y,wt,h);

    dc.setForeground(fgCol);
    dc.drawText(x+1,y+(h-th)/2+asc,"%02d"%nr)# if @nr
    return x+wt
  end


  def selected?()
    @selected
  end
  def select(what=true)
    what = !@selected if what == :TOG
    what = false      if empty?
    if @selected != what
      @selected=what
      update()
    end
  end
  def update()
    @list.updateItem(self,@yPos,getHeight())
  end
  def updateChildHiding(hide=false)
    #puts "def #{self} updateChildHiding(hide=#{hide})"
    hide |= @collapsed
    if @childs
      @childs.each{|it|
        it.hidden=hide
        it.updateChildHiding(hide)
      }
    end
  end
  def handle(hindex,dx,dy,sender,sel,event)
    #puts "def handle(hindex=#{hindex},dx=#{dx},dy=#{dy},@xExp=#{@xExp},@yExp=#{@yExp})"
    if  @xExp and @yExp and
        @xExp <= dx and @xExp+EXPS+1 >= dx and
        @yExp <= dy and @yExp+EXPS+1 >= dy
      @collapsed = ! @collapsed
      updateChildHiding()
      @list.dirtyHeight
      @list.update
      return true
    end
    false
  end
  def collapseSubtrees()
    _excollSubtrees(false)
    @list.dirtyHeight
    @list.update
  end
  def expandSubtrees()
    _excollSubtrees(true)
    @list.dirtyHeight
    @list.update
  end
  def _excollSubtrees(expand,skip=1)
    @collapsed = ! expand
    @hidden    = ! expand unless skip > 0
    @childs.each{|it| it._excollSubtrees(expand,skip-1)  }  if @childs
  end
end





#
# Test Test Test Test Test Test Test Test Test Test Test Test
# Test Test Test Test Test Test Test Test Test Test Test Test
# Test Test Test Test Test Test Test Test Test Test Test Test
#

if $0 == __FILE__
  class FXListMyItem < FXListGenericItem
    #attr_accessor :txt, :icon, :lev #, :list
    #attr_reader :txt, :icon, :lev #, :list
    def initialize(txt,icon)#,lev)#,isDir)
      # @txt,@icon,@lev,@isDir=txt,icon,lev,isDir
      @txt,@icon=txt,icon
      @selected=false
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
      bgCol = i%2==0 ? FXRGB(255,255,255) : FXRGB(235,250,245)
      fgCol = list.textColor;
        #i%2==0 ? list.backColor : FXRGB(240,245,250))
      if selected? #and data != 1
        bgCol = list.selbackColor 
        fgCol = list.seltextColor;
      end
      dc.setForeground(bgCol)
      dc.fillRectangle(x,y,w,h);
      
      dc.setForeground(fgCol);
      case data
      when 1
        #dc.setForeground(list.foreColor)
        drawTreeIcon(dc,x,y,w,h,@icon,bgCol) if @icon
          #x+=@icon.width+2
      when 2
        font=list.font
        th=font.getFontHeight()
        asc=font.getFontAscent()
        #puts "drawText(x=#{x},y=#{y},h=#{h} @txt=#{@txt} th=#{th} asc=#{asc})"
        dc.setFont(font);
        dc.drawText(x,y+(h-th)/2+asc,@txt)
      when 3
      end

      #dc.fillRectangle(x+2,y,5,9);
      #printf "%08x %08x",list.seltextColor,list.textColor
      #dc.setForeground( list.textColor );

    end
    def getHeight()
      # puts "h1=#{list.font.getFontHeight()} h2=#{@icon.height}"
      return @h if @h
      @h=list.font.getFontHeight()+2
      @h=[@icon.height+2,@h].max if @icon
      @h
    end
    def handle(hindex,dx,dy,sender,sel,event)
      return super if hindex==1
      false
    end
  end

  def recu(dir,l,parent=nil)
    d=Dir.pwd
    Dir.chdir(dir)
    dirs  = []
    files = []
    Dir["*"].each{|f| 
      dirs  << [f,$minifolder,true ,false ] if File.directory? f
      files << [f,$minidoc   ,false,false ] if File.file? f
    }
    all=dirs+files[0,10]
    if all.length!=0
      all[-1][3]=true
      all.each{|f,icn,isDir,isLast|
        l.appendItem(parent,it=FXListMyItem.new(f,icn))#,lev+"'",isDir))
        recu(f,l,it) if isDir
      }
    end
    Dir.chdir(d)
  end



  $app = FXApp.new('Svntree', 'thus')
  mw=FXMainWindow.new($app, "FXMainWindow" , nil, nil, DECOR_ALL, 0, 0, 500, 150)
  l = FXList2.new(mw,LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
  $minidoc          = iconFromDat("minidoc.png")
  $minifolder       = iconFromDat("minifolder.png")

  l.appendHeader("Icon",  nil, 150,1)
  l.appendHeader("Name",  nil, 150,2)
  l.appendHeader("Dummy", nil, 150,3)

  dir=ARGV[0] || File.dirname(__FILE__)
  recu(dir,l)
  l.connect(SEL_RIGHTBUTTONPRESS){|sender,sel,event|
    state=l.getState
    l.clear
    recu(dir,l)
    l.setState(state)
    l.update
  }

  mw.show(PLACEMENT_SCREEN) # Make the main window appear
  $app.create
  $app.run
end

