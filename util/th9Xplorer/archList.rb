require "fxList2"
#require 'rexml/parsers/sax2parser'
#require "parsedate"
require "fileutils"
#include FileUtils


class FXListArchItem < FXListGenericItem
    #attr_accessor :txt, :icon, :lev #, :list
  attr_reader :dir,:name,:kind
  def initialize(alist,kind,icon,dir,name,size,date)#,lev)#,isDir)
    @alist,@kind,@icon,@dir,@name,@size,@date=alist,kind,icon,dir,name,size,date
    @selected=false
  end
  def path(name=@name)
    @dir+"/"+name
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
  LPAD=4
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
    when :Name
      if @name
        x=8+drawTreeIcon(dc,x,y,w,h,@icon,bgCol) if @icon
        dc.drawText(x,y+(h-th)/2+asc,@name)
      end
    when :Size
      dc.drawText(x,y+(h-th)/2+asc,@size.to_s)if @size
    when :Date
      dc.drawText(x,y+(h-th)/2+asc,@date.strftime("%y.%m.%d-%H:%M:%S"))if @date
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
    case FXSELTYPE(sel)
    when SEL_RIGHTBUTTONPRESS
      raise "handled in main obj"
    when SEL_LEFTBUTTONPRESS
      #if @selected
      #  #start drag
      #  return true
      #end
      case hindex
      when :Size
        # puts @alist.readFile(@dir+"/"+@name)
      when :Name
        return super(hindex,dx-LPAD,dy,sender,sel,event)
      end
    end
    false
  end
end

class OrgaList < FXList2
  def initialize(parent,fileSys,opened=true)
    @fileSys,@opened=fileSys,opened
    @myId = "orgaList#{rand(10000)}"
    super(parent,LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN,@myId,:SB,0,0,0,0,0,0,0,0, 0,0) # x y w h  l r t b  h v
    @list=self
    @list.backColor = parent.backColor
    # @list.appendHeader("",  iconFromDat("flag.png"), 24, :Marks)
    # @list.appendHeader("Icon",  nil,  40,:Icon)
    @list.appendHeader("Name",  nil, 200,:Name)
    @list.appendHeader("Size",  nil,  40,:Size)
    @list.appendHeader("Date",  nil, 150,:Date)
    # @list.connect(SEL_KEYPRESS){|sender,sel,event|
    #  @keyDispatcher.onKeypress(event.code,event.state,event.time)
    #}
    @mpop = FXPopup.new(self)
    #FXMenuCaption.new(@mpop,"Caption")
    #FXMenuSeparator.new(@mpop)
    

    FXMenuCommand.new(@mpop,"New Folder").connect(SEL_COMMAND){|sender,sel,event|
    }
    FXMenuCommand.new(@mpop,"Rename..").connect(SEL_COMMAND){|sender,sel,event|
      @list.items.each_with_index{|item,i|
        if item.selected?
          s = item.name
          k=item.kind == :file ? "File" : "Folder"
          s = FXInputDialog.getString(s, self, "Rename #{k}","from: #{s} to:",nil) 
          if s and s != item.name
            @fileSys.mv item.path(),item.path(s)
          end
        end
      }
      @list.killSelection()
      refresh()
    }
    FXMenuCommand.new(@mpop,"Delete").connect(SEL_COMMAND){|sender,sel,event|
      @list.items.each_with_index{|item,i|
        if item.selected?
          @fileSys.rmFile(item.path())
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


    @list.connect(SEL_DND_REQUEST){|sender,sel,data|
      # drag-src: daten an drop target ausliefern
      mode,*idxRest = data
      ret=[]
      idxRest.each{|sidx|
        ret << [@list.items[sidx].name,@fileSys.readFile(idx2Path(sidx))]
        @list.selectItem(sidx,false)
        if mode == DRAG_MOVE
          @fileSys.rmFile(idx2Path(sidx))
          #puts "move deletes orig"
          break #move only the first of selection
        end
      }
      #puts "#{@myId} SEL_DND_REQUEST #{ret}"
      ret
    }
  #drag ^^^^^^^^^^^^^^^^^^
  #drop vvvvvvvvvvvvvvvvv

    @list.connect(SEL_DND_MOTION){|sender,sel,data|
      # drop-tgt: action an drag-src liefern
      index,item,srcId = data
      #puts "#{@myId} MOTION #{srcId} #{item}"
      ret=DRAG_REJECT
      if item and @fileSys.allowedDrop
	if srcId==@myId
	  ret=DRAG_MOVE
	else
	  ret=DRAG_COPY
	end
      end
      ret
    }
    @list.connect(SEL_DND_DROP){|sender,sel,data|
      # drop-tgt: drop ausfuehren
      #puts "SEL_DND_DROP"
      #pp data
      dsti,list = data
      if dsti and item=@list.items[dsti] #only if item exists
        # @rcFiles[dsti+1]=name_contents
        p=item.dir+"/"
        p+=item.name+"/" if item.kind==:dir
        list.each{|name,contents| #=name_contents
          @fileSys.addFile(p+name,contents)
        }
      end
      #p+=name
      # @list.selectItem(dsti,true)
      #pp @rcFiles
      refresh()
    }
    refresh()
  end
  def fileSys=(fs)
    @fileSys=fs
    refresh
  end

  def idx2Path(idx)
    item=@list.items[idx]
    item.path()
  end
  def refresh
    @list.clear
    readDir(".",nil)
    @list.update
  end

  def readDir(dir,parent)
    #puts "def readDir(#{dir},parent)"
    files=[]
    dirs=[]
    #Dir["#{@fileSys}/#{dir}/*"].each{|n|
    #  next if n=~/\/\.\.?$/
    @fileSys.each(dir){|name,stat,isdir,path|
      #name=File.basename(n)
      size=stat.size
      date=stat.mtime
      if isdir #File.directory?(n)
        dirs  << it=FXListArchItem.new(self,:dir,$minifolder,dir,name,0,date)
        #it.collapsed = true #! @opened
      else
        files << FXListArchItem.new(self,:file,$minidoc,dir,name,size,date)
      end
    }
    dirs.sort{|a,b|a.name<=>b.name}.each{|di| 
      @list.appendItem(parent,di) 
      readDir(dir+"/"+di.name,di)
    }
    files.sort{|a,b|a.name<=>b.name}.each{|fi| @list.appendItem(parent,fi) }
    if ! parent and ! @opened
      @list.collapseSubtrees
    end
  end
end

class FileSystem
  attr_reader :allowedDrop
  def initialize(baseDir,allowedDrop=true)
    @baseDir = baseDir
    @allowedDrop = allowedDrop
  end
  def path(dir=nil)
    dir ? @baseDir+"/"+dir : @baseDir
  end
  def each(dir)
    return if ! @baseDir # empty dummy  filesys
    Dir[path(dir)+"/*"].each{|n|
      next if n=~/\/\.\.?$/
      yield File.basename(n),File.stat(n),File.directory?(n),n
    }
  end
  def addDir(dir)
    return nil if ! @baseDir # empty dummy  filesys
    FileUtils::mkdir_p(p=path(dir))
    p
  end
  def mv(from,to)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::mv(path(from),path(to))
  end
  def rmFile(dir)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::rm(path(dir))
  end
  def readFile(dir)
    return nil if ! @baseDir # empty dummy  filesys
    File.read(path(dir))
  end
  def addFile(dir,contents)
    return if ! @baseDir # empty dummy  filesys
    File.open(path(dir),"w"){|f| f.write(contents) }
  end
  def copyLazy(srcFs,srcDir,dstDir)
    return if ! @baseDir # empty dummy  filesys
    puts "def copyLazy(#{srcFs},#{srcDir},#{dstDir})"
    #srcFs.path(srcDir)
    dd=addDir(dstDir)
    srcFs.each(srcDir){|bn,stat,isdir,path|
      if isdir
        copyLazy(srcFs,srcDir+"/"+bn,dstDir+"/"+bn)
      else
        File.link(path,dd+"/"+bn)
      end
    }
  end
end

class ArchList < FXGroupBox

  def createArch(repo)
    mkdir_p(repo+"/Hangars/Hangar1")
    mkdir_p(repo+"/Hangars/Hangar2")
    mkdir_p(repo+"/Hangars/Hangar3")
    mkdir_p(repo+"/Archive")
  end
  def tryOpenArch(arch)
    ah=arch+"/Hangars"
    aa=arch+"/Archive"
    return false if not (File.exists?(ah) and File.exists?(aa))
    @arch=arch
    @repoHangar  = FileSystem.new(ah)
    @repoArchive = FileSystem.new(aa,false)
    @hangList.fileSys = @repoHangar
    @archList.fileSys = @repoArchive
    @parent.parent.title = "th9Xplorer - #{@arch}"
    true
  end
  def newArch()#menu
    arch=FXFileDialog.getSaveFilename(self, "Create new Workspace", @arch||Dir.pwd+"/th9Xarch.txa", patterns="*.txa", initial=0) 
    arch+=".txa" if not arch=~/\.txa$/
    createArch(arch)
    tryOpenArch(arch)
  end
  def openArch()#menu
    arch=
      FXFileDialog.getOpenDirectory(self, 
				    "Open Workspace",
				    @arch||Dir.pwd)
    tryOpenArch(arch)
  end

  def initialize(parent)
    super(@parent=parent, "Organizer" ,LAYOUT_FILL_X|LAYOUT_FILL_Y|GROUPBOX_NORMAL|GROUPBOX_TITLE_CENTER|FRAME_RIDGE, 0,0,0,0, 10,10,0,5, 0,0) # x y w h  l r t b

    @arch=nil
    @repoHangar  = FileSystem.new(nil)
    @repoArchive = FileSystem.new(nil,false)

    # @arch="file:///home/thus/tmp/svn/arch/"
    #repo = "./th9xData"
    #createRepo(repo)
    #openRepo(repo)


    tabBook = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

    tab1      = FXTabItem.new(tabBook, "Hangar")
    @hangList = OrgaList.new(tabBook,@repoHangar)

    tab2      = FXTabItem.new(tabBook, "Archive")
    @archList = OrgaList.new(tabBook,@repoArchive,nil) #keep all closed
    arch = getApp().reg.get("ArchList:arch",nil){
      @arch
    }
#p arch
    if not arch
      app.addChore{newArch}
    else
      if not tryOpenArch(arch)
	app.addChore{openArch}
      end
    end
  end
  def save(rcFiles)
    dateDir=Time.new.strftime("%y.%m.%d-%H:%M:%S")
    # @repoArchive.addDir(dateDir)
    @repoArchive.copyLazy(@repoHangar,"./",dateDir)
    rcdir = dateDir+"/rc"
    @repoArchive.addDir(rcdir)
    rcFiles.each_with_index{|nc,idx| name,contents=nc; idx+=1
      @repoArchive.addFile(rcdir+"/%02d_%s"%[idx,name],contents) if name
    }
    @archList.refresh
  end
end
