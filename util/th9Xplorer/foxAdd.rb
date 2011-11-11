require "timeout"
require "rbAdd"


$FOX_VER ||= "fox16"
require $FOX_VER
include Fox
FOX_DIR=$".grep(/(fox.*)\.so/){$1}.first #"
puts "FOX_DIR=#{FOX_DIR} Fox::fxrubyversion()#{Fox::fxrubyversion()}"
require FOX_DIR+'/colors'

class FXTabBar
  def currentChild()
    return childAtIndex(current()*2)
  end
end

class KeyDispatcher
  def initialize() #KeyDispatcher
    @lastKeyTime = 0
    @globlKeyMap = {}
    @lastKeyMap  = @globlKeyMap
    @currKeySeq  = []
  end
  def addKeyCmd(keyCode,cmd,*args) # "a", "a b", "C-a M-b  C-M-a" #KeyDispatcher
    #see /home/husteret/tmp/SfcRuby/lib/ruby/site_ruby/1.8/fox/keys.rb
    km=@globlKeyMap
    seqa=keyCode.split(/ +/)
    while modk=seqa.shift #"C-a"
      modka=modk.split(/-/) #"C-a"
      code = modka.pop[0] #!! code could be > 128 if KEY_xx used
      mod  = 0 #shift pressed
      modka.each{|m|
        case m
        when "C"; mod |= 4
        when "M"; mod |= 8
        end
      }
      extkey=code + (mod<<16)
      if seqa.length==0 #last key in sequence
        warn "keycode '#{keyCode}' already used. #{km.inspect}" if  km.has_key?(extkey)
        args.unshift cmd
        km[extkey]=args
      else
        if  km.has_key?(extkey)
          warn "keycode '#{keyCode}' already used. #{km.inspect}" if ! km[extkey].is_a?(Hash)
        else
          km[extkey]={}
        end
        km=km[extkey]
      end
    end
    #pp @globlKeyMap
  end
  def keySeq2Str(seq=@currKeySeq) #KeyDispatcher
    seq.map{|extkey|
      s  = ""
      s += "C-" if (extkey & 4<<16 ) != 0
      s += "M-" if (extkey & 8<<16 ) != 0
      s += (extkey&0xff).chr
    }.join(" + ")
  end
  def onKeypress(code,state,time) #KeyDispatcher
    return if code>=KEY_Shift_L
    dt=time-@lastKeyTime
    if dt > 2000
      if @currKeySeq.length!=0
        statusLine("timeout in keycommand '#{keySeq2Str}'")
      end
      @lastKeyMap=@globlKeyMap
      @currKeySeq  = []
    end
    @lastKeyTime=time
    extkey=code+((state&0xc)<<16)
    @currKeySeq << extkey
    if ! @lastKeyMap.has_key?(extkey)
      statusLine("unknown key command '#{keySeq2Str}'")
      @lastKeyMap=@globlKeyMap
      @currKeySeq  = []
      return
    end
    if @lastKeyMap[extkey].is_a? Hash
      @lastKeyMap=@lastKeyMap[extkey]
      statusLine(keySeq2Str+" +")
    else
      cmd,*args=@lastKeyMap[extkey]
      if cmd.is_a? Proc
        cmd.call(*args)
      else
        send(cmd,*args)
      end
      @lastKeyMap=@globlKeyMap
      @currKeySeq  = []
      statusLine("")
    end
  end
end

class FXWindow
  @@grabWindow=nil
  alias grab_orig grab
  def grab()
    grab_orig
    @@grabWindow=self
  end
  def FXWindow.ungrabAll
    @@grabWindow.ungrab if @@grabWindow
  end
  def getDNDText(src=[FROM_SELECTION,FROM_CLIPBOARD])
    txt=nil
    src.each{|origin|
      dtr=nil
      @txtDragType.each{|dt|
        offeredDNDType(origin,dt) and  dtr=dt and  break
      }
      if dtr
        txt=self.getDNDData(origin,dtr)
        if txt
          txt=txt.gsub(/\0/,"").sub(/^file:/,"")
          puts "getDNDText #{txt}"
          yield txt
          break
        end
      end
      if ! txt
        puts "getDNDText discard"
        pp inquireDNDTypes(origin).map{|t|$app.getDragTypeName(t)};
      end
    }
  end
  def dropConnect()
    fxobj=self
    #types = ["TEXT","STRING","FileNameW"] #if types.length==0
    #pp types
    # @txtDragType = types.map{|t|$app.registerDragType(t)} # "text/plain"
    @txtDragType = [FXWindow.textType(),FXWindow.stringType(),
      $app.registerDragType("text/plain"),$app.registerDragType("FileNameW") ]
    #pp "@txtDragType:",@txtDragType
    dropEnable()

    connect(SEL_ENTER){|sender, sel, event|sender.setFocus}
    connect(SEL_LEAVE){|sender, sel, event|sender.killFocus}
    connect(SEL_LEFTBUTTONPRESS){|sender, sel, event|
      getDNDText{|txt| yield txt }
    }
    connect(SEL_KEYPRESS){|sender, sel, event|
      if event.code == KEY_v and (event.state & 0x4) != 0
        getDNDText{|txt| yield txt }
      end
    }
    connect(SEL_MIDDLEBUTTONRELEASE){|sender, sel, event|
      puts "SEL_MIDDLEBUTTONRELEASE"
      # acquireSelection([@txtDragType])
      getDNDText{|txt| yield txt }
    }
    connect(SEL_DND_ENTER){|sender, sel, event|
      puts "SEL_DND_ENTER"
    }
    connect(SEL_DND_MOTION){|sender, sel, event|
      #puts "SEL_DND_MOTION "+ inquireDNDAction().to_s
      pp ["SEL_DND_MOTION @txtDragType:",@txtDragType,inquireDNDAction().to_s,event.target]
      @dnd_from=nil
      @dnd_type=nil
      [FROM_DRAGNDROP,FROM_SELECTION].each{|from|
        @txtDragType.each{|dt|
          if offeredDNDType(from,dt) 
            @dnd_from=from
            @dnd_type=dt
            break
          end
        }
        break if @dnd_type
      }
      if @dnd_type #offeredDNDType(FROM_SELECTION,@txtDragType)
        acceptDrop(DRAG_ACCEPT)
        # dragCursor = getApp().getDefaultCursor(DEF_RARROW_CURSOR)#DEF_DNDCOPY_CURSOR)
      else
        [FROM_DRAGNDROP,FROM_SELECTION].each{|from|
          pp ["discardDND2,inquireDNDTypes:",from,inquireDNDTypes(from).map{|t|$app.getDragTypeName(t)}]
        }
        acceptDrop(DRAG_REJECT);
        # dragCursor = getApp().getDefaultCursor(DEF_DNDSTOP_CURSOR)
      end
      setDragRectangle(0,0, width, height,FALSE)
      0
    }
    connect(SEL_DND_DROP){|sender, sel, event|
      pp [ "SEL_DND_DROP",@dnd_from, @dnd_type,event.target]
      getDNDText([FROM_DRAGNDROP,FROM_SELECTION]){|txt| yield txt }
    }
    1
  end
end


#class FXApp
#  alias beginWaitCursor_orig beginWaitCursor
#  alias endWaitCursor_orig endWaitCursor
#  def beginWaitCursor
#    beginWaitCursor_orig
#    @waitcurs ||= 0
#    puts "def beginWaitCursor @waitcurs=#{@waitcurs}"
#    @waitcurs +=1
#  end
#  def endWaitCursor
#    @waitcurs -=1
#    puts "def endWaitCursor @waitcurs=#{@waitcurs}"
#    endWaitCursor_orig
#  end
#end

class FXPseudoTarget #module Fox
  @@app     = nil
  @@parentw = nil
  alias onHandleMsg_orig onHandleMsg
  def onHandleMsg(sender, sel, ptr)
    return onHandleMsg_orig(sender, sel, ptr) if !@@app or ! @@parentw


    #weiss der geier warum windos dies hier braucht ??
    #ohne endWaitCursor fehlt manchmal der waitcursor im repobrowser
    @@app.endWaitCursor 
    doWaitC=false
    selstr=$SEL2NAME[FXSELTYPE(sel)]
    #puts "FXSELTYPE #{selstr}"
    #doWaitC=true if selstr=~/COMMAND|EXPANDED|BUTTON|SELECTED/

    @@app.beginWaitCursor if doWaitC
    #puts "beginWaitCursor"
    begin
      #timeout(3){
      onHandleMsg_orig(sender, sel, ptr)
      #}
      #puts "  endWaitCursor"
      @@app.endWaitCursor if doWaitC
    rescue Exception #SignalException,StandardError
      #puts "  endWaitCursor Exc"
      @@app.endWaitCursor if doWaitC
      puts "rescue from"
      pp $!
      FXWindow.ungrabAll
      ErrorDialogBox.new(@@parentw,"Main Loop",$!).execute(PLACEMENT_OWNER)
      #retry
    end
  end
  def FXPseudoTarget.startExcCatcher(app,parentw)
    @@app,@@parentw=app,parentw
  end
end 

$SEL2NAME=[]
Fox.constants.grep(/SEL_/).each{|sn| si=eval(sn)
  $SEL2NAME[si]=sn
}
class FXWindow #module Fox
  def dumpTree(lev=0)
    w=self
    idt="  "*lev 
    printf "%s%s \t%s@%d,%d+%d+%d\n",idt,w.class().to_s, (shown() ? " ":"!"),
      w.width(), w.height(), w.x(), w.y()#,idt,s
    if w=getFirst() and w != self
      while w
        w.dumpTree(lev+1) 
        w=w.getNext()
      end
    end
  end
  def findChildByClass(cls)
    #puts "#{self.class().to_s} #{self.class() == cls}"
    return self  if self.class() == cls
    if w=getFirst() and w != self
      while w
        ret=w.findChildByClass(cls)
        return ret if ret
        w=w.getNext()
      end
    end
    nil
  end
=begin
   usage:
     b.watchAllSels("SEL_UPDATE")
=end
  def watchAllSels(*excludes)
    excludes.flatten!
    excludes<<"SEL_UPDATE"
    selNames=[]
    # $name2sel={}
    Fox.constants.grep(/SEL_/).each{|sn| #si=eval(sn)
      selNames<<sn
      # $name2sel[sn]=si
    }
    selNames.reject{|sn| excludes.include?(sn)}.each{|sn| si=eval(sn)
      connect(si) { |sender, sel, val|
        puts sn
      0
    }
  }
end
end

class FXTopWindow #module PersSizeWin
  def persSize(key=nil)
    key||=self.title
    key="PersSize::"+key
    self.x,self.y,self.width,self.height =self.getApp.reg.get("#{key}:xywh",[self.x,self.y,self.width,self.height]){
      self.minimized?() ? :DONT_SAVE : [self.x(),self.y,self.width,self.height]
    }
    
    # app.addTimeout(1000){
    #   # ab fox 1.6 : gehts ohne tricks unter linux. unter windos??
    #   # ab fox 1.6   gibts getWMBorders(), kann evtl. benutzt werden
    #   
    #   #die x u. y werte aendern sich nach configure um die Rahmenbreite 
    #   #linux u. windos verhalten sich dabei etwas unterschiedlich
    #   #Wir berechnen hier daher den Offset-Wert zwischen den  init-werten und
    #   #dem Wert der sich nach dem Aufschalten einstellt.
    #   #Achtung! versch. Effekte erzeugen manchmal unsinnige werte daher
    #   #die if-Abfragen
    #   #puts "#{Time.now}: selfx #{self.x()}, selfy #{self.y}"
    #   @posBugDx-=self.x();   @posBugDx=0 if @posBugDx.abs>50 
    #   @posBugDy-=self.y();   @posBugDy=0 if @posBugDy.abs>50 
    #   puts "#{Time.now}: @posBugDx #{@posBugDx}, @posBugDy #{@posBugDy}"
    #   place(PLACEMENT_VISIBLE) 
    # }
  
    place(PLACEMENT_DEFAULT)# Achtung! x,y geht nur wenn show(PLACEMENT_DEFAULT)
  end
end
class FXSplitterPersSize < FXSplitter
  def initialize(key,*args)
    super *args
    @persKey=key
  end
  def create
    numChildren.times{|i| 
      setSplit(i,getApp.reg.get("PersSize::#{@persKey}:w#{i}",getSplit(i)){ getSplit(i)})
    }
    super
 end
end

class FXMainWindowPersSize< FXMainWindow
  def initialize(app,title,icon,miniicon,opts,xDef,yDef,wDef,hDef,*args)
    super(app, title,icon,miniicon,opts, xDef,yDef,wDef,hDef,*args)
    persSize()
  end
  def close(notify=false) #only fox16
    #puts "FXMainWindow closed"
    #l,r,t,b=self.getWMBorders()
    #puts "getWMBorders=#{[l,r,t,b].inspect}"
    app.reg.saveAll
    super
  end
end

require "fxText2"
class ErrorDialogBox < FXDialogBox
  def initialize(owner,where,err)
    super(owner,"Error in #{where}",DECOR_ALL)#, *[0]*10)
    #persSize(owner.getApp,"ErrorDialog",10,10,500,500){|x, y, w, h|
    #  super(owner,"Error in #{where}",DECOR_ALL,x, y, w, h)#, *[0]*10)
    #}

    txt=err.asStr.sub(/\A\s+/,"")#remove leading linefeeds
    t0=txt[/[^\n]+/].sub(/[.!?]?$/,"!")
    t0=txtWrap("","",t0.length>80 ? 40 : 30,t0)

    #txt=err.hierStr+"\n\n"+txt
    txt+="\n\n"+err.hierStr #+"\n\n"+txt
    l0=FXLabel.new(self,"",iconFromDat("error.png"),LABEL_NORMAL|
                   ICON_ABOVE_TEXT|LAYOUT_CENTER_X)
    l1=FXLabel.new(self,t0,nil,LABEL_NORMAL|LAYOUT_CENTER_X)#| JUSTIFY_LEFT)
    #l2=FXLabel.new(self,$!.asStr,nil,LABEL_NORMAL|JUSTIFY_HZ_APART)

    f3 = self#FXHorizontalFrame.new(self,LAYOUT_BOTTOM|FRAME_NONE|
    #                  LAYOUT_FILL_Y|LAYOUT_CENTER_X,
    #                 *[0]*4+[5]*4)
    FXButton.new(f3, "&Ok", nil, self, FXDialogBox::ID_ACCEPT,
                 FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|
                 LAYOUT_SIDE_BOTTOM|
                 LAYOUT_FIX_WIDTH,0,0,100
                 )
    more=FXButton.new(f3, "&More Info", nil, nil,0,
                      FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|
                      LAYOUT_SIDE_BOTTOM|
                      LAYOUT_FIX_WIDTH,0,0,100
                      )

    l2 = FXText2.new(self, nil, 0,FRAME_SUNKEN|
                      TEXT_WORDWRAP|
                       FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y,0,0,0,0)

    lpos=0
    txt.scan(/(\S.*):(\d+):in/){
      m1 = $~.begin(1)
      m12= $~.end(1)
      m21= $~.begin(2)
      m2 = $~.end(2)
      l2.appendText(txt[lpos...m1].unpack("C*").pack("U*"))
      p1=l2.length
      l2.appendText(txt[m1...m2].unpack("C*").pack("U*"))
      p2=l2.length
      lpos=m2
      l2.addCmd(p1,p2-p1, [txt[m1...m12],txt[m21...m2].to_i]){|sender,sel,event,arg| 
        puts "edit #{arg[0]} #{arg[1]}"
        edit(arg[0],arg[1])
      }
    }
    l2.appendText(txt[lpos..-1].unpack("C*").pack("U*"))
    
    l2.hide
    dw,dh=self.defaultWidth,self.defaultHeight
    
    more.connect(SEL_COMMAND){
      #l1.hide
      more.hide
      l2.show
      #self.resize([self.defaultWidth,300].max,300)
      self.resize([dw,800].max,dh+300)
    }
    #@bind=binding
    #begin
      #require 'ruby-debug'
      #Debugger.start
      #dbg=FXButton.new(f3, "&Debug", nil, nil,0,
      #                 FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|
      #                 LAYOUT_SIDE_BOTTOM|
      #                 LAYOUT_FIX_WIDTH,0,0,100
      #                 )
      #dbg.connect(SEL_COMMAND){
      #  eval "debugger(1); puts 'debug stop'",@bind
      #debugger(1)
      #puts 'debug stop'
      #}
    #rescue LoadError
    #end
  end
  
end







=begin
 Extension of class FXRegistry
 Features:
 - automatic type handling
 - get, set and defaultvalue handling in one single method

 usage:
   w=$app.reg.get("FileViewer:width",300){self.width()}
 
 automatic save at exit:
   at_exit{  $app.reg.saveAll() }
=end

require "yaml"
class FXRegistry
  def get(key,deflt,&rdValBlock)
    if !@regTab
      @regTab=[] 
      if Fox::fxrubyversion() =~ /1\.0\./
        at_exit{  saveAll() }
      end
    end

    sec="global"
    sec,key=$1,$2 if key=~/(.*):(.*)/
    begin
      v=readStringEntry(sec, key, deflt.to_yaml)
      #puts "#{v}=readStringEntry(#{sec}, #{key})"
      
      ret=YAML.parse(v).transform
      @regTab<<[sec,key,rdValBlock] if rdValBlock
      return ret
    rescue  
      clear
      puts "registry #{appKey}:#{vendorKey} read error key:#{key}, deleting registry"+$!
      sleep 1
      retry
    end 
  end
  def saveAll()
    @regTab.each{|sec,key,rdValBlock|
      #puts "writeStringEntry(#{sec}, #{key}, #{rdValBlock.call.to_yaml}) "
      ret=rdValBlock.call
      writeStringEntry(sec, key,ret.to_yaml) if ret != :DONT_SAVE
      write() #to disk
    }
  end
end
SOME_ICONS={
#cd /home/husteret/bindelta/icons/; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' mini*.png but12x7*.png
#cd /home/husteret/work/SfcUtils/svntree/stuff; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' flag*.png
#ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' th9*.png
  "th9x-icn-128x128.png",
  "89504e470d0a1a0a0000000d4948445200000080000000800806000000c33e61cb000000"+
  "017352474200aece1ce900000006624b474400ff00ff00ffa0bda7930000000970485973"+
  "00000dd700000d89016610eba20000000774494d4507db0a1b16191d9928947000000019"+
  "74455874436f6d6d656e74004372656174656420776974682047494d5057810e17000020"+
  "004944415478daecbd79b8a55759e6fd5b6bbdc39ef799873a35cf554955261208092421"+
  "2088b320d20e8d76b7ada8806ddbdae0a576a3a2d80a020af82128ca1420cc24cc211319"+
  "aa1252494da9793cf3b4e77758c3f7c7bbcfa9aaa442b03f097cc07b5de7aae4ec5367ef"+
  "f75dcf7a9efbb9effb59259c733c5397738e485bf2bee287d7f7c6259fe9370c94fcaede"+
  "f0f901ef006bdd85df7b0637c4f7c225be1b37ec9c4308f15d7bdfe39373fceddffe9d7b"+
  "f8fe47c12ae69a93dc74f3f3f8eb37bd51fca065a767703b9e0bb4efc6e22fbdefc47c9d"+
  "1ddb37b964e1307ff09a9fe03fbefc527efce64bf9a777fe0d1fbae5a33f58db1ff09ed1"+
  "f517dfdd9b75ce31da57e1ba9b5ec4d1d3a7e8e89833d3a7d8b5ff0856783ceffaebc50f"+
  "5a003c7325c03910e2bb1e00420866169bbceef77fc77dfd739fa751af73c935cfe2b937"+
  "bc84b7fcc9eb7f1800dfcf19e0fc20b8e7c16f1efedaa73eb971dd862d8c6dddc40baebb"+
  "a6fb2cc4773b4ebf4f31c0f7c8435dc21f9ff8f46736fee42b7f9e17bef8263efe89cf9d"+
  "f7fa0fdbc0efdb6b29db7df11bf7bb4f7cf0bdac5a31424f5f9533470ff037fff4612784"+
  "f8816b0371cefd407d8dcfccd13732eadef1576f75ce59e79c757fffeef7b89e9111776a"+
  "72e607ee79fcc06580bfff877f742b06027ef37ffc265313134c9e39c9d6adc348d3e68e"+
  "bbeef9611bf8fd7ee5f2799c06611de3674f522a54989f9da1d38e504af2c300f83ebe26"+
  "e717989c9e666cf5308feebd97f18971fafa0798a92d323cb286f1c9395263f17f800241"+
  "fc20819e37bff3ddeecfffd7eff3dc6baf61c386cd2834a9d1d43b09274e4db267d72ede"+
  "fb814ff0f33f7ab3f86106f83ebc8e9e9a444a9f540bacf049224d6a246922e8b43ba446"+
  "6392f8876de07786077217fcf9ddb8ea8bf3789e422a1f81c3188b13022144f6a91cb45b"+
  "ad2e60fc6100fc3bf340028d453cc38c907170cfeebd873ffad92fb96feedd47ce2fe0ac"+
  "a6d36e111b8b730221051e02cf2f72f7ee7d1c387e16272ee40e7e8801fe3fedfe8c0874"+
  "5840229e215de0ccd42caf78d52fba23071fa098cb51a954a8f45608c38020f0f1508043"+
  "2945145b5aed98b9c506b5f97944d0c3dfbce5ef79c54b6ef8fec603cf14e1609dc35a8d"+
  "b1f6997b4f6b49b5e6c1bd07df54e9eb77dd5874ca53aeda5f7532089c0af34efac1f26b"+
  "80bbf1253fe64e4d4ed18a92ef7b22e819eb02dc796ad03395011aed883ffcabbf70effa"+
  "dbbf24a702fa2a55f2a512522994a7905262adc3688bb28266dc41b73ba416b6ecbc8c3f"+
  "fae33772f3b5577d7fcb03cf6cc4599cb3cb36ac67eaeb9b8f1fffd157bdf6f79677785f"+
  "ffa01b1e5ee1c27cd1e58b6517e60bcbaf49a9dc2bfef37f76fffae9cfb889c506c6ba67"+
  "fcf37edf650087432070ce642050c8672cb897d4bf2fddf90df7e21bafa33234c08d37dc"+
  "486f6f2f674f4f10e602e2b8cdfe038f337efc3883ab37307df28838f7f7e17b46cafcff"+
  "3311b414044b2dd67732af9ebff07ffc7fdeea6ef9c847f08b0115df63607088d19121aa"+
  "e532488505da514c6b6e8e89a905e6ea750ad51ed6afdfc0fbfff6cddff78490f70cad3e"+
  "882c081c0e89f877dd55da41addea0d56ab1b0b8787daddeb83d49e2d2c193137cf4c3ff"+
  "42488a948a62a544b1eca194c5b9942050a024562a7015863d47ea2266674ef199bdbbf9"+
  "a7e73dd73dfbb21da2b75aa1522ea3fc809c124f157519a770e1b7bee7fd05ffce19205b"+
  "690708778ef459d6d905386790423d6d005cece1596b99ad35d9fdd841f7c89e4779f09b"+
  "7b786cefc3cc4e9c246eb749534de0fb8432205f2890cfe728f45418ecedc52f14290621"+
  "c562115f4118784895c3184b278e89d288386a525facd36947cccdcf313d33471ca718ad"+
  "714e53e9e9a1d4bf924b2ebd94ab2edfc1a5db2fe5ca4bb789c1fe5eca791f2525088170"+
  "dd7c2740db73a5c493e2295be427ff9f7b1293f23d1e000e9cc0097701d9333d3ec5a9f1"+
  "99d7b75af36f9a9f9de0a69b5f2c7a7a7ab89847ec6276f107f73efef643fbf7bd66626e"+
  "9ecfdefe050eec7d84fe6a89de9e3e7a7b07e81f18a4542e91cbf9844180e7fb04be40ca"+
  "acc797d2c3f3b344a784443a07b29b83a4cc82d258acccdac6ec3e1cce419a3a8c71e834"+
  "21d59aa893d0ec24345b4d66a6a6589c9f6366768656a783108a17dcfc12defab6b788d1"+
  "a27ad222f3145678d77d6ed94b06501765509cfbce58d5beed0078ba7496bdee48930e6f"+
  "7deb5bdd830feea23ebf4014d73970e408b3334d00def7cfefe7575ff5cbe262371469cb"+
  "473ef631f78fef7b3f05bfc05597ede4b22d9bc815426eb9e503dcb3ef11d6ac594db5da"+
  "cbaa9563148a05c25c8ec0f7f197494d07ca470889541e028b541229159e52f842609d7d"+
  "02d5eb4851d9dae3b0462384c51a873516a4c3590b189cf4b30593129368daed36b37373"+
  "8c4f8c73e8e05eaeb9fa7a5ef68a5f63667a0697b64875c4739e7dd55f5c7dd98e373c55"+
  "9003ec7af09ec35fbde38e8dbaa3191e1a66786488defe01366ed92a464746be63b314c2"+
  "b9b41b75e2496968b955104b5ebaa7ff00ed28a2a75476a9d119d72cc15a50bec0a48edf"+
  "78f56ff28e77bc4d78ca3baf3bc888a2dffebddf77ef7eebdf0070e5153b59accd73fcf8"+
  "198484555b3750a9f4910f03fa8706593d3646b954225f28a2a4447603ca68cd915367e9"+
  "2d291c8240680c0a2b14be742829babb5181530825b046a39024388c3108e148ac4fe02c"+
  "759bd01b04c8b048bed887272d4a0aac7344a9a1d96c323b3bcf99b367a835e6499bd3dc"+
  "fc9c6b195e31c2a6cd1bf8f82d5fe1a31fff38d7bfe0663e7ecb2d6278a0ffc267dcfdaf"+
  "5f79d52fb9f7ffeb07b3f855d0d3eb512e8ed26ab4f9a33f7e03af79ddef7e476a80776e"+
  "f1dd05b5e6c911f7ad11fcd2cfe7c3809b5ef842bef4c52f5c1000d8ece71edabd8b34d5"+
  "2825112e4bc142086af506ef7ec7df01b07af51813d3b394cbfdf4f44754fa7b2815aa48"+
  "271142e04981ef493c2990d80c5476015812c7149460d7d7ee62dda62d24a9264d3af81e"+
  "e03c8c0a70ce920bc2ee6898a5d36991343b44587cdf271704983421f0421617161859bf"+
  "8ae1d1958445bb7cf3ce39040e675df7d138a41310f6b1e7f153ccde7b946d972ef0c043"+
  "0f532ae5b8e76b5fe5fa9bae73871f3b282eb691eebcf3eee565f07d854e2427664f03d0"+
  "6c76be936290392f0ec5059cddd2a2c69d0e93674f6274961ab988a22784588e8ee75c77"+
  "dd05a501c018875282a3470fd3eab4bb90e1dcef79f091c71c3a936283503171769c4307"+
  "1f23cc8554ca158458d2120452080402a5d479a90ca4cc02a46335a552915402c212e442"+
  "849f27572c912ff8944b39fc40e1795e562af0088a657a7bfb191e18220c0bf87e012315"+
  "61a140a7ddca02355bf2e5fb177495c4257a5b64db69b6d56662ea041fffc03f72faf831"+
  "d6af5f03c0a9e34778fcc8e1273dbb4ebbc38993a7963789358e763b5d7efdb2cb2ffb0e"+
  "b4cad997bc107474d7305b51d2386661769689b367e8b45b1c3af0c8eb41e22ec818e7c1"+
  "1921104ef0ac2b2f5f5e1c6b2f4c22f3f38bec7ee0012784442030367ba4773fb80b64c6"+
  "11b55a6d8494f48f8ed03b34801364a0cee92ec72f71c243a330d2c7080f2b2075608424"+
  "07c41ee45c0ee9f948a5088210e181700a6304519412471196949efe227dfd258af90063"+
  "627c99e0fb02ada193c44449021802a5c1098c5320140e8b3529c618ac75089395340fc1"+
  "d8aa118646473219ba1393cb05e88ee5c091134bca73b704c283bb77b9f371beb3166d1c"+
  "5ef7195ef7fc6bc5b7c3e6ea34c61a73c1f79fb2f6674913ef89295f08c123bb77bda1dd"+
  "5cf8b36b6f789194ed166b366c444ac989a37bee6e356a14cbd58be081731960fbd66da2"+
  "542aba5aad8e73e0c9ac1d323afb40bff707afe7831ffea83b74f43833b505daed0e51a7"+
  "49eff03061be881704aced1b442a904a811038679142763f781634d689e5303c0f2f935a"+
  "45a8a16122bcb48df47db08ed4817216630cce46047e1e2b04a9b6a449074f7a6897f905"+
  "1b6d8d483a741c14a5444a895412abdd93cbe3529603dc52961030383a4a9a3a1aad1661"+
  "d1c349cb273ff949aae592dbb271bd18ec1fc0f714bb77ed5a2e97c682f2a0bf5a6166ae"+
  "c18a9111aae5fe6f0de484c0989443fbf7bc6dc5aaf5af6b2cd61959b9123f089e163c5e"+
  "40041d79fc000f3ff80dbdedd2ed5f7ad73bfe37db76eea058e8a5beb8484f5f1fabd66e"+
  "bbe7c49103d76fd8b2f39e2eb373411c082168361a1c3a74c849a928140b148b65aa3d21"+
  "d2cfe17b3e9e97275601274e1fa5d45f65edda3182528e422e473e9f4706215e1092f325"+
  "b77ffa53b46383500a670c56827336c3019e873cafaf160e4417e041440c0c3a41aa3c70"+
  "16674d86ae24d9429b732b271d044108088a52605c8ea19c636aaa4dced8656fc0f940d8"+
  "5de039b06863d0cea18d4500d279e025dcfcd21fa150ac526b2cd0acb5d8b7ff00bffdda"+
  "d712755ace0f3dcac522b5d93abdc303c48d163a4df13cc3e4741d809b5f78e353332ee7"+
  "01b2667d8e200cbeb0b8388d49edc8a30fdd37b172cd06912429c55299be81818b623b6f"+
  "e9d70921e8edebe765affc8f9ef27d5ef37bbfefdef2a63f767ffad7ef1151a749bbd522"+
  "0c4384b4a3c6188c35cccc4c73f6f499db8e1d3ffda30f3dbc9bafdd7107c7cf8e532a15"+
  "587fc956fafb07a8542ae4f3458a853cb9d02797f709030f25144a4aacb3a4c6629dc318"+
  "0d2645a41ae33c0ad532ed9979ac350832e52eebd50581e713882cdd2ed51929c47209b3"+
  "c24710e39c05e74120f11018e37046235588f425d24a1cd089dae48390284d010d426054"+
  "81503551d2c7daac8bc1996e9a76180b2992d418b43528d725bd706867c9fb01abc686e8"+
  "e9ed41a931ac315827898d4327296992d08e23daad168d4683a45e238e3a345a4dda8d16"+
  "53d3334ccdd5f9e0073fe056af5ec9aa556bc4c8e828b930b75ca697aebd8f3ce4765cf9"+
  "2c51ae0c20849c9c9d9c118b8b677fee816fdcf9d1ad5b9f7dd79993a76ed9b065cb3b8b"+
  "a5e2c53240f68bfa078758989ba7582a73cdb53f293e73ebadeeec9993582476768eb1b5"+
  "eb31f8777feab39f777ff807bf8f5f2ad23f344cb554a2d453e5aae73f9fe7e773e4f201"+
  "4a6568dd1983d1068b016bb15653abb5e974b29b6e361b74da119d4e8734d1544a25b65d"+
  "722961a148215fc2d9d96ec1caeaabd68628ea10753af84ae1053ea24bfad0651c53e791"+
  "138eba859cf0b09e02ad49c85a120b14821c6947d3919a8282423e8fb32094a0556f6362"+
  "43250c696881a7bcae8825ce91362eeb208cd6cb75d791a99d0e815412df0f0048a28846"+
  "a381d69a7cb18cf0fcece1fb82be5c89be9e0a4a8d11063e4af944b1266ab569b75b2c2e"+
  "ccf3b18f7e94c95a93466dc1b51b7536ad5ec54fffeccbf9d11fff09b176ed1a16e72668"+
  "359b54aac338eb981a9f6478c5081ffc97fffdd11b5ff80a77c98e2b6ff8ccad1fb0b55a"+
  "edef9ef7829be4454bc0526ae8edef234d3a80cf73af7f3e9ffff487dddbfeee9dbcfc67"+
  "5ec1ce4b2f6772fe245fb8f3415ef4933f4ea15442290f5f9a6558a871743a0d6ab57992"+
  "561b9326a489a6b1d8268e236acd0893a4b493089ca0502c81c9da29cf0b98692d30bab2"+
  "c670a1483e5fc8b0767761974ef430daa0758a94922eb187940aa514ce592ad53ef6366a"+
  "34ce4e52f0032c199b679180c4588d3606a70d06818fc55887b19a58a72807da5aa45484"+
  "c51c2f78f1c6ece711ddf7745daedb42d77862ad5d06830881b002cf5328256936355ffb"+
  "eadde8d4e0f912e10bf2853ca1ef5308437a7a7bf0fc80a05024e77be48b65f2f9227eae"+
  "879e813ebc8d1b7146133b682609cd468bafdc771f9ffaece7dc96b56bb9eeda1deec75f"+
  "f63201b03037cfdec7f658442cefbef36efed36ffc897416366f79d6cf6fbf6ce7c72ed0"+
  "2d9c3b17004bc6c8fbeefa9abbe55f3fe02eb9748378c14ffc07f2d57d5cfabcebf9d43d"+
  "dfe0d123c7dcea75ebc4ceab9f8b6f53dd6ed5f57c3dcae976c3b55a4dd1683469369ac4"+
  "4984148e3475e8d4e24bc98b5ff052766edec1fe33fb583fba8ed1c101824281dd0f3e44"+
  "b998c7f83ed31313f83d05be74c71719181da1582c2c3d63ac1358215016b4eed6746900"+
  "8df202a404211d52c2cce4719e7bc30bb23a6d2d4a29a4c83807db65fb9cb5cbe95a0881"+
  "5c6a84a5c4da2cc50b2c46800acb4c4d9ca57f6425a15a229c1c388d301aa7538475f87e"+
  "80c391c4316847e84bc230c7d989099aed8c2e4eb44174a0598f11169c1078721287c3f7"+
  "14423afc4012e4020607fb29964b94cb7d14021f3f08e82d14e8290de0ad1c432a45b3d9"+
  "e4cb0f3c2c3a2636c3039ba6defce6370e8ac089d7fdd7df762f7cd1cb5db3d6e4f8e4a9"+
  "376dd9b1e30dcb15430852eb08a4b81004ce4e4ff36bbff6ab5c7ac59562a839c77bdeff"+
  "6e16e6eb602437de7c13053f87a76dd25e983975f0f8b1c1f9b9f98a332e16568441a848"+
  "d208ac4059853119751a843e516781bfff87b7f086dff94bbef6955bf8e75393dc78c38b"+
  "d977605f174c79985c0e3f0840a704814fa7d3210c431c026b0c4208ac1538af2b385977"+
  "1e17d0751c1a4bdf401fb82b989e1ac7baec336430c164816332c228a3830dd6640aa5d6"+
  "19d873ce61d3140b58633156932b846cd97649978bc870beec024e476670b1c6a08dc659"+
  "ba8298a3502ca094e4d0d143c88c67ceca8410280452390a391fdff7a8b722e238c2531e"+
  "566be2181ab589eebd6942cf753198607864840d1bb7e00745bcc06368c53a8ecfc6e2de"+
  "47bf3e4ab59fb1d1922b0c14c4801813fff29ef7b92f7cfd1ef7b18f7fec0d034383ddec"+
  "25086406e22f0880c1a1217eebbffd4ffed75bdeca742b61e3ea75f40fad60d437181331"+
  "7ef630678f4fce475173639ca677bee2e5bff4e197bffc95af31c66ecde53c79f7d7be24"+
  "defbde77e250086b5152227cc3c4f80c41c1e71fffe5cfc8157394aabd1c3cbc9f9327a7"+
  "a8547a88a2060363c3c426460a8936110b73b3f4f50de17b8a4e94e284042cd61a8c4d30"+
  "d87348dc5d2896f40f95181cd94ca3be48b3d52289134c9290a62969ac9701a71312820c"+
  "d9177c0f2904caf308028f30e7532af510e48b58e3baa9df2e7325c698ecf75887b50667"+
  "2d699264190b0bc632d03f48ab1131bfb888f42456839422c31a02fecbab7e815ffc8557"+
  "512857387be6249fbaf516aeb9f2d9bcfecfff8266bb81751ebecae4736d2571a34d1a1b"+
  "ea0b0b1c3f7a82200828168bac5c3dc68a15abc5f0c000230337d06ed6c4476fbd9ddec1"+
  "5e1a0b758e8f4f8b3bbefe55f7b33ff70a21105dd5240b65effcb660efdebd239fbfed36"+
  "9e7bcd356cdbb4895c4ed16ad53872f20ce31333d834168aa08c10affd9dd7fdf74daf7c"+
  "f92b7fec6d6f7ffbe30fdd7f6ffe475ef2d2f53ff78a5770f4d0e37ceaf6db70d2a3e02b"+
  "82c0b16edd5aacb12cd6eaa014bde51246282ebf7c07f7ddbf9b4b2eddc9ecec34f97219"+
  "823c0ecdc4f83823432b504a66f5d8f31026c559837319ead6c690efa66f63cfd72c2cc6"+
  "583c2529942a54aa120f899202a7ce3193da7a5d35aeab0c724e11345a67753dd5789ec2"+
  "5add65fb323e30cb225966c13a645702b6980c2062e9eb1de0d0e1a3d88e45793ece69ac"+
  "952897f0dcabb6f39bbff51a1a73d37ce5739fe5639fbe936fee79909327c6a97612860a"+
  "011baffb513e7ffbad04d227ef3b6ebee15a6eb8e105dcffe0fd28693931bec87dbb1ea4"+
  "b5d8e0c4a1938cacec67f5fa8d94ca3de48aeb59985b647ca6c9f0500feb376e7aadcae8"+
  "4c5aa92554024f82b704b06aad166ff8c33f9c088a4576eedc4ea7b9c09e470e31333383"+
  "277da4b5c442b80dca159ded7ffb8eadcf7ad79597effcd481fdfbdebb62201f7de2539f"+
  "e1b22b76525fa8d33738c0dcfc6206a24245a1e4d369c72449cce9d31318ada9f68db0ff"+
  "c0419acd26bb1ebc1f8760dbf66d0825705252ab35b1362608fc0cf49918e5044a5ab406"+
  "a36db7edebba0e9667fb1d46a708e1d0c690a42989b5842aa37d2d1999e41c181963b5e9"+
  "d219ddda6ebb7230994824e4797e06e8fa1a5de66e36a68b4f0c76892b7002d3c51dbeef"+
  "53afd510cae0b0f852609d414ac795575f4ea87c3efcb15bf9cb77be13dff378f6559b78"+
  "e39ffe29bffcb25fa6d13ecbaebbee229001c226d8386162ee2885f28b682c8c53ab2ff2"+
  "b32f7f258d7ac2aac1907a1c70ff63bbd97fe0209b376f61c3c64df4f77854872ea352e8"+
  "e5fff9877f7afb3bfeeeb277049e24500eaf0b66bd259dfa231ff9983b333ec58fffcc8f"+
  "307efa28fbf7ed473a1f2142acd3196de872421ae1ac6d8813470efec6ab7ff5c7a28fbc"+
  "7feae4ba316f4de26f71b9c089cf7fe52b6cdaba9a05d3a6d58ee9a9aea2dd9c274e5a38"+
  "97f5e9a7cf4cd15b5dcde4e40cd63ac6c6c6989b9b254a13cac5009d5a8c35c49d849ede"+
  "1ec627a7414a8cc8d8bcc42ea55edba59b977445c1122d20a5e0c4b1d33cf2f0c36cbfe4"+
  "12c230208a623aed16f30b0be4f221cf79de754c4c4df3c5cf7e8115ab56522c96509e42"+
  "a79aa9a949948097fd875762ac5e0a118ccd0226c591e088d294441b8cb1086330d69118"+
  "cd70df00496a989c9e45588913825400c24359c1e1038f623d4bff501fab868a3466a7b8"+
  "e6f26be82995b962eb06ee7f680a8346388b8962365dbe92bffcabb7f2677ff066be78db"+
  "adc4318c8df6f0533ff152defda77f42a56708f0f0bc2ac78e8f73faec242323fdacddb8"+
  "8ed1d503ecdf779c5ff98d57bb0fbdf73d22d629be5419a1b654383ffe910fb162d56aa4"+
  "329c38769434d6590d97e02981059414cc972a225f4af9f0473fc1effef75fcbcdcf4fac"+
  "f165eaae7cce4de27def7b0feb376e6476fa24ca0b30582627c7d9b061033ae923890d9e"+
  "abd268c6ecdef510699a49c6a74f9f424a491066d4a5b31685646e6696d1d1511edbb71f"+
  "2515ca5a7ca5f0ad0563b2f4dbe5ce8d752045575eb6180d2b57af6660b06f99fb564aa1"+
  "94879412632d5a1bfafb7b78e5ab5e89e785b825f72f3acb20a9234d5254a032fce11c9e"+
  "cb349b0c0758acb36893056c6acc726658bd6a8cc5f93aed24450991790ba445288525e0"+
  "b3b7df43cf1ffd2ebff04bbfc59ffdc5df22754c796005af79edefb2f0f8012ac272e5b5"+
  "37f1a5afdc8a133e77deb98b6fdc7b073ff292177174df17093dcb55cfba8eddfb4e5229"+
  "150911084f2044a6d54451caf8788da99907b8eaeaabd9b27d13b7df763bf7dc7577e359"+
  "d73faffc241e6071619ef523a308208e52a4586aad0c9202c54a09e5244258a2b6473ed0"+
  "62cf9ec3dcffcde3f457068551731c79fc3449348defe5c01a24a094c7e4f8298240b0eb"+
  "a1bdcccc34cea355cf5dfd83fde43d3f4be54a211d341a7556ac5d83effb589791e5560a"+
  "526b49758a35169da65d2792022b904a744d3d8ed3274ef08dbbefa16fb01f2932724629"+
  "45a3d164c58a15ec7cd6d5cccd2ef2c5cfddc6c8ca1519c034169d2634ea0dfafbfb79c9"+
  "4fbc149b66c1e51c18976992d6ba6539d95a833696d4812f25ca59560c0d70f8c0691267"+
  "28481f210ca68bbab5d4d8b0ca2d1fbf8d3851fcfaafbf867cb1872fdc763b274e1c6360"+
  "f34a0658c3953b2ee7cb5ffa2ca884465bf1e043a7f8b19ffa59365ef922f6ee7d8037fd"+
  "9fbf66a0ff12667201d7def4231cfae26db840218442a92c935a24c78e1ce1d9d7afa1b7"+
  "3acca73ff3d9d275d75f8773b29bd5bb044e4b6bbcc0c33989941687c1da5cb68839c94d"+
  "575d43a9189224864a7f95c9a9093ef1e177512e39b66e19e1d183f771766186bc94c449"+
  "4c92a619c0924baa9465f5fa319053d46b2de228e9b2611e03833d8c8d8d1004d943f6bd"+
  "6c27c6511b9c63c5f008e31353682150d9afcc041c27488dcc50adc83878e3ba9494b0ac"+
  "181be6a77feea7f03d8f200c975b462104719c101b4ddf403fbffc5ffe13ca23e30a004c"+
  "8a75964ea4e9c4865ce02390081ca9b520bac7cb5a48e214ad538c49282a85f242a40f7e"+
  "58e1ccc4497256a39d430a85273d700e8503a9485c91cfdff6256ebbfdcbf89e4f2225e8"+
  "14151a365c7639a74eeca75a2ab3d899636ccd28b7defa29eeb9fb4e568ef470f7838fd3"+
  "69b7999e9ae1d77fe377b9ff8e2f53503eda7874748454293e0124e04b0f6734855071e4"+
  "d829526d0802792e03a4694a9aa628e9638c47a9dc47b33e43eab249d94ea7c5873e7d0b"+
  "bea70873215e90c75721effafb0fb27ef37ae6e7e7f9e4e73e4eed73b76170f869f6509c"+
  "b638d3255aa4208a2386463d7afa3561e851c8e7a9567bc81772a46942ad562389239224"+
  "c6f77d4cbb4dad5663c58a158c4f4e77091dd1d5cc2d469b73f5599c53063332d6b0b8b0"+
  "c8fe7d07a8567b32a653429a4624494affc020ab376c627e6e8eddf7dfcfe0f0f03991d6"+
  "285acd16c572912b9efd2cb4ee964321b0b82ef8341863d05a77db40473b4d9151ca9a35"+
  "6324714ca7d3462a81b00e89264d34699ae9fcf97c81befe7eaabd25464757604c57ac32"+
  "0625e0d8ec2c8de619c2be22b98536693d26d13127cf4c30373bcf95573c9b5c2ee4d24b"+
  "2f61e3ea958cf41659b576236726a7b9e3be6fa07c904283ca7c0fd65aa4ccdadbf393af"+
  "07104511c61a848428aab37ee35ac25c012104be1764bab4d058a33036a6d18e889398d7"+
  "bff18f68b61b343a319552896258245fca93cbe5c8e5f278a19fed4a9d8947c6daee020a"+
  "9cd524498ce90239cf0f2814f25dbe5fd36a3588e38491d1512abd09a7ce9c6561b14610"+
  "f85d4f40b600d698ac853b4f9e73d68070482558b7610d85420121335fa09492388ac917"+
  "0b9834a5542af1ece75e47900b9002b435d8d464aa9c1f6401ec1cc6656414c2e184cc4c"+
  "20d6a1538d350e212542297c4fb179e3268230a45c2e1386398af9907c3ea452ad3232ba"+
  "92b05046c88c6dec341749528d540adf9338276836db9838a2a70cd5be326b376fc0b312"+
  "270d712a3051841096c5c51a47cf4ed0e92468d3e1d153a74835e40a053c93a2ad456b4d"+
  "a95cc6930a197834a3f4023fa427804ebb8d4e531edbfb08274f95500adaad98c0cf51aa"+
  "94e8eb1fa1bfaf4421df8be7831419f7add314631d9a6cec4b38505d61298a3a2c2eceb3"+
  "58ab51af35889298344d0041980be9ad56e9ed1ba0b7af8730c82d9b3e94101472826ab9"+
  "271352ac250861c78e4b7864d7439c9d98a47f6890545b8449912e45580ff38413bf8510"+
  "782ac7fce224ad285d367c3a070bf3738cac58c1c8c828f5c5451edbf3082323235d2731"+
  "189d12b7db04618e1d975d4e4cf734adae99cba60684051be37484b016b445e8942baebe"+
  "8cfec13ec230c7cffccc4f2184c45302676cb76574689b059313e0f70f2c3b8a96ba9a62"+
  "b5921965acc5c3a184c07912d9adeb9d469df9b939f2f93c71fcb8518800002000494441"+
  "541c2394255039c2822457cc532d97a9562af87e817c5ea2bc1c4667ab1d47179ed1e001"+
  "c49d08e72c51d44160a954c678de0dd762759d8777efc51f1aa45cea254d22526bcef310"+
  "66762821259d4ec4dccc0c3649c8e542cad51eaa7d03f40d8d740916837002dbbdd954a7"+
  "c471c4c4d971b4d6e472392a3dbdf4f5f66460ab8bf0adc90e72c88539b66cd944a23567"+
  "c627989e99e3e4c9e3dcf0fcebb3bfa35d37b2dd729f9fcfe7d9ba6dfbb2816bf90fb711"+
  "ad53ac31f4f4f470e34d379de313ceb33858ebb2faddbd4f67bb5abff2b04671eaf8147b"+
  "1f3b42abd52097cb73cd35573238982972a94ec9d08941ebec374aa530c6d06cd469351a"+
  "686348ad45290fe5a98c5f3006a335691ce320e3ff7bfb2896cb38da386b09fc8095ab56"+
  "774b52064c8dd6995ee21cce24448d1a53b36789e314ab218923c667e75939baea826ce9"+
  "01b43bed2c3a6df6e0f3f91cadf659def5d7ff4c6f5f95038f3dcad5cfb999ed3bd60302"+
  "636c575c712ccccfb3d8a893cb878c8d8d51cce51052a1d3142d64576cc9da376141080f"+
  "6b0d612ea0582c30343c82d18638ea50afd538363b4d315fa0b7af173fcc656d5597092c"+
  "968b6cdabc09e5e7383d3ece99b3b37ce4439f64fdfa55ecdcb983a191619cb599951b47"+
  "122758299ee479755d049fedbccc478038e729eab23f18a30902b1fcd7a592c471876387"+
  "8fb3f7b1bd2c2c2e20a5a2afb7c265975dc6c0e01052a94c11d41aa714420ae224a15eaf"+
  "11773af89e47a95866606818cff7117e90954963ba730c59b0f84a912429894ea9b75acc"+
  "4ccd604c4a18fa54ca7db834cd94c825dfa59248e1f0a560ffbe7db41a35365eb28d35eb"+
  "7672eb473e84b386a8d3ee7a3a9f10008d66ebed4276a54e24d54a91c7f71fc83e7ca743"+
  "d4b68c9f3dcba597adc59a00a52cad668b93278eb172d56ab66fdf4ea7dd44084747a768"+
  "93d0acb7989b9ba75e5ba4dd6a77c19a220c030aa5806ab58f6a4f0f412e475e29423f60"+
  "687008dff7999b9ee6d0e387a854abf48f8c642d9c1078618152c5b17ec36a9c4b883a29"+
  "b57a8b63c7cf70ecc469464786b9e2eaabe9ef2fe39c607661815633037dd6389c7118db"+
  "e5f0b5c6d804cff391d20314be5220255258942728960b0c0d0d22a426890c478f9ce081"+
  "dd0fa2bbb6b052b94ca99067e78e6df4f554c9e502101283c40948d294f9d9195aad1623"+
  "a323ac181d41279a54679c42a71361a3b86b4517199874d98a06be8feab6ad3dc512a658"+
  "c5f703daad26a74e9da0582ad3dbdbd7f52880b40e15e6b8eb8b773073760f4a96b9f7ee"+
  "6ff0ead7bd9abede5126674fe20b49ead22797804eabf91ad17dc85849be90e79a675fc7"+
  "c4c42cd162821321d73ce76a9c7138a739fcf82146578cb1e3b22bb27629498952c7f1a3"+
  "c73876ec24674f9fa25dab618deeee3677dea13bd9912c4208a4ef53191862ddda75ac5f"+
  "bf96b1952b702454aa552a3d55e6e7e6d8f7e81e46c756d2d7df8fe7f9140a79a4946cdc"+
  "b899c3878f305c2860ada5d58c989c9ce2f6cf7e9e4229c7f0d010db2eb984556b4648e3"+
  "84384ee974629224cdb293f6b026eca666411006f8be4f1004e4f3217e2031c6b26fef5e"+
  "8e1f3b49bdd6248e535410d0d7d78bef0b92a4cd8e9d3be9ebeda190cb65c1a414d6594e"+
  "1e3e86758635eb363032320c4ed06cc51823585c58e4ece9534c4c4e3237bb40bb51c7e8"+
  "3803e208825c8e42a148ffe010c323830c0e0e30343282b516cff358bb713338c7c49933"+
  "489989780889e709ce9c3cc9fcec22ab5679e8d4d268ce902f1496cba0d1fac99341b77d"+
  "fe73eebffeceef50ad5430065efa632fc6170a291df5661b552e9147d36a36981c9f62ed"+
  "c64d04b9009da4b4da6d0e3e7e9447bff94de62727b14f78836ff70a8b1556ad5fcfa53b"+
  "b6b17af5185e779aa7d96e7160df7ecae512ebd66f224d538cd12449caf8c40493535378"+
  "4aa284404a8f56bb43bb95d06a3448754aa15064687880befe0ac5628162a1422e172e89"+
  "ffcbcc639224c4494cabd96676669eb9d905e6e7e731d6e07901b94248a55c44f90a6b15"+
  "51dc61ddba55ac5dbd96c0cbc6cf8220a4dd6a70ecd8614646871959b12a3b14c7395aad"+
  "88e327c6d9b7670f331367895bb56ffbd9e48a05fa0606d8b8651beb366c6060b01fe71c"+
  "7e1052af2fb23037cbe0e0007ee0d3ae6beef8e2e7999b9f65f5fa95dcf8c21772e6d422"+
  "7b1e7b089b5a86c646f9caa73e2972b9f0bc0cd08932a60b472e0829160274a4b1588ac5"+
  "8cd55b5c5c607161914b765e4e27496875528e1f39ccbd77dfc5fcf8d4d3b856412889d5"+
  "16e98965f9d639b75c9be3569d238f3dc291037bd9b2f332aebaea0a868606c8e70b5c71"+
  "d5b3d8f7d81e1e7d640fdb2fdd819282c097ac5ab986f95a0ddff3c1a4f87e48a95c2608"+
  "05be1f1047298dc51673730bcccdcca3b546776ddc0207323b1dc43a879241d75de46565"+
  "aa9863f3e60d84f91ca62b306993a56f931afa7acbac1e5b41e065a78d789ec7d4c43813"+
  "1367b864c70e0ac53cda58da89e1f081233cf4c07dd4a7c7ffaf3647d46a33de3ac5f8c9"+
  "533cd45b61cbd66d5c79f535944a65f2b922a5b5554e1e799cfe817e4aa5223ff9f29767"+
  "3649e5b0ced0d35fcd68732131da3eb904349b0d8490e01c854271796ac0daac9d6a34ea"+
  "b4db119bb76d2789db4491e6fefbee67cf83bb48a2a7985a11a03c89efa94c15cc05d46b"+
  "0d8aa57c7780234b95c6589cd5b43b7166a6d09ac71f7e88c9f1099e77c30bd8b0610502"+
  "d871f915ecddb39743070fb069cb1642df27d1296b56aee2c489e3e473397c3febf39508"+
  "09c33cc5a2c7f0701f9b588575a0534d9a6ae238cd183c9b1938b201d2acde06a1c2f7fc"+
  "cc7a661c519c10eb9434f19089c6084da21759b36a23811f204406226767a699999de0ca"+
  "ab9fd305a230333dc75d77ddcbe9c7f7d3758a7c8b5d72d1799b275dad853a0fdff70067"+
  "4e9de59a6baf61e3d62d08ad59b36133674f1e433a4b3e5f0227b12e03c07e10a23c1f93"+
  "e88bdbc2175aad6c28c542b952c21a8323eb755bad268b8b75d66fda4294462c2cce73ef"+
  "3d0f70f0a13d17fdc45275bd705e368c2984407912a5047ee051c8154058b4035f78d991"+
  "31dac30f7ce22421ee24580db5c971befcf9cf507bde73b9fcf2ab10d672c98e4b78f491"+
  "473879fc381b366cc4f314d572897c2eccc819e91116b2f16fdf97148a0502a9f05466e6"+
  "c8ecdd12bddc932f6194ccec29e512a3981157696cf0bc0499c4489974e5534b3e976760"+
  "6808491670737333ccce4eb173e70e84b068e778fcc009eefcf21769d7e79f7acd65e667"+
  "140294a78863938dd299a70f86e9b367f8c26767b86a769aab9e75256168195bb3813327"+
  "8e52719642a18ac5ebce4142cecfd349ebcba696e500e8743adc73dfbd789e426bc3c8e8"+
  "285a776548a7999a9e62ebb6cb897544a3d9e2ee7beee7d0c38f3ee527b4d665f4a8b3e8"+
  "d474fd7619e9a1b5a1566f9d37e695b556a2db5a3a977522b6fb5adcac73df1d77a35cc8"+
  "cecb37e379826ddbb6b36bd783f4d70628572a846148b95c214e1372a18fef49725e483e"+
  "e7239c239fcb65431d5d1a37758e0096851c634c77ae5075ade512eb34c668943420b253"+
  "4484b5d85492a496e1915102cf47a0889384b9b919b66cdd86e7057422c3a14387b9f34b"+
  "5f266e37bee58e77ddd10a974917cb43a759cf796e9ef2290fc6886376df7b3f51d4e6da"+
  "ebae238fc7ca351b3979fc2061aed89da69248a9c987455aadc5ee94f37901303f3fc7c1"+
  "4387500e8c14f4f4f4e19c460ac1dcd4346bd76dc598189dc6ec7ae0010e3fb2f75b1fa3"+
  "e9b208ce7af127df4147ffdb061d75dce1817bbf4eb59267dda61504398f2bafba92471f"+
  "79944b765cc6d4d4148d7a93d9e919a6a726a9cdcf13f801bff82bbf44a552c153b2bbc3"+
  "fcacf65987b386344de94411bee7e1795e1703740745503814ca1a161766b9fd939fa0a7"+
  "bf9fe1d1310a9502bde50ac21aa4e7317ef614ebd66f240c026cea38737afce9177f69b2"+
  "c39c7b42569b27eca46feff99854b367d72348a9b8eefa1b71d63138bc8ab3678eb176cd"+
  "6a9ccb13f88a300c9142d16c379799472104b2dd8988a3084f387261d6fe080c69126375"+
  "964a13633974f404fb1fdd8f33e6193ec62c9bdebd7ff72e16173a382b299672547bca1c"+
  "3d729087773f42d48ec9e58a0c8eac6078cd1acafd0320fc2c1885c0290f2b044849ab3e"+
  "4f3e50e472018540512884f8b902cd7603e509022ff33f28e910d21275da483fc44ac962"+
  "b3cee2628dc7f6ece71b777f83f1f1d3f8bea2542e6171cc2c34b8e7cefb9e7ef1ffbd2f"+
  "63d9b7671f070e3d8ef10441e891cff5b0383f8f14991136c8852418ce4e4ef2e1cf7c62"+
  "f95f47918b0b73ef8b93048ba0a752059b80549c3c7d9655abd7828366a3c99e6fee21aa"+
  "3fc337b6048eb4666afc0cfbf7ee47a7963435ac5cb99233674e651cbfb5f87e06340ba5"+
  "027ed81d79145d8fbecca67fa62627e8ef1de4f4e42cba1df1dc2baea4ac4244daa6b75a"+
  "a1beb880b15957c0b2fb5751ac96e8ededa5afb797c1be3e8ac522cd7687d3a78eb36ec3"+
  "fa4c14d2b07bd737991d3ffe5d39eb2769b5d9b36b37335313380cc32b56b230d7244d3b"+
  "586b28e70b780ecabec75df7dc8fe97a32e4c4c4e95fd5580caaebc337b4da11d20b912a"+
  "6b0d8f1d39ccccc4e4d31e10a194240882aef34622d512b03a378dfa7f75ec50e6e2e4d4"+
  "c9d3d4eb0d9c95e40b25caa57236d02a417a19785bbd66150303fd28cf2184e94ef13866"+
  "a62619ec1fe4c6e75c4fabd1e4aaed97f28a9fff655e70d30b29e7145b366fc56a4dbb13"+
  "a197ced143e0053e2bd78ed13fd08b4b536c9cd069b569471183c383f87ee631989d9ee7"+
  "c4f123dfd513e566a7a63974f04026532709bd7dc3341bf380a5502e9338452a1cd3d333"+
  "444b7e8c463bc11799cbb5502c82d0346a738c8cacc41a4b278e3873668aa4935e64c5b3"+
  "5a5528840c0c54183f3bb7ac779fbf82411810843ee0883a095aeb656bf405c292730c0e"+
  "f7a3754aadd6c8107ab7160a63a93716183f3b4eb9b205cf83a19115785ec8e0e0305e10"+
  "d068d459b57a0d39a5700eb413042673ed9a3441cf2fb0f392edb8380504674e1c254a23"+
  "eacd055e7cfdf3b8e7ee7ba9cfd718180eb3a116eb08f301ebd7acc3f37ddaad36b97c1e"+
  "9338021f56af588dd512a4e1c0c143b45b8de5d9c1276631813ccfb5cc792653f784ce40"+
  "2085ecb6ca4b86d40c14a4a9ce74866f912d8f1f3dccf66d9be9ed5f4958ce71e6d424a5"+
  "5e43b15ac6a586404a1ab50646a74080a78dce5a050985622e6b9352831f28526759ac2f"+
  "303b3777c176f4c3804ab584d1096962d8b2693d71da44eb99277da6e1d15efafb7ad0c6"+
  "d06836335d5e78480feab53a3ab617fceede9e1e464607d8bbf720f97c481427cccd66e8"+
  "d518c3ecec2c5bc4169c7314f37982d1156cdeb68db8b3c8dcac64a0bf848e07baee9ea5"+
  "e3670c26d54422656a7a8a441b266b7516e7e688a20821734ccdce315faf51f0fde587ec"+
  "ba96b6bee1de4ca62d16e9ebeba5b1d822491af8611e9ca15e8b989e9e62a97ff17d45b1"+
  "54444a8fc0170c0cf473e2c404cd66e38249eaa1e15e9224ed8ee577a7ab5b51e6344ad2"+
  "657978e9f203455f4f9985b916429acc9a96da0b0e77a8d51a4c4f4d51ed19c4531e69a2"+
  "d16942b1585d5649d3b4d5159f40361a8dee838252a988b5102716210dda69e66b0bd4db"+
  "75e89e8fa73c9fd5ab56d2d7536560a0072515d59e325353f3176500a3b66671a145a765"+
  "d1a9c2f7b3c9d62471d88b20dd288ac8e78b94cb25cae5127dbd3df4f65532609c6a1617"+
  "1749930470787ec0f0c828491411c88072a14cb950a1582e2f1d71d2cd22991c1d09c99b"+
  "dffa1624900f736cbbe26a94caa153c19fffe91b492d54aad5e5b16b670dbeef53adf650"+
  "2816a9547b2886017d03bdf4f4f776278034f373359af506982cfbad181b64647890de9e"+
  "2a3dbd55aad5eab28175992ff15c663cd59a288af03c459a6aa2764c14c5179deb4f13c3"+
  "e64dab191e1ec1cb2b064607191c5b85f4bcf3f690646a6a12e752841494ca651616e691"+
  "9ea552a966e4db790fdef30205023c7cf2b91c4677704e612d68e3d16e46a4a95d6efdc2"+
  "5c88ef0b16166a447107ad2dcd769d5aad75d163486ab506b55aa31bc13e0e4b18f8b49a"+
  "d145b358a3d1a2b65847290f6b3281caf77d840756a7c4494c1ca504a18ff204e56a2953"+
  "ce44e6247264d3bca94dd04683e723846060c518870f3e4eb15065cf238fb2f7d17dbce3"+
  "6defa61d3528f594d9b2753b324d905265ee259d193d33910c7c95b96ea552e424f495ca"+
  "19e963040bb53a511a618d25f025a11f8073a4698c9239742a89e3f809ed1bccccd4baaa"+
  "629e8586216d779ef6748f562ba2542ad2ec482a611e818fa9f4303f3f9b951f07f57a33"+
  "1b8c918662a14aad3e8e8e13fafb4658989b422d4d53035ea7dde902a98c0aed4469268d"+
  "bbaea69e6a9cb6cb35c618c3ecdc3c5127422a47aa35c78f9f214decb7d5d2196d4965f2"+
  "d4bc7727e2c4c99358eb08c30010a4c992ed2b334ca46982208f948a7cb180d3990379e9"+
  "1e827c0ead93e512901de804ebd66de0f4a971366ddd8a7186d4a42886f1954f92a4ac5c"+
  "b52adbf9ddc91fd13571787ef6ba9092ec681bc8178be8ee7858bbd5422ad9a5cfa1566f"+
  "2efb023a51c462adb99c72cf31a619d96313473bb2e8a87e71aad0b90b48b7c9a9797c55"+
  "244d0db57a0da5c2ecbd978e6a748e4ed4218e63022f4798cbd19e6a634c42ff402f871e"+
  "4fe9ebed210cbb6250aa334094ea8438ce0e444c4d361625b14b83f0cb6f10773a2449a7"+
  "cba1677ef7d9e9fab78552d3d474e7e59f1ac8743a51264e9d8f0f25cbaca1d61a6333a6"+
  "ce538aa8d566716e0e89c4f73dd2542385c2688b102eebe745d6d40909632b4768b76266"+
  "e7e7c1b4a8e44bf45506f0c32003609265d79258fa1232d3ea134bbd9366e700050aa353"+
  "8c712449bc0cfeb571ccce2ee2fb5e6631d7faa2bc593ea72814cbcc4c2fa2a308f081f4"+
  "420af022fac1dccc226118d3e96892b886e72b9c15171c3ca953ddd52334527858a3313a"+
  "454989b1862ddb7750c8e5ba0160354a0428058d4607e53952a3498de99a3002849220ce"+
  "0d632e015d6bbec3074dbbf3583101aabbc3a59759b442cf67d73d77f3f5af7c1de5297e"+
  "eae77e9a7c2547a765bad4ae4474ff95926ccc3cc33a6118303c3cdc3d77481028991d50"+
  "25ceed362925c259a4b5b4ea75529db0ffa187b9fbaebbb1d6f15bffedd5c8a08835164f"+
  "087c2188bb116b8cc598e45b73375a10b79227ecf6a7a700b5d668ddc85c44d662ce0781"+
  "d9906496b9c8dcc8180d5a1328c5e2fc3c38e8eb1f5c2e3352a4295ef688489304cff7b3"+
  "56ae7b7863be90477999b5e9df7ea9a73e9f4e758738fe0dc1e07575f7300c4992888585"+
  "792627a6ba0fd4f0c8438fd16e768f6f71997175c9e8e5fb3e6118e0fb9220f0c8e7328d"+
  "3f0c15be2fbba789ca0bce361664b37cbeafa8d55a9c3a757ab9433873fc54e674d29a30"+
  "0831d6a0bc6fffeced28d6b4ceabf9b87fe3bf56269ee29b52e07b3e7ee02185c4188354"+
  "d9b0c8ecec2cd60946878696efd36bd41a18a7099074da2daa3d7d600d6962f10341a550"+
  "a650c8d16a996f5bb23c97bde592ecf224c95388a757489f7805853ce55231135d9a0d16"+
  "16ead4ebe7cacfecfc0cb38bd3f84a11781e0a85740a6d2c777df5ab4c4fcdd2aab732e3"+
  "a4cbbc7f4a0a7ce9912bfdbfddbd59ac65d979dff75b6bede1cce7dc79a8b9bae69e47b2"+
  "49d14d9ab6043386a604797006cb82e197e421401e021808823c0949901879489c414612"+
  "0481620b961c8bb6a436290ecda6248e4d36d943f554d3adaa7b6fddf18c7bef35e461ad"+
  "bdcfb955d5ec6e41a6831ca081aeba75efdde7ecb5d7fabefff71f125aed0ecf3cf518cb"+
  "cbcbe01c1a81ce0de3d1885b3737b873e74ef5bb6edddd226e74e9f6e6e8755bc8e055e0"+
  "fbeb8f41f2a8299af588ddfdecc811a18438c270fee4cf9ba3d3ebf8addf59fa87874451"+
  "84b182dddd1da484855e77da05143af782043c474d3a8992506405c209e6da1d96961619"+
  "0c86a834c64c8a4fb07b170fddd25bad06c618c6e3ec63afa6288ad1ceb1bebe86c90bb4"+
  "29c8f3094e4c8b2b6124aa10189be3a4df028dd66823d9d9dd238963eeeedff5e8a42c27"+
  "71fea2d46142f391f3ececdc616d6591c2f88a5a1bcbe070c07838a8b48ce03f1f9d1758"+
  "ade975dbd492149be7907fbc8744a068b7e79062c4ce7e1f6b1db534a251af85ce6af200"+
  "0e707f87f5e002f044ddb5d555cf7f149adddd1d3abd26fdfe10eb34606834dbd39d7832"+
  "3ac41a5115780e49bd5ee3b0bf87500a84e4d4a953c471828a93bf14a87330187dfc9b1f"+
  "b62ad56890a609ebebc770d62145023662616e917aa34e524b595e5b464a473e9c200dde"+
  "b52b101d1acd94249544e1ac77c6e1b44321489442458e76ab0152523857f9188f47231c"+
  "10c5be4dae286c691a184d824e6f8ee5658f467edc1d723cf169a5dbbb8715f1262f2cbb"+
  "fb030e07236cb0b099fdef23b75ca568d4134e1d3f8eb20aad0b86c301ed769bc3833e2a"+
  "f276fda7d6d7ab1f16f5fb032486dc2a8663bf1db59a0d6ededa6469611953141c5f5d61"+
  "7e619eadcdbbc4b584629cfffc66410a9454445272f2c4691a8d065a67683d41a58a7397"+
  "2e73ece419f24c936719463bc6e3825ecfcbc9a55048e7486584160e6d4006afa0127dd3"+
  "da900a01514c12d73dffdf3a8f74e739a371461c279cb97811a524ed769756bb436135b5"+
  "9af7213c7be12237efdca6d1aa33fa0b78fb96edeafd7ff7715f513dc23ac59993276936"+
  "3b1479ce7860896347a41af40777fdd08a189524d31dc093031d16c76434c459419a3610"+
  "02eeedec60ad258d531e7bf41251a4204d3c8de5e771f385ef38baf33d3add0e8f3df628"+
  "ba281042b2bdb58b921190902475d238f5dc40847702c57b113ba191d2a02257053694fe"+
  "ce4a0a746534e135854a7840570b87718ea2301485218e621acd0eabeb27995f58a5566f"+
  "b1b57d0f81c419cdeafa2a4bcb4ba4f5262a523fd721904a0552a6b45b751e7ffc194ce1"+
  "656bbbbbf7989b5fc05ac3a03f0cbc8884f5c5b929f7a1d5ee54dbac3605baf0fcfdf5f5"+
  "55b6eede0d0cdc8ce3ebab5c387f8ec242da6bff6b9f7a9554a9b9e579b4533cf6d453a4"+
  "0d7f044d269a5b373788a29aaff285ac1249f23cf7dbb62ba16089b30a5378a7b13327d7"+
  "b872f91417ce9de2f4c9639c3b7382f38f9c667971016b8caf358cc520289c63a20bb2cc"+
  "834a719ca2643c2dc29d62e3e62d8474600b9e7afa4932eda8b75b3fb7a8182905b57a0b"+
  "15091e7df4327373f368e32d700e0e7769b77b3867bcfed31892f0f497474ad46df6b016"+
  "6a02b430ec1d0ee9f452a2a441bdd9647b7b9fc5a51e18c9934f3cc96034e0d68d0d9a73"+
  "5d46fb7d6fe6a082458bf0da405fbbb84a8b37030422676207bcd8d21734b19a5ab01681"+
  "54b9b0b2c8a4303cfef8454e9d3889c9729494bcf9fa8f989beb54f8781a475e9ba02dad"+
  "2c2733168d26778ad86aac906824851971e3d62649e24d228a92b22625420ae28591d72c"+
  "382feab2b2c020998c337001911490e79a288a585c5ae49deb1fd0595a208e152b0bcb7c"+
  "fac517f9e62bdfa43937c760772fe0edb26a2d6da993b8af302e5d5fa5f0b4b0d2b2c6dd"+
  "ef4b2ba63314a9049db92e5a5b4e9d3ac6a5cb97184d72848878effd9b2c2dcf8370e405"+
  "5e6a2f24692d396a15db99eb85f3072229e90f0ee8f4167022a2b7d0e3c6f50d6a8d26cd"+
  "668c70f0c2f32fa08bef70676383ce5297c37b07c112ce55d2ec0feb59a5f4064b36983b"+
  "7a4ebe7fe326c8c8b5714815b1726a9549a1b974fe228f3dfe0479911329c5bbefbdc768"+
  "32e6f9279fe2fdf7ae914d0ad2d8dbb58ef29c511279a4d2691071b53b946e5ec65a5657"+
  "9688e3a89a82eeed1d726ff79022f70bcc1a83310e8b879db362841082a228d8de32a469"+
  "93bc1873f1d24576ee6d72edda075cb8709e3c1ff1c8b9b3dcdbbdc71b6fff94d6c21cc3"+
  "dd7d7fcc0402a854b28acd135240d051181b68f21294375540c8e903547ec465ebac6249"+
  "77be456e042bc79679ead967b146a28de660af8f23a3d55bf6ba410b59e1074ced66ab92"+
  "d8fb05d0e9055324ff61f4fbfb08b980b339a898b593ab5cfbe026e74e1ff7deba52f2d9"+
  "973ec50fbef703eedcd8a4b7bc4c514c18dcdbff99f470676cf0f51328e7bdf2ac9dea02"+
  "4af3e6f9a5791aed0e5951f0e433cf71eac409f2c2c39837366e71ede60d9e78f2299234"+
  "25cf32ae5fbfce5cb7e5a558c6a24cc1703c06ac4f080f722be70c5afb277867779f4845"+
  "d503a8b5f6337be95d44acf520980bcae961ff1004e8a2a09636b17697dc8c387fe12c67"+
  "cf9de7f51ffd80f794e0dc238f6074c133cf3d4f1ad779f3cdd7593cb6ccce9d6d6c6022"+
  "4be59041332905c828aea6954e088412181d1ccfec747798c54c5add0651bbcd6034e4cc"+
  "99159e79fe5308adc8f209ba88d9dcbccba9336b1481683b99e46853f816b05ef7128072"+
  "01745b2d9feb2d144a44e4f90881b745534a2265cafab179aeddb8c9b1636b341a09aeb0"+
  "7cead967b9b97c9377de7d8fe1d0b0786299629c33198ec9665b3c1708a2c124d1569bc5"+
  "94ec11458a66b749add342484167a1cd952b57e8f5e6c82713944ab87efd033e78ff032e"+
  "5ff23a3c816665b5cd934fff759aed0ea628d8dabac757bffa357ffdcebb89c51264a488"+
  "62c8c79e28926519b9c831cea2949c198f6a94723861b11458a318f50fd8debcc3b3cf3e"+
  "c5993327886a295996b1bdbd8d8a2c8d38e1dc854b5c7dfb2dd25acab163c7c1663cf5ec"+
  "a32c2e7778fdf51fd35b5fc5641983bd034ca1b152a3a4c038c89c977fdb705ceadc55e5"+
  "d5fd487bda8869cef788e3146d34cf3cfd2457ae5c41e7864c6bf2cc72fdda554e9c5a25"+
  "8ee33023c8181e0e5122025bd048a3a30611730b7344b197310b292ad70b9d8fb142628d"+
  "a4568b585aeb71edfa4d565657e9766b98a2e0ec99b3ac1d5be7eafbef70e3e61d6414b3"+
  "d06b1149c5e1ee3ea3c138ac7ce75d3b6d69eb2e9152102509ad5e87a416931b43bdd1e0"+
  "dcb947387be60c7996331e8f8954ccdb6fbfcdcdebb7b9f2d8259657562a597aaddea037"+
  "bf80940a1d452c2e2df0e28bcf32e88f20b8773ac069a6d7507a0a62b1943ebf2143083f"+
  "6ff07471bf529796e768b7224e9c5c636169119924d554d0d720398d469d47ce9ee3ead5"+
  "37d1da72f2e42926e3096b6beb2cafacf0fa4f7fc2ed8ddb343a2d8af198feee0145ae2b"+
  "26b0b9efd89c9dffc94891d4627a0b5d848ab158eaf594a79f7e9ec5c5630cfb631c39d9"+
  "b8e0c6f5db1c3bb94abd9e7a9a3d1641c47834f2935c1cb57ae3680db0bc72e27cadde7a"+
  "271b7b672ca56226e309c37e9f3ffae72ffb9b72f6f502393100002000494441541c4f3c"+
  "f338e971c1e6dd2d06fb8a13a74f329e783bf6c72e5ce1f2f94b6cdedbe6c68d9b0c0efa"+
  "d4bb2d6add16d67977ae3c9c7551104ffab40a452205edee1ca7cf9c6565659922cf2926"+
  "85df7ec7193ffdf18fc1699e7cfa715aed0e6ffde427eceeee72f69147985fea91a4a98f"+
  "7d338a7abdc6c95327b97b678bbc70086988c318b9d41e78ed82412a19fc7e67c6b30e9c"+
  "f4b6f0c64aacd11c3b7e82d59505d25a0319c54452a16249b3d940678e9dbd3da238a637"+
  "3fc7c58b97b97af52a077b079cbf74c1bb880b78f6c9a778ecd225de7bef3deedeb943bd"+
  "ddf6e36127b0933ec39117adfa09ab244e62d246ea27944aa2adf728687752ce9fbfccea"+
  "ea3ae3514eff70df67296e1db0b3b3cdc9d3c7a937626291408437be967546a5f4cf397a"+
  "9d7630c50c0b607e61eedd5aab463e19845d20c598115f7bf9eba4494c9e4d78fda73f66"+
  "f5c42a7373732caf2eb27f38e68d9f5c65616191d5b55526d910e16065618553c74e62ac"+
  "61329eb0bbb7c3c1c13ed978421130f2388aa9d56bb4e716e874bb24714214268b83c198"+
  "2452186d78ebeafbdcb97b97f5b5154e9e3a46ab55e77baffc291b1b37998c736ebffb2e"+
  "bff42bbfc2cd8d5b1cee1e50e419e3f138cc061c972e5d264d95eff58dab4c24fd02a082"+
  "5967797a12818c04ca09841118a9b87ee37ddebefa26ddb91e9d6e977a1cb3b8b8403eb6"+
  "fcc91ffd3187873b8cc76396d74ef0c52ffd2297d4153e78ff1adff9b3ef72fefc055656"+
  "96198d264829b97cf9512e5ebac4fefe1eb76f6db0bf7fc0484510e7a45aa32210a18c8e"+
  "a4a7ae2f2ccc33bfb8c0c2fc2a691a618c64d81f7bea5eae78fffd0f48d38833674ed16e"+
  "77f9deab7fc6e1ce1df60e879cbb729ec79e7a91e1788806ac3024c97d3b80548a244e7c"+
  "4e8d362869c8f38c63271778f7ad0d9acd1a715ca3dbed2095241529f30b09b57acaf6f6"+
  "0e9b9b5bcccdcdd39d6fd270061d9c2da490ac2dad717ced18499c78968d9bf63b93c9c4"+
  "7b076585cff0b58efee180edcd1d6edfba457bbecd934f5da2dbe9789b95286232197178"+
  "3864a15dc7a230467377e32e492c88e38846638e95d5a5a0ab170869bd6c3a49188e860f"+
  "2554ba40a290ca79b32c5dd06d7530810b71e5ca6526c518a30de3f18883d198c18deb08"+
  "137167f30ec25a0ae3b8bd718bbc18d36cd6b974e9025bdb9bbc73f52d366edde2f8c953"+
  "cccff5bc1f80d534eb6d1e7ff229c062f289e738381b7629439a24a824268953ac135eda"+
  "3eca83036ac278acd9dedee2607f8fe59525badd3652c56cddd9e7cd377e5231b0afbdfb"+
  "1ea74e5f4009436efcb1d668d68f2e8048286a694a8ea086c24949ffd0f0eca73ec3f1d3"+
  "9b6c6edee389279e0a624e87159ecbd668d639962c71f3e635befbed5788928476a7c7da"+
  "da0aed6ecf6beda301918a7c1be61c799e33198fc31b89a8d513a228667beb1e37376ea1"+
  "71d49298d59515a22866e7ee1e073b0392d8bb643ff6dc33ec1f1ea0ade3cc2367186403"+
  "e224a59e2461dc9b12c7312a4a88e388288a8922c9eddb5b3ef124897fc6785a9226096f"+
  "bf75952ffed52f926519455120d30815d5fd7547119972610834a6dbebb073cf73211f7d"+
  "e202f5b8ce242f90b1627d6d8df9de1c5b5b5bfcf8873f208a22ce9c3ecdf11327d0c6b2"+
  "bf77e8db4deb75984ad551c21782466bcc70021cfa0c04044ad4393ccc78f38dd770149c"+
  "3a7582b38f9c254e22948a3ced6d31a551af331a8f710ee616ba18937975143916e8b43b"+
  "47db401579770e234a4681a0b0862c13cc2facb2bc72dcdf7853043d9d416070ce0b4037"+
  "ef6cb238df2569c68cb3096f5cfd11711493d652167b73d4eb3592242149537ef4c3d7e9"+
  "ef1f1e31686ed45b3cf6f4059e7de10a49dac41acd6070c8bd9d1d366fdfa591d6595e59"+
  "20491336af1ef0cbbff66b18a3d9efef73d8ef9388042115cd7a835aad4e1c47a828aa0a"+
  "4d29043b3b3bc12934103f54d08d8829e32a4d62a23862d01f12296f471b2b8506b4f51d"+
  "929411a9f2c9a4c349cef32f7e8a5ea743addee49bdf7895975ffe2a0eafa656c2b0b2b2"+
  "ccdc7c8fc71f3d8f738ed178c21b3f798dc3c321fb7b3bbed87696388ee8ce2d20c2fcbe"+
  "280ab249e6338bb567f738e92d6b70964eb7c5dafad314dacf49caaf67d6f0377eed5739"+
  "38f463df4ebbc5ad8d7d72abfc91e704495a3f3a43104291a4de0ace05cffd3297c75a47"+
  "911b1c9e5ae5bb37ef95ed9cc53a41bbdb41da1a8d4e445614d41a75eaf51a695af32a9a"+
  "4633f0cf0cdffdf6777dd062c52cb264d9987a6b9e6e77c9bb683a8b5209ce29d2b84e23"+
  "4d595c9cf73756c50137110c0743b436957993d6da1b332989b01629c0185069c26030f4"+
  "1ef9690c36b0cc225f0b08c06a8fd68123cb26c1c54486c54ef0e2f14e6826b8945b6b18"+
  "8e0be6e6ebc828a1d969b33657c71405d9a84d1c472c2e2ed0edcda154ecb902c632198c"+
  "f8bddffdfdaa23295ffb5b3bbcf48bbf80b682e17088d19a1bb7ee78cf432139bdbe4cad"+
  "5663d8d76cf7ef10c7758a220bc41d0b3ac070ced0ed2e60b425d39689ce3081cd250434"+
  "5bcd230a9d48468a5a92624c8193121979af5b210485369416494698e0c3eb87280a852b"+
  "34b5244588847a23c18cfc78d41a48931429556507a3049c38b1ccb50f6efb7006e78862"+
  "c5eaea128d4482ce3012ac93de9c298e410a642da69e26c834258e1384b06499f65428ad"+
  "91ce2fa412327581171195ad9a548cc67da4709c3c7982c5c5f910724955a56bada9b5bb"+
  "dcbc71135b688a02b0026704c6faa00a6bc13909567a4770ad513227d71322ab4220a5a7"+
  "d58f5482149624ad916539cd46401d03b72d8a23f2fce844358a15dd761b88e936db8c26"+
  "23ac731eb3c8727a4b0bd4e208252738d141981c9c0905ae0fd588844209456173a49121"+
  "0f40a04c50415bcb5cbb75648c13a5714ca356c79ba1ca4a36ad836b9577df0e5669c255"+
  "d8bdc3a194a2564b3146321a8d2972c3e9b3c7a9a5750fef1619fb7b7db23c47ebdc7bd8"+
  "cdb5e81f8eb002e6e6baac1e5f6138189065131fb214f9d08666bb46bdb58231706b7393"+
  "d5a56584046d3459e68d95b23c0b214d013b0fd33e1122615002b4e191d3a7a92731a3c3"+
  "3ebb3bfb7ea7b31683451b8d948a787048af5ba7167770aea8dcb75c40054b6f60214530"+
  "88b4c471088eb036f821248cf221d66a26599f221fd16eb7b026274deb20049919f3ec67"+
  "9fe5ea5b57d9dbde4348585c5de0dcf933182b90c2914f260c076306fd11fb07fbd4d294"+
  "e120a3b5dca25603639b1ee370d3a02c84405b8324e02ec260b4f4045147e55198ce701a"+
  "020817d1aad73d0152faf0051bc414b3e049e14248138e58489cf0264a4a4926930c8309"+
  "19411035536ab53a8d5a4c12c7deb54382319aa2b008a1289c414ae98d9566727b0a0bc3"+
  "d1883ccb198d460c467d76fb7d56e61710d6c3b14551e09c63d01fb0303f870de6d135ca"+
  "38358990cafbf439cbc5f3e7b97cf1a237973616eb7cbc4bee8c27864a8920f2a453ebc8"+
  "46190e55b58e362c326b2ccee6381ce3d1842489c9b3cc47b920c8f282d168c8fcfc1c9d"+
  "c631ea8dc694bc69bc1175bd5e63797185daa329453e408988a896526f35a925758cb5b4"+
  "3a5d1add2eeb274e04ade688edcd1dfa877d621987872e1c7f61bced8d2ebc459e32825c"+
  "69a4f3dd1d01775152d069b78f2e001945b45a5d948ac24cdc3fe9fec71555cb90886826"+
  "21d361c81158dabd1e79b64d2349bd56c03af4246394154c0611f55add0b7c839e5e4a49"+
  "a1c738eb889304a38748e1ad64ac75e47a42a17d00a33105ca38520377ee6ea1c2196785"+
  "06e1180d33f2cc92245344cf85e52e98063d96a95ed61a721302212cc44e226444e9356c"+
  "b52673c61b5cdba21a6f4967ab418cd6be981a4f46ccd3c1698bcd0d665230d0fb64a309"+
  "baae198b31422ad2b8e18bc77a1c166a4ebde6e875e7d1da22a40ee213dfea6aad9152d0"+
  "1f8ec9f282f164ec775737619481b005ed4e4aee737271410ca284f0ac6721c9850623d0"+
  "01ed143862a7c81074daddfb8a40a0d16a2110219ad573fdb5d1743b1d46636f236b4519"+
  "8c2a2a8327630a9454f47a3e12bd516f81b00c86876c6d6d72e7ce26a3fe105dd8197c53"+
  "3c9441e88f6b854a04cd7687b5f5132c2dcd2195a433d7f1b172c4ecef1da243c8d3683c"+
  "6677778f66ab59c5d0532688de4729ab042221cebcba1c3793841ce2de4adfbea957c3b4"+
  "70b5c6d2eff7c9b21149a288940f753a7df60cb60cb60e64d3d75f7f8d5b37378865421c"+
  "5ad45a52234962948cbcfca4a4db0751495178fec1446774e7da1c3b7e82d367cee2d43a"+
  "ca82d5967ca2994c86be2609015ac66a7fffa47f9f4aca90622a91a286148628522469ed"+
  "b5073c82e6e6e63d18121cb18590ecefeea18b09cd668b4eb7872cd133075604503f9cb7"+
  "22842821fc19e69c63797985c71ff705a79f74c92910546ad385975a2911ce6de13b0c21"+
  "bcf91242238d9a2a756c8111d267fcf5e6585a58e2dd77df219b4c68b71b21d731dc6431"+
  "1b2b2bc23928c3e4cd868451394dd156c111202c526ba7ca5c85c2da09c6f8c0a9dddd7b"+
  "5c7ef4020bbd7992284546113ad761a7700169745cbc789eb38f9cf4f6f95981292c46e7"+
  "58a3d185f6c702deb1c4e16b963496d45a110b719d66bb43925afa87f73c8c6dbd45bd52"+
  "11514c08a710a0ac4750ad4648413dad93a629b76ef743cfab71c2f31fe7baeda767137f"+
  "23071c5b5e4648e947a432414981108a2c3720733fabb605a3e1d0a76d0594ac5c2c65aa"+
  "2721dfaf9433cba02a7221d5d30ae10da5a3a88265955244e178d1422030485166e27ae3"+
  "caaa3dc50481870f8fccb28ce124e3bd0fae51aba5d4ea0d5aad46f81e812d851e82ea3c"+
  "17217a5e949870d8810c0a6b4d88a7f5a3da6af7c02f6c6b0537aedd65322e980c2dbbba"+
  "4f9a64481511c7de025708af5ec259ff3e4544a26292a6a864e2dec1cbcd0ae3434683ac"+
  "8ad992085a51b754291d17d56723840cd6b2be5554b1a2b0057b3b7d36b776c8f2028442"+
  "2890b124b2923449a71327117680eedc5cf8651629bc9f9c0b31a9d9644c2d8d69346b2c"+
  "2d2d84edd556c781287df443b12842f1e4aa1befe7df12cf062a090ed63b32798e000e67"+
  "058aa8b2ad2fd93056f86dcc588312351c1a6735d679a9d9a9d327b9bb7197377ffc2eab"+
  "ab03ce9f3fc7dc82f391b208a48a821b53a08f4bef13a48d9eb292828fb19b8922b7c23f"+
  "6dc65874eed8ba33e0cdb7de627e2ee69147ced0eb7588e35aa5cb73aef41eb638e7fdf9"+
  "7d0cbc0e3235817121dedd85eca1a075f48bc684165b31c982d4ac8ca8750e445c753b12"+
  "51d52de5bd88638fc41a27c9b23cc8dc044a398a42a26482520569ad86b67e4c5e1d01cb"+
  "cb2be72329df914a1205d76a11b6f224497cbcfb68cc64a403cd2b2c00dff613490f138b"+
  "6a75fab3d804e00811080ed573ef10ceab6ea584cddb7779e3f53730b9efcba50c957c79"+
  "834228b308dbbbdfbec3f6ac2479e147c71b1bb779fb834d3aed961f324551a5f8a992c5"+
  "05d513639d43094fadd2611287f4d6eec209725d301e4fc80ec7ec6e6f601863272df6b7"+
  "f611c1da1e595ea70b05b240398711de594c08c95cb7cbc2c953f416564884f0635a4195"+
  "38e6372935657d84408a29754e56da9a7288e5aacfd385f878cb649c93151aad3d60152e"+
  "8f244e7d826a9a226474140708a60cefa6718c931e57b656875d4654fc74e34226809033"+
  "6acd90c259ee2842112029cf042aaf9290b517deb52d5543c2614cce1bafff9483bd83bf"+
  "048a64cef8f6db6ca390220a2c1fe56161157959b494d320682183b0c422ec344ed119ef"+
  "0c6a8d1752183d9911af8e3ef155ed753abcf5f6dbfccd5ffeb770f51a79c8a3170eb42d"+
  "aaf009636df02c741591c6048bfa9273291115ebd82b951d2a8ac9270559ae3d6219b217"+
  "ac3648a1482281d392286978d4574e39881140bbdb23491274d8cea5f2de2f9593949495"+
  "d7bf90be5d122177aeccdf2df57952b92abead6482fa2382996d6b96fa203e11fffd63da"+
  "66554f16967fe3af52be767d7b8f73278fe102d9c485bac95947ae33b436c8a0d42eed02"+
  "adf10f5d9975ec618e28b88997bbb5dfe1ca4c430f5ed95023f8c5a32245bbdd66bedbae"+
  "c6e0551bd86ab5e9b63bec8d739f5d6b0cc8a8cac9290b2930e02c05d66f2978968f7102"+
  "15cc18f371c1eefe1e93f104b0341b0d16e6e7bd39842030559ca7446911e44a1ff1aa2b"+
  "8412c838f2418f7eeff4d726a5b7ae13d233272bff6137756164669b72ffe616421a698a"+
  "903cee4a1ea685f1f01063274cc65e5756026e304d27134e54a89f1382a248a8d5da5eab"+
  "2144d04bf8621514c2498cf0d4332125562b7af33deed7e35672d6a5a5250e363691320a"+
  "5c32570d105c3934b10e844105598d0eab6fffde2e1bd73ee060778771f670eda0b75659"+
  "e0d4f947a8f7ba389d7b174efb110ba029e0f114377698950e6cef23d61761ef90787d91"+
  "62738f78be831e66befd9302911954b7397599db39205a99f33dfacc9a10c6916def1335"+
  "6b500249fd51d0d8096ca189967ae8ad7d44a7813918202285cb35228970a302d9ae63f7"+
  "0650f3be84f427508fe0eac4eb048f48f704c60437d0d26026376cdedd64fdd822c78f1d"+
  "a328720683219349560dbb4af5789224341a4d2c095bdbf7180efab45b1d6c642a208c70"+
  "0c8b30bb410aa238069370e1e2c5071545653bb0b0b4ccf5bbbb9565aac0624d81145115"+
  "70541a561801c239126779ed7b3fe0ee9dad8f5cfdc32c67b871879b1b77585f5de6caf3"+
  "cf219c0f5efc99cea3389075a815c4c4b85e8f24ae53341cb14cd1ceab809d31be784b62"+
  "6c5e600763dc2447ccb7b1455155d3220843adf1e95fb29122d3847c3044a8085b4f1049"+
  "8ccb0b5c12616385958ea85387d108d56962fa236423f5385b2b81a4e577242971a68076"+
  "0cea410b9c5a9af8912e16a9bc67415164e8c231196976b60744b13779ec7523a2607eed"+
  "f081d393f198c1a04f7f3422cf74c853b43347a89dea0e6c391bf1bbb3538ab3e7ce3fb8"+
  "005ce8e197979751c93b616b35a14850c16fd15bab3be7c57a4ae788b8c6e99373fcd197"+
  "5ffe44927607dcbebbc5af9e39c3db376f20a8516bd4383ce87ff837590de31cb9aa887b"+
  "1e5a16f34d0486fa5acf1b45ce75aaaa58b6eaa13df5470eeb8bbefd2b4f324be50412b5"+
  "6a0809b5f9563818eb55d7a1b54600c9f1252f1c590b3efd8d1411495ca71176a95a65de"+
  "500860fb20b440f789620f73ea4d81713e97b8a4aa57032d0fec311a8d39380c0f739956"+
  "16ea2a635c30bc10503ee5824adb2142fbea8354fd111e4509566b9eb8f2c4b71e20c294"+
  "d55a6f619124a979d306e17f508984b910b79ee73938c76432e22bfffc0ff8a7ffd797f9"+
  "0ffeceaffaa8948f2919afd76bfcfaaf7f897ffa3bff986f7ff95f620ffb3cff991748d3"+
  "0f67eb602d245105e7da19eaac288bcb70d649a9909162da4853a94125d356d085787ba9"+
  "7c5f5d7a10511d7ecebb9ec751704811c8c8873bc958055f25818c1432f245988a224461"+
  "c0c98722deaf7ef315bef1957fc5dd8d0d845264da542616e56a9742a254ecf509068c91"+
  "381123558a9229427864d4689f55e884637a604f05a5424ec12f2925b55a9d4b172f7eee"+
  "c123209c01ed76c753a2a59cd19fbb6a018c4623169796188f47fcd9abdfc538c7f6ee0e"+
  "bfffbb2ff385bff602af7cf3fb0c0ec7f7afae237557abd5e4d39f799edffffd3fac2ef4"+
  "4fbffd1d5ef8c267f8dc4bcff19597fff421377f3a43f00e1e226cb7e228ba57caa8ecd4"+
  "dbc789d9fb20420763519184e0e661b52da18ad0fd1c55e57a97f1993173691f25bcc389"+
  "0dbb05124480625da23e543bb9b7b3c3775f7d95f9b7e678fec517d0c18f49a9883c13dc"+
  "bc7e9beded6d0a5392c53df40d9a5a9a70fce43aed6627b482a15db46e5af432ed066430"+
  "8b89e388566b8ef956fd01fbb9a8bcd2563df14109464fcf130c583f526da635c659c6e6"+
  "8d5be433966783c1883ffcf2b7f8dc4b9f61e3d675de7f6f63da01cedcfcd3a74f72eac4"+
  "71bef2f2d7ef33851a73efe616eba7d738797a951bd7ee3ec454224cf02a84d80fac04ce"+
  "9b5b9415b51047073725f0133a19671d428542d07a75923f27e5344dab948de3e9594402"+
  "6b6cd034fa27ddb766d37cc232f0c9ef14e1f75958aad789f28ce352300a41dcfbce7b91"+
  "dfcb0a326d7cd4ad04a284f170c4ebaf7d975a22c3b53b54d8911d82a22fb92b72161f7f"+
  "865844489b214501c4d54cc3bf0719663496484812a9585f5f2b1f83071e5200babdae07"+
  "7a64852f05fa96a328b44f9c280ab6ee3ebce07be51bdfc609c52f7cfee92a60b1fc552f"+
  "bcf02cb1527ce3956f3ff47bafbdf71ec22a1697961ec2d6f4ce17424c9f4cff61fb0a57"+
  "05b4abccfd55524ce70e41f8292bd06786d2169ef4e0abe0a1aab0a5968497920ca354b0"+
  "879b712b2b514f313b71b416979b30a007eda02b157b8167393130af0b62a389c248da16"+
  "051247aaa240de708c3343965bb2cc311a594643cb7868188e0abfe3c872a0a6c0a9e98e"+
  "254ae8c58fbf45d8c1a452ac1d3f716418eb9ce75e546d606f61f14b52f02f658994951f"+
  "f6cc304259c7fefe8723761fbc7b83fe5e9fcfbdf4023ffad19b186d79e6b96779e7ea55"+
  "ee6cdcadfacefb033186a311c57842add9f810af19176613a190732224798aa93cbc1c55"+
  "579b74b081b1957752353a955204f68d98b64f332daf0cf949fea67a6644992a3a3d1ac2"+
  "7d0e98842bdba9c01dc0c25e3166ef81f32cb484768c121a611d9190486731e6a35d5322"+
  "15544d561305122f2503aa9cba5790b2432adf491c5b5bf3377c660328dc4c0db0b2b4fc"+
  "875104da06a002138e3adfb75ae940e795bae6c35ef776f6f8b3577fc8f39ffb2c969cef"+
  "7fe7fb0c07531751cd037e51012d3ba0b7d078f00b06300661089e7da1952bff9db355dc"+
  "8bb36e3ae90b90eed46cd91793320047252c2da4f4338da05a2ef1f612612b2de364f5fb"+
  "4ad9fbf4e9b7ce3b8a389f2f5f4dda7ea6a9835214c630b116ed3449aa38796681ed7b6b"+
  "8c86039f745e5d8f436b4314491ebd728628aea14d46aaea28e990d6fb13f889a9ac6ebe"+
  "b302e12c711cb3bcb2426e40cba35d775442b1f3dd2e6b2b6b5cdfb883529e64a88dc50a"+
  "3f9e95c2f7921fe775e6cc695616e7b979e30697cf9fe47b3f7c1335e3172681ba80a19b"+
  "7da2940f397ad80e30ce71b9c16acd786b8ca825a838c2194badd3c059c88693a9556200"+
  "aae2c4134bcb89a593d3addb399f6c2e23e59d41a4a8a0571518d265dbe866424511a084"+
  "f261d2e17aa5949e2361f00ba1d01f89387a934d1f805d84d1f6cafc3a2f7dfe0b089bfb"+
  "781b6b2ac4d339cf3b7436e6debda1f71e0e3548995e5e8ee75d39d256deb92c8e63e67b"+
  "9d2f09315d9947a060842049127ee9977e91fffdfffc3f3c182412849c78fb141bce48e9"+
  "6836eb0c87e387ba015ae0f127aee0a4e0f7fec9ef21808b97cef2d24bcff0ad577e481b"+
  "47d9ed8d35477ae566bbc978327ef08313f88add083ff4c846d4bb2dc65bbb4829998437"+
  "6386138823af338f24667f846ea634e6da8838f26d60e870fcf9e8bd7ff3d10493e7d341"+
  "e14c99e44a43213113295b12318d256aa624a9cf20143650e587390c3f1ade2e594b2e70"+
  "314793319b9bdb4491a0dd68d26a7769c73ecea6c80b06e38cfdfd3d068301c58c937845"+
  "6e093c07dfb578f34a27bcf6a2dea8b1bcbaf687d52c413c040a1642f0a9e79e17bff37f"+
  "ff8e8b84f028a60b8c19247a5260242c2dcd331c6e543f202e8d3c95e4d3cf3fc9ddbb5b"+
  "7c706d0305a4c0f5b7dea77fb8cce7feca93bcf2cd1fd18c15d21976b3e99d5e9c9b8304"+
  "f6b73fc463400964c3a35eb5a51e48497d65be62c3ca808747498c2e3449a3469126c4f5"+
  "d42363da86739d6ab8559e9569bd866837a6e9e2d6a1b39c6cb78f391ca1e69ac824216d"+
  "8684731568e1212d5d1705a630e47b87c4bd36d4a2903dfcb3cf731516a3b416ab0d5abb"+
  "800ac27894b3796f0f57a68c97e1db625a5a3bac3710709e48e20775cab7bf657a7ae451"+
  "c0c79e7e924eb7f5d05de988b5659c2428ef25e68b23672b03c4d124a3d36eb27e6c8deb"+
  "d76f8708b5f03395e497fefa5fe15bdffe1ec5e1605a19277e78a3f7f6f8c98f727efd57"+
  "3ecbfff32ffe94d84c6b0180b553c7b05ab3fd3048b96a0305769233da1b10376b212c59"+
  "600a8fcb631d36d5a00da259236935fcf769cd6438f05abb46adbad1a579b3f7041648a9"+
  "18eff5216ca7d61ad2e51eb5f9b617b08c32f2fe0857ba7b86560f63fc10aadd20bfb31b"+
  "d4261f6da255dae3689385e345501482c95873d8dfa3c88bd0b104c5702c68b71ba4b5b4"+
  "e25654e113362cf030599cdd658484d6dcc203687bf9e7230ba0d96cd04c63ac84440932"+
  "e3a3e195b038095936a1d96d73f9e259de78eb3d0c303f3fc7934f5ce64fbef62a7156f8"+
  "b6aa74de2834691c912848c4983ff9ea0ff8ec679ee4fbafbd05fb7eaebebcbcccc2ca12"+
  "a3bd0376eeed3d1c08b2ce836b5292aecd23b4c10ae97bfa31a87acde3fd218f78b4d7a7"+
  "d16b576da41965a49d6680136c652055824bc2131729eeed239a352f64a9a544ad3ad9e1"+
  "90222b7c00633d41d453bfb58622d205ae9ee98f10cb1df4adbd309584348e6939eb3d84"+
  "c3fca481631f8f58aa40464b92042162366edce183f7dfc36853d1c2ca1bec1c2469cc93"+
  "cf3c4ab3ddf3d7e87962615067027db524df38cf1d9282b3a7cfbc664c0599f8f722fdf9"+
  "1f1ddd6905bd4ec7ab6b84200ab42207444a8661032c9e3ace45e7cfc1f9c579bef1f56f"+
  "074530a411c40632076924996f2534d29883fe986c34e16b5fff019f7afa323b834386fd"+
  "098f3efd287956f09deffce06782c8aeb0884851dc3b205d9e23bfb58d8a634823ac19e1"+
  "a4244a2449afc178733ff0152c5112d35e5fc4181b3e1e572d0015d84fe5b1d07ae438a3"+
  "ed5ddc28478f33f4e10870348f2ffb42cf4e072f62065c42806ca414daa7afa05da8762d"+
  "17b5e1a7c02960028c810c4b5385ce23e00c4922998c46189d57865af7efd8796630a6f0"+
  "085f380da4149e7216184f251e2195228a626ab584e5f5d34f971e095240aaa6c5ed03ee"+
  "c62bebc7903f7d031545682bc32c7aaaa4544aa1b4e0f4e975ea71c23ffbf257a6fdbc83"+
  "61e1abfc242c9c3b07632666e46bb9b03bfcf90fdfe4d3bff059ce5df456276fbcfec6cf"+
  "1e2098c0e32b0aacb6e87186ea34fcd3976b88244e5a0ca0338d1e8dd1793e25618ae953"+
  "344bf434852e61bf4a4f9076dbb8b60dd0b1ef0aac36184cf860bdc7ac2de7543376aece"+
  "58fff4e7ae227afc40809592ab4278cd8484d8060a7a1c87c5279091439b8f36e04c5315"+
  "e616a5b43dd40268900a25244559e44ac1dafa31549ad24904f7fb7d8ba33b80df1b1e7b"+
  "fc09fef82bff0a83c438afb0410aa42b59b3fc63e00000095e494441542a96e02c4ba133"+
  "3ef78517b9fede0d6edcd838b26b4fac63322b04c58fc71797e63973e124bd5eeabd79ec"+
  "47b4cc06d8282011d8d10e6847b13b0e42660189a87e811182d1ed3d708ec1e826387104"+
  "419c82fe021285487dafed06854775d47d4db2286939e1a94e66be5e3d14a534c77929da"+
  "40c3203cb12566328b9d583877ee0467cf9f626c14456ea8d77d42dbc242939d7b72c6b8"+
  "a28a71c6184bbb9332d7e9500470aa0cddf2e8bdaa46f5de21d51121b870e9714eb63d29"+
  "57fbe7887826c12dbadfcbedd1cb5744b7de70fd42238ab15fa922843d6b3fe992c26202"+
  "532549622e5f7984f317ce7073e336bb5bbb4cb2bc52e988d08f77e73a1c3bb64ea7dbf1"+
  "8cdeb095393e469edc4eb5157cf8c858de0734281fcbe9e47d20dc4c3fefa29945266700"+
  "2871df7f3a7c7f3403f0942db59df93ec387d2d09492f47a2d9e78ea3ccd668f51ee702e"+
  "f7c5ad75346a753efde2733cf7ec65b4c903235a843a25149c42206872ebf66645072f7f"+
  "79a92ec279eb1d158c3fce5e7cb4bac9b9819afa9036b01c83ae2c2ff1e20b9fe2d5d77e"+
  "c4241f934d32a234c169cf5d2ff9e80e1b68de82c2818b0c6ba78eb17ee23826142402e9"+
  "1f0ee535ecd259b27c4c1cf951a750aaaa683fda08f9be9bec66fe3c73538fbca368e666"+
  "c5f7dd3c77dfbc411cf534ac6eae98f937e5ef2db9afb3e89608bf23e7a1b9bf8f9c3fc9"+
  "b133c7712ea65f583fe7b732a49f48fa833ece422d8d5958582352b2b293730e06939cdb"+
  "1b9be4d916799ef927bf34b30a03282514d6181219518b7dc0f5b9332704e1e98f55a0e6"+
  "cf0a438e7cce617efaa55ffb7571f3d67527f28ccdcc6701a6ca9b2d3aebf37b44783cbc"+
  "fba50f4b900e9fa91b1e49e340380b85097ebc0e7d1f01c8fb0c1c2d777aed36fbfd3edd"+
  "769b837e1f89a0167941a4753ed10420513185f61abe248a8e1851696d88a4aacefffb3d"+
  "f86711672115bf7a6a81abbb437e7a30a4d7e930e81f32bfb0189c5015e3d18883e19046"+
  "5aa351ab330aec608bef50e290941eb7e32a3bb13f1acd9cb7126b95bff121c104e7284c"+
  "01d4c826053aa47bdfdddaf14f7092e2aca5d01aa3a781db650c8db322f0091c9188bd0d"+
  "8f35246944524bb8f8e8158eaf2c02de8a4ecc38923e74072839f38f9c3ec57ffa9fff97"+
  "e2bff9afff2b77381e72d03f244205e9d57d0c4b41453d62663c5aaa8308f26ae13c05cb"+
  "89809d3b81718648c9a0af2b39032d3ef7d9cff2c69b6f72fad469befbbdeff057bff045"+
  "06fd3ed639f6f7f7fdd4d05a7abd1e7ff4f21ff3dcb3cf52afd579fbeadb9c3d7386cdcd"+
  "2d2e5cb8c81b6fbdc1a5f317c8f39c3ffffef779e1e967b8bbbd45afd34148499e675cba"+
  "f228fff33ffa6d1e77191b894f1f5b5f5a22ef75bd856d14d1e974d8df3f08892531eb4b"+
  "cbdcd9de6275698983c3430aad595a58208a223fd8d29a7bbb7bf7155cd653d6825ac939"+
  "1ba8f21aa5447010b5614e69d03aa7d063ef6a529972f8efd53af7f6b304214a68939db5"+
  "4489a4d56af3e997bec8afff7bbf21127914ddbcffb4150fa3647b58d431c933fee1fff4"+
  "3fba97bffe270c0f0f50910c69dc5ef1123ae97255847e5a239cdfbab435d389d90350e8"+
  "54dc914dfa7cffcfdf384242f979bee6bb1d923841441177eede258963cfb6b58e5196a1"+
  "42745d2d4d198c46d50eb5d8eb91e57925a38f93c46316ceb13b93641229c153cf5da4d9"+
  "5eaa5cc02c1e491cf4870cc7198d5a338ce0bd16c0bba896d1bb9e8d1449ff10e6c52169"+
  "2d258d13a48a49921af9c4bba3f47a5dfee6bff3eff3d7bef4cbe2442b3ae207f4d0d3f5"+
  "c338f9650167806bd7aff30fff87ffdebdfaad573042d26cf828d8a228b0c6203d70508d"+
  "611d166783cf96f5c68c2658ca88706e476a26d8c97a0a9a75dae30d8102ad4a6e827028"+
  "a12ad2863fa944e5a983b3fe033dca1ff19b9271810740d0fd056d833101e69741ef1884"+
  "19ce11292fd32ed3c69c0bc71de0aca19444394bc599b065408e7328e97317ad73d45245"+
  "b3db455b092eaae45ce5e75e1405599e5364b91789868ec2553c1651e6d72124a848514b"+
  "6bc4714c1445c471ca6492932429c78f9fe23ffe4ffeb3df7af2ca85bf9fc8a3f7f1132f"+
  "80877df39b6fbdcd37bef935f7da4f7ec28f5efb01837e9f5a9a1049111c323cf85042d6"+
  "069f9b674d88ee08c0855251a523d0a654d57ad59b76deb94354dd87acb62d29146ea68a"+
  "73c1f80037a3951315012c7cc8538f801256f5471515b58b102feb493fb262059524b092"+
  "5c591d6f95c5b799191197e77ce0e8b9696095a77db9ea1aa510be9e2ad5c4ce27880ae7"+
  "824187addeb70ba40ea7945705479e382264044ea2b565fdd8093eff8b7f83bff5effedb"+
  "62a9d39ab99e8ff6ac171f4f95e3aa8953f9fa8ffede6fb83ff8eacbde9f46fbb3486b8f"+
  "548d460593e198a79e7c8a7ff607ff425c7bef1df7d65bef70e3e6069b77ef301e8e1817"+
  "13a48042e7f896c00689f8ec536cab9b5f52b808e859753d41b256d62f8892e8e166b480"+
  "33f2b4720a673dc94404876e634555ac558adc522e2fa9d845be0d0e24526baa099caf6d"+
  "4c1835fbc55a5d8b28317d41ac1452459ebc3a339e564a910427d2ab6fbfc9bdad2d1acd"+
  "064e78bf8249963399644c2639024dbb3dc795275ee06fffe6dfe5d32f7e4acc250fbf4f"+
  "1f4930f9b884eeea678632326e77402a626bb0ca631d2292589510190d43f827bffb8fc5"+
  "a913eb9c3ab12e5efafc4b477696f26795e1cebeaad5d5965b168e53316ae8c5dcb4659d"+
  "fabc714430e98ba6fbb63e37c3fa11813be40423ed68c6f27e67fb072aa6d99f5552b1c5"+
  "0c256caa819cf90b71dfbfaf3e4731fbe5990005ff7fffeb3ffadfdcdffbbbbfc9e2729b"+
  "28a92155821296484962156164c295a79ee2bff8ad7f202eafb6661e52f189832aa24f5c"+
  "3185bae0332f7c9a1bef5d65736b93fe785c9929d5d21abdf92effe1dffa0dce9fbff040"+
  "df51e9094b91060259310a02b9f1be58f9aa5d3ff2b31e461c78082e701faaac439126c3"+
  "13d9fa79457b7ccc97738edffc3b7f5bfc83ffeebf75f7766e7924cbfab0699cc31a4dae"+
  "0d278f2d737ca151f1376703263ec93b129f5498f95145c5fdfff6c8eef1e09cf7c8cdfb"+
  "a88b3ffaf50f5900d526550a4f2b911bc6fadca0ea58f904efe5e7fdba76f326ffcb6fff"+
  "b64b6aa9af9b82c95ca4a091447ce1f39ffffb4f3cf1dc6fb900b8b987ed60ff3a16c0ec"+
  "31f0514f1c1f7a5befff3bc75f4608919ba54b84634486ed7eba10ff625be5cf7b1738ea"+
  "51141472e2e1ffaedc03fe229fa470cef1ff87972919c333b3fa6a64fb001bfeffdb2f37"+
  "bb7bf2e0b3f697f9fa7f01b79475e112d290ff0000000049454e44ae426082",




  "flag_bl.png",
  "89504e470d0a1a0a0000000d49484452000000100000000f08020000006211d878000001"+
  "7c4944415428cf95923148425114864fe57097e0bd2150a8e0d164d0f09cd24d9b121a22"+
  "08b4516a291aaa2da7688a68081a2a5e415141f0745287e83e5aaa4983c0db761a02ef20"+
  "bc33489ec1a0c1218c2cfb97b39c8f9f73febf2fbd5580ffa81ffea9407b6453312b6808"+
  "01979e6a3264a6c300e094947cc29f016bd858583b304391f5942584985a2d1a86b9316f"+
  "b54900d09ad74fe5172004004162d6763c42a5ac90654f5aee0d3ad7be4f44ecdf1e253b"+
  "6e506f94598cb9f95c241c4cc46d23680203042d236422e1c54eece14577004ebe9c8cdb"+
  "44e83719004c61a0067c255991723f5923764ad5f6e6c0447c01001adc1a1f1b1281803c"+
  "3e849184aed37da5481ae55e12890ff2d526f3f7b73af972663641c224c2b292bb4bd1fb"+
  "a3b4d21ddb5f0e6d93d1d060b301cf773979b2dc78ff38f39e0b8fd86ab5ba06e77ad595"+
  "c518b2992b558a15acbefa7f245d23ae11a767ecedf3c2662ada53355c0fe7a6c3ec3313"+
  "f704a0f6b10eb75759a5e9b72e759a28b77bf93e0127eeba7339c87e050000000049454e"+
  "44ae426082",

  "flag_gn.png",
  "89504e470d0a1a0a0000000d49484452000000100000000f08020000006211d878000001"+
  "764944415428cf9592314802611886bf4ae28686130a74b449878693860c5a6e080c1ab4"+
  "2da7ba0c22683182509a1c0f1bc2cd1b6d28baa6b3a96b087468f885860b14fe21e1fe21"+
  "f83f48e81b1c1a1c522bd1777997f719deef7b67cc9a01d36816a654a06f192d1f52c310"+
  "50dcb64d3dda8aee0240ededda7b77ff06428be19db37224e61552397521787a79802473"+
  "7b853e090088c27a29fc0010505090beaf951f2c501014994ee9f653598204021458397f"+
  "1cea2090e74f74ab047a32ae691aa84124d4125a508da000335bf14463087098a5af2590"+
  "500a89849188ca39678cf1262f1e9912d0f5eefac9b9cd4c1c00a8d75d5e5a51e6033757"+
  "2c1c25de412124b644f1d0fc826eedb54a3d1c3dabc32c635b4708f226a2278d0da372e1"+
  "48c0c1f440690024e17d303d11739f7da754f415b29b652ebd718fabb79ce3ec3aef866d"+
  "86ace3fe4e8f024842926fa462e66d35bd9a9b681a8d762d9d8ca10f843411e07f72045e"+
  "bfcff9e48ddbd27013bbfefff8be012081be0db834bd8e0000000049454e44ae426082",

  "flag_gr.png",
  "89504e470d0a1a0a0000000d49484452000000100000000f08020000006211d878000000"+
  "be4944415428cf63fcffff3f032980898144c002a5ffa00afc4191c46ec3b2e5cbd6ad5e"+
  "c7f08781e10f0a1b81300db1b2b5dab67ddb870f1f0c0d0d256524972d5f06978a8a8c82"+
  "b2fe2381a58b96fe4705cf9f3f5fba68e9ffdf0811244fff6160606178f1e2055ce0c58b"+
  "17fb76ef8b8a8c4271079a91104beeddbeb774d152a8d9df5114b06006dbfd3bf78f9f3e"+
  "0e71f48f1f3f3878385014fcc700688e4603d822ee07de98c362c86f7c96909c3418b124"+
  "be3f0cd862158f06bc0000bfa1ef259d775c6a0000000049454e44ae426082",

  "flag.png",
  "89504e470d0a1a0a0000000d49484452000000100000000f0806000000ed734f2f000000"+
  "a14944415428cfc552c10dc3200c7410eb586c900f3b300743b08a07620266e00f765f8e"+
  "28226aa2a6eabd7c36679d8d01fe8d4d0366168d8d31db9853be821d89730eacb58770e6"+
  "23b4a99d0b3146d8f71d6aade0bd87100238e7dedee49ccf67424459e589481051566e60"+
  "dc03220a11c96df1ca454a4910f110f7deaf375031330b334b29456efdef55cbe6acd05a"+
  "fbeec274a19f5c98c74e79e560beba9fe00557276bcb3290f7780000000049454e44ae42"+
  "6082",

  "flag_rd.png",
  "89504e470d0a1a0a0000000d49484452000000100000000f08020000006211d878000001"+
  "7e4944415428cf95923148026114c79fe5f00906de1078d07291c305121734d478e090d1"+
  "d06a34c8450d0712482d3a994e5183a183700485068506412d510e824da9507082c2d720"+
  "7c37083e48e81b1b0cb492d0fff296ff0ffeefbdbfadb2a5c1389a803165ef0df9204c66"+
  "247012eb3a07dd4f77500300ebcc60a5e7e10099933643a93527f3ef686027b9d03640c7"+
  "1fd095e07760fe6e99b1681f0042ac2e0ff8a45c320a1c14b7202b6a2a9d829304002087"+
  "c8ed63cf38b9bbb0080082ec999f15f76e58dc2b7845f1a1493d2dba224b534ec7d32b6a"+
  "87115bcbc2976a7f699a31967dcbc8d1641da015c52520018b52a348f55858740aec3cfb"+
  "e34abc8dbc6e6a3e255afbce68d4d0a8a37e1417a7459a3638e7bfcf4a33466043452224"+
  "ea58a85175558d14ee048041f7c0d200bc8df8565597e472891949ddd5e5f4f4181bf4bf"+
  "c7b1425e0fae985ccc579115efffba7f03bc8dc462daba5cb8c84afb9191aac1aef2019f"+
  "cc3e80231f09c096e56898e5cb3034cda1806ddcb67e016fffa84ba63ef9b90000000049"+
  "454e44ae426082",



#cd /home/husteret/work/SfcUtils/svntree/stuff; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' reload.png

  "reload.png",
  "89504e470d0a1a0a0000000d494844520000001200000012080600000056ce8e57000000"+
  "06624b474400ff00ff00ffa0bda793000000097048597300000b0a00000b0a01bf436653"+
  "0000000774494d4507d30a0d032527af1bdf880000037f49444154789cad545b4c5b0518"+
  "fecee9e9fdc24e5b5784b65c07a3d0aed8a02303dc8264642ed12ccb9e1635c607cd5e48"+
  "966824d1897363cea7252ef36126dec8881a8db2999818966db0718d5d18e9105a0aed2a"+
  "bd1d7a39b43dedb9f80411343ced7ffd2e7ffeffcfff014fa988ddc0333fbd27ed865f3d"+
  "f1e9969eda8d383eff0893fd379011830817bd5829cc602dadc43d2feb1f3a71adfedfdc"+
  "ff181dbcf0e1eb2429e4485e1058cc01640905298984b8849cc461fc6e29ffe7f8e2c04e"+
  "dd9651e7e54fce190c8a0ea7d31c8f141653b73e0f846dcf019224a244e42127b4a00825"+
  "4c16834aa15b19d4786a1fe76603d39b7a1200da2f7ddc6fb7d3a73bdcfbca337cdc3afa"+
  "555049f0a561009000a8253d1e3ce46020cad0542327da3a9b2acb5b6c43da2ec7e12da3"+
  "96b36f7788c5dc2b758d7aba581dda3bb7bca0c987225f27467e0e00c0726a09d76ecffb"+
  "6f0cdfbe38f46bba683102ae063b4e9deeda57efb6ffa07754ef07004a5b663e53f68cec"+
  "80605a979c3a9b7033ecd720972e6c76fa6ce2baffafc0c6f1f4c3183332f31b0b1cbbd8"+
  "d34943309bd0f1d20173f05164d0b4b7b58fa2542a8db28c54e6b021f13ca44395cdd688"+
  "3ddc8529ef94f7835b8477fb4e0767da7d6f98684583b3d904578319ad2fd7f626e342b7"+
  "8cf6bca09644beb7adae914a16b34495d9a29cf3471bd944ea8f12c3c4765ea7c0c31797"+
  "8aafbdd57b584c0a0b88333c99e764922c3a36e65d6789f22a87fbf90a9505453a8be666"+
  "eb9ee9d935bb5a438db67ed46ff3f4f54c689ded57347ac3403ab0aca96ca38fbc7ae8a0"+
  "3a914bf133f311219713e7480028fdfde4cabddf1fc49f245320d27a7096048e9dece9d1"+
  "edaf39df5d55ffcbd9b6ee3a00e0380e04ad35d86d647e69c39789325496899542ec6aec"+
  "4b1900f0a97586953493c1d54497bedc6c5419005d4b86b2599a5a4ff6d6981b94b5f8ee"+
  "fe14d8d8c298de6678ffe8118f2eb361c8fbfc9142262b7e4f30aa6f659bb397222b2b9c"+
  "484cb18270dc55edd6669e5d25ac354ac22437c24656e29bfb9348c54315efbce9520bb2"+
  "3d5c309a1203abc951799cba347e7598dbf622f979ef04e76eecf3f997afd30e4197278a"+
  "5040b1853b5c15d9913b6b21b53a15d1908a69ce2fdebcfbc590f0bfbfe63ef5e205abab"+
  "a82b9132d493b530c20899280700ac3d4e9f67d8341bfd716c71a76e5b8c782e9f930ac1"+
  "f04e0e0040556dc5ecbb03bbc6ce53a97f0027957f8be42fb7fc0000000049454e44ae42"+
  "6082",




#cd /home/husteret/work/SfcUtils/svntree/stuff; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' tool_drop_target.png
  "tool_drop_target.png",
  "89504e470d0a1a0a0000000d49484452000000140000001408060000008d891d0d000000"+
  "06624b474400ff00ff00ffa0bda793000000097048597300000b0f00000b0f0192f903a5"+
  "0000000774494d4507d2061610042bbde675530000041549444154789c7d943d6c535714"+
  "c77ff73dfb3dbf0f3b24b891a338322234a80369688ad2481dba3021c4d0d2a97ba5b274"+
  "6061ead411096582810c08d42512ad84c8c69454401a09241c199236569de7c452b0137f"+
  "bce7f7e1773be0a440538e7475758eeefd9d7ba5fff90bfe27161616c4fefebed16eb7d3"+
  "dd6e5793520a55557d2144db711c6f6e6e2eeef57affb9278e82ddbe7d3bedfbfe742693"+
  "f9d2b2ac69202fa504705aadd66aad56fbbd5aadaedeb871631f901f04deb97327db6ab5"+
  "7e1c1b1bfb667474f454369b554dd3440881e779d4ebf5ded6d6d69fa552e9d762b13837"+
  "3f3fbf03c40760f56dd8fcfcfc60a3d1f8299fcf5f999c9c1c191e1e56a4948461481445"+
  "288ac2e0e0a0323434741cf8acd3e91cb32cebd9fafa7aa70ffd1778f5ead584aeeb3f08"+
  "21ae4c4f4f674cd3a4d96cf2ead52bcae5328ee350afd7d1340d4dd3b06d3b59abd54ee9"+
  "ba1eadadad3deb76bb01201500dbb6453e9f9f89e3f8bb8181812129259d4e07d7756936"+
  "9bef2cd775715d972008c866b3c7868686bebd70e1c2574208131009808b172f26a228fa"+
  "c2308c939aa6e1791e42086ab51a8b8b8b388e03c0c8c808972f5fa65028e0fb3eaaaa62"+
  "59d658369b9db56d7ba5d56a7515807c3e9f11427cac699a9d4aa508c390388e01d0759d"+
  "542a452a9542d77500e238268a2292c924a6691a96659dcce572c340320188300c6d5555"+
  "07755d17a669924c26515595300c2997cb6c6e6e02e079dee1cb5455c5300c0cc310baae"+
  "1fb32c6b10d01200beef934824300c03d334b16d1bd33401a8542abc7cf9f28dc6c41b95"+
  "1dc8c8f77d745d4751141186611250158062b1d81142d452a9542f9d4e93c96490521245"+
  "d1214808715893526259168661904c267bbeef37aad5aa07a0003c7efcb8ebba6e495194"+
  "dd4422411445dcbf7f9f9b376fe2380e524aa4946c6f6f73ebd62d161616088200806eb7"+
  "db741ce7efbdbd3d17e829800c82207cfefcf91f9ee715c330ec699ac6993367f07d9f76"+
  "bb7d28fc4ea743bbdd667c7cfc208f777676ca2b2b2b6b52ca36101c0a7b73733328140a"+
  "f1e8e8e8e7e9743a5d2814387dfa34ebebeb54ab5584104c4d4d71edda35ce9e3d4babd5"+
  "a252a9bc7ef0e0c16f4b4b4bab52ca2da079080c8220ded8d8681886d19e9898981d1818"+
  "489e387182c9c9499e3c79826ddb5cbf7e9d73e7cee1791edbdbdbddbb77effef2f0e1c3"+
  "e52008fe026a40f7ed5156001b98b874e9d2f78b8b8b4b954a65777f7fdf7df1e245f0f4"+
  "e9d3607777d72d954af57bf7eeadcececefe0c7c0d7c0a0c1e8cf1fb6ea30026309acbe5"+
  "4e9e3f7f7e6a6666e6935c2ef7511cc7cad6d6d6def2f272f9d1a3471b8d46a30a6c02db"+
  "400b888e021e4053c00070bcdfdd0692fd4b2eb007bc06eafd6f1edad79106dbafab7d88"+
  "0e68fd3c0602c007c27e830f1bec11e0f7cfc9f7f677e21fb1f6e9b61636a13900000000"+
  "49454e44ae426082",




  "close.png",
  "89504e470d0a1a0a0000000d494844520000000c0000000c080600000056755ce7000000"+
  "06624b474400ff00ff00ffa0bda793000000097048597300000b1300000b1301009a9c18"+
  "0000000774494d4507d60b1d0836307cc61ba0000000384944415428cf6360a000fc2746"+
  "8e118b62463c063132e292c025c648a4b31871598f4d138a1a26524386222791e469a283"+
  "95e488231900007f330f064fe05fed0000000049454e44ae426082",



#cd /home/thus/bindelta/ICONS/; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' minifolder*Ok.png
#  "minifolderOk.png",
#  "89504e470d0a1a0a0000000d49484452000000100000001008060000001ff3ff61000000"+
#  "06624b474400ff00ff00ffa0bda793000000097048597300000b1300000b1301009a9c18"+
#  "0000000774494d4507d6040616060a767c3dd4000000b44944415438cba593d10d83300c"+
#  "449f51f7229b61367326bb7e40684842a1ea49e890a2d8cf07863f65e5c5ddd51ebabb3d"+
#  "aae2ee8a08499c7c54b4237077a59498e744ced179445c35b5a3fbafdac90430d571e49c"+
#  "1f7937bfa46106575e131c05704ecfb722dd08b6f65fcb562e836d66d8bbaaeeae83ea8e"+
#  "e005c0024218861651539981d4127c28a61aa6bd5cd48e516b2358378aab3c228208078a"+
#  "b7bbe08c7f59bfdf253b8539be6c8fb6b1c47073dee90d47950eb10f1ee55c0000000049"+
#  "454e44ae426082",
#
#  "minifolderopenOk.png",
#  "89504e470d0a1a0a0000000d49484452000000100000001008060000001ff3ff61000000"+
#  "06624b474400ff00ff00ffa0bda793000000097048597300000b1300000b1301009a9c18"+
#  "0000000774494d4507d60406160c245045d891000001314944415438cba593b14a034110"+
#  "86bfd510d2a71453188882489ec0d687c823a4b7de59ac04c12e36d6d75ceb1358db4452"+
#  "b8d70a82450aab2442188bdcdeed5d2e18f1876338d899ff9b1906fe2913ff586bb5fec0"+
#  "3967f6aa64add52635158dd50ac9224296650c06a764992fa28800341629e84a77d47bdf"+
#  "107792e9415c3176aec60c30b5980f31f4688ca1dd5eb05a757e9d978843c4e29c2bf187"+
#  "0f4345d0ee6d57c74f6355fdda89edbdafb6d0bbef31fd9c02305fcc99bc4c38be3bdfc2"+
#  "167100244912f15cf38ca0288a6cbea0ce4d676ba0c1b92478e7120b9a6f4af3b51b6758"+
#  "ae97f4fb2795818e46a3da44ae36eeb1020982023a9bcd2a24c11dd016dfbce138c35238"+
#  "d795a629696a8104c2c3e8162e105e9bf7b5df311d02eb1cb79efc011cfde53a97a137e0"+
#  "719f841ffd1e239c73c1a20e0000000049454e44ae426082",



  "minidoc.png",
  "89504e470d0a1a0a0000000d49484452000000100000001008000000003a98a0bd000000"+
  "0274524e5300bf2d4d632500000002624b474400bd1f5dec030000003b4944415478dab5"+
  "8c410a003008c3faf33ecda7b9758a14ef0bd443082216d00a1329da94209948ece23553"+
  "f01ed00b45f4426fbe16438be0d0c23957a49fedddc4470f0000004374455874536f6674"+
  "776172650040282329496d6167654d616769636b20342e322e392039392f30392f303120"+
  "637269737479406d79737469632e65732e6475706f6e742e636f6dede8d9f00000002a74"+
  "4558745369676e6174757265006634623938353530663364666364343832653531633638"+
  "3730323336653464321471a8e1000000097445587444656c6179003130305c19840f0000"+
  "000049454e44ae426082",

  "minifolderopen.png",
  "89504e470d0a1a0a0000000d4948445200000010000000100403000000eddde252000000"+
  "12504c5445b2c0dc7f7f7fffffffd9d9d9ffff00000000e3fe1aa70000000174524e5300"+
  "40e6d86600000001624b474405f86fe9c7000000564944415478da636080034641410843"+
  "484949002ca0ececac282828c0c0a8626262a4a4240a16010251064130101105a9555252"+
  "0c06324c402010a6465414accbc4c45414682048c4319401aa0dc8600d0503060c0000ae"+
  "eb0e606e70156a0000004374455874536f6674776172650040282329496d6167654d6167"+
  "69636b20342e322e392039392f30392f303120637269737479406d79737469632e65732e"+
  "6475706f6e742e636f6dede8d9f00000002a744558745369676e61747572650035323662"+
  "38316339313534376138653561333863313832613034303032646166d58b1bf600000009"+
  "7445587444656c6179003130305c19840f0000000049454e44ae426082",

  "minifolder.png",
  "89504e470d0a1a0a0000000d4948445200000010000000100403000000eddde252000000"+
  "12504c5445b2c0dc808080c0c0c0ffff00ffffff00000097b0885f0000000174524e5300"+
  "40e6d86600000001624b474405f86fe9c70000003d4944415478da6360800341410130cd"+
  "a8acac086608191919090a0a323088b88080630083881108180219ca20a048a288200404"+
  "30b0868241000306000056b71061cb3761e40000004374455874536f6674776172650040"+
  "282329496d6167654d616769636b20342e322e392039392f30392f303120637269737479"+
  "406d79737469632e65732e6475706f6e742e636f6dede8d9f00000002a74455874536967"+
  "6e6174757265006639643364613832633735346265623361346561386238653830373132"+
  "66653269b79a59000000097445587444656c6179003130305c19840f0000000049454e44"+
  "ae426082",

#cd /opt/kde3/share/icons/crystalsvg/32x32/apps/; ruby -e 'while f=$*.shift do puts "  \"#{f}\",\n  \""+File.open(f).read.unpack("H*")[0].scan(/.{1,72}/).join("\"+\n  \"")+"\",\n\n" end' error.png
  "error.png",
  "89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af4000000"+
  "0467414d410000b18f0bfc61050000012249444154789cb596e10ec3200884cf3eec7c26"+
  "f7b2eccf48aa41bcab956459d221f781c05a20980196fd5e80a2c4fb9fd917de01491d55"+
  "e1272053875d7116e23a29eeb15a6b7c3c03ecc4878238254e41a487cd78a185ef0811f6"+
  "404f66fdf75bbe54f691bde07baf425e81124c50945df42c3a2b65cf66a75429a8c2ba07"+
  "b24aec64eeeed2d259359720fe6d0d005b014640ccdc4d0338601a407605eaeccb00ca22"+
  "7a1d60d6edec9e48ac00c8ff7e995113c7d127a0d65af20ab081372a7101c95bcb185819"+
  "c389af67df01a4e6819839177c6bada50348dfdd942543dc7de73e3e9056b3607771cf1e"+
  "08ae20a23c250e4ccade5ab34fadc7c5a7006f41acc453008700001564bcc699f8124005"+
  "89fa2713a7014610c656c28f00181056d8ed078249ad33757972e90000000049454e44ae"+
  "426082",
}

$icnCache={}
def iconFromDat(name,*iconTabs)
  return $icnCache[name] if $icnCache[name]
  (iconTabs+[SOME_ICONS]).each{|iconTab|
    name=~/\.([^.]+)$/ or raise "bad extension in '#{name}'"
    ext=$1.upcase
    dat=iconTab[name]
    if dat
      dat=[dat].pack('H*')
      cmd="FX#{ext}Icon.new($app,dat)"
      icn=eval(cmd)
      icn.create
      return $icnCache[name]=icn
    end
  }
  raise "cannot find icon #{name}"
  return nil
end
#TRANS_COL=IS_WINDOWS ? 0xffffff : 0x55555
TRANS_COL=0xffffff
class FXIcon
  def overlay(icn2)
    w=width
    h=height
    icn = FXIcon.new(app,nil,TRANS_COL,0,w,h)
    #dat=SOME_ICONS["minifolder.png"]
    #icn = FXPNGIcon.new(app,[dat].pack('H*'))
    #self.transparentColor=TRANS_COL
    icn.transparentColor=TRANS_COL
    #puts "w=#{w} h=#{h} transcol=#{self.transparentColor}"
    icn.create
    dc = FXDCWindow.new(icn)
    dc.fillStyle=FILL_SOLID
    dc.foreground = TRANS_COL #transparentColor#TRANS_COL#0
    dc.fillRectangle(0,0,w,h)
    dc.drawIcon(self,0,0)
    dc.drawIcon(icn2,0,0)
    dc.end
    icn.restore
    icn.render
    icn
  end
end


class TxtReader < FXDialogBox
  def initialize(owner,txt="",title="Reader",width=80,height=25,attr=TEXT_READONLY|TEXT_WORDWRAP|TEXT_AUTOSCROLL)
    super(owner, title, DECOR_ALL, 10,10,500,500, 6, 6, 6, 6, 4, 4)
    persSize()
    #owner.getApp,title,10,10,500,500){|x, y, w, h|  }
    @buttonBox=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, 0,0,0,0, 0,0,0,0, 0,0)
    @text = FXText.new(self, nil, 0,LAYOUT_FILL_X|LAYOUT_FILL_Y|attr)
    @text.visibleRows = height
    @text.visibleColumns = width
    self.text=txt
  end
  def text=(txt)@text.text=txt;    end
  def text()    @text.text;         end
  def method_missing(*args)
    @text.send(*args)
  end
end
class TxtEditor < TxtReader
  def initialize(owner,txt="",title="Editor",width=80,height=25)
    super
    FXButton.new(@buttonBox, "&Ok", nil,  self, FXDialogBox::ID_ACCEPT,
      FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_FIX_WIDTH,0,0,100)
    FXButton.new(@buttonBox, "&Cancel", nil,  self, FXDialogBox::ID_CANCEL,
      FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_FIX_WIDTH,0,0,100)
    @text.editable=true
  end
end

class FilterCombo #kleine Auswahlbox mit Editdialog
  class EditFilterDialog < FXDialogBox
    def initialize(parent,title)
      #super(parent,title,DECOR_ALL,10,10,400,300)
      super(parent,title,DECOR_ALL,10,10,400,300)
      persSize()#parent.getApp,title,10,10,400,300){|x, y, w, h|  }

      FXLabel.new(self,"Name:")
      @editName = FXComboBox.new(self, 10, nil, 0,
               COMBOBOX_REPLACE|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
      @editName.numVisible=10
      @editName.connect(SEL_COMMAND){|*args|
        @editName.setItemData(@curr,@editTxt.text)
        @curr=@editName.currentItem
        if @editName.text=='NEW'
          @editName.setItem(@curr,'name','x=~//i')
          @editName.appendItem("NEW",nil)
        end
        @editTxt.text = @editName.getItemData(@curr)
      }

      buttons = FXHorizontalFrame.new(self,
               LAYOUT_SIDE_BOTTOM|FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
               0, 0, 0, 0, 40, 40, 20, 20)
      FXButton.new(buttons, "&Ok", nil,  self, FXDialogBox::ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH,0,0,100)
      FXButton.new(buttons, "&Cancel", nil,  self, FXDialogBox::ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH,0,0,100)
      FXLabel.new(self,"Filter: (Ruby expr with variable 'x'):")
      @editTxt=FXText.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    end
    def execute(data,index)
      @editName.clearItems; 
      data.each{|title,code| @editName.appendItem(title,code)}
      @editName.appendItem("NEW",nil)
      @editName.currentItem=@curr=index
      @editName.text,@editTxt.text= data[@curr]

      return nil  if super()!=1
      @editName.setItemData(@curr,@editTxt.text)
      data=[]; @editName.each{|*kv| data<<kv if kv[1]}
      return [data,@curr]
    end
  end
  def initialize(parent,title,defaults)
    FXLabel.new(parent,title+":").textColor=FXColor::DarkRed
    @combobox = FXComboBox.new(parent, 10, nil, 0,
    COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
    @combobox.numVisible=10
    @data=$app.reg.get("Filters:#{title}:dat",defaults){ @data }
    @data.pop if @data.last[0]=='-'
    @curr =$app.reg.get("Filters:#{title}:curr",0){ @curr }
    @combobox.connect(SEL_COMMAND){|*args|
      @curr=@combobox.currentItem
      @block.call(@data[@curr][1])
    }
    @data.each{|name,code| @combobox.appendItem(name) }
    @curr=[@curr,@data.length-1].min
    @combobox.currentItem=@curr
    #watchAllSELs(comboTxt,%w(SEL_UPDATE))
    
    @editDial=EditFilterDialog.new(parent,"Edit '#{title}'-Filter")

    comboTxt=@combobox.first
    comboTxt.connect(SEL_LEFTBUTTONPRESS){
      $app.endWaitCursor
      if ret=@editDial.execute(@data,@curr)
        @data,@curr=ret
        @combobox.clearItems
        @data.each{|title,code| @combobox.appendItem(title) }
        @combobox.currentItem=@curr
        @combobox.handle(nil,MKUINT(FXComboBox::ID_TEXT,SEL_COMMAND),"")
      end
      $app.beginWaitCursor
    }
    @block=Proc.new{}
  end
  def connect(&block)
    @block=block
    @combobox.handle(nil,MKUINT(FXComboBox::ID_TEXT,SEL_COMMAND),"")
  end
end

def fxSplit(rgb)
  [FXREDVAL(rgb),FXGREENVAL(rgb),FXBLUEVAL(rgb)]
end
def hsv2rgb(h,s,v) # 0..360, 0..100, 0..100
  s=s/100.0 #0..1
  v=v*2.55  #0..255
  if s==0.0 then return [v,v,v]
  else
    h=0.0  if h==360.0
    h=h/60.0;
    i=h.to_i;
    f=h-i;
    w=v*(1.0-s);
    q=v*(1.0-(s*f));
    t=v*(1.0-(s*(1.0-f)));
    case i
      when 0; [v,t,w]; when 1; [q,v,w]; when 2; [w,v,t];
      when 3; [w,q,v]; when 4; [t,w,v]; when 5; [v,w,q];
    end
  end
end

def rgb2hsv(r,g,b)
  v=[r,g,b].max
  t=[r,g,b].min
  delta=v.to_f-t
  if v != 0.0 then  s=delta/v    else    s=0.0  end
  if s==0.0
    h=0.0 
  else
    if r==v     then      h=(g-b)/delta;
    elsif(g==v) then      h=2+(b-r)/delta;
    elsif(b==v) then      h=4+(r-g)/delta;
    end
    h=h*60;
    h=h+360 if h<0.0
  end
  [h.to_i,(s*100).to_i,(v/2.55).to_i]
end



if Fox::fxrubyversion() =~ /1\.0\./
  class FXMenuRadio < FXMenuCommand
    def check=(val) val ? checkRadio : uncheckRadio end
  end
  class FXMenuCheck < FXMenuCommand
    def check=(val) val ? check : uncheck end
  end
end


