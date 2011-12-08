
require "md5"




module ModelFileUtils #for include in archList and rcList

  def renameFileDialog(content,isFolder=nil)
    name = content[1,10].strip
    s    = FXInputDialog.getString(name, self, "Rename File","from: #{name} to:",nil) 
    if s and s != name
      content[1,10] = (s+(" "*10))[0,10]
      return content
    end
    return nil
  end

  def showModelData(item)
    if item and item.kind == :file
       # showModelData( @fileSys.readFile(item.path()) )
      filecontents = item.readFile()
      $modeldata.text=Reader_V4.file_to_s(filecontents)
      $modeldata.show
    end
  end
  def onClicked(sender,sel,data)
    event,item=data
    if event.click_count==2
      #if item and item.kind == :file
      showModelData( item )
      #end
      true #processing complete
    else
      false
    end
  end
end

class FileSystem
  attr_reader :allowedDrop
  def initialize(baseDir,allowedDrop=true)
    @baseDir     = baseDir
    @allowedDrop = allowedDrop
  end
  def _path(dir=nil)
    dir ? @baseDir+"/"+dir : @baseDir
  end
  #private :_path
  def each(dir)
    return if ! @baseDir # empty dummy  filesys

    #puts "each(#{dir}) #{_path(dir)}"
    #pp Dir[_path(dir)+"/*"]
    Dir.chdir(@baseDir){
      Dir[dir+"/*"].each{|n|
        #pp n
        next if n=~/\/\.\.?$/
        next if ! File.directory?(n)
        yield nil,File.basename(n),File.stat(n),File.directory?(n) ,n
      }
      Dir[dir+"/*"].each{|path|
        next if path=~/\/\.\.?$/
        next if File.directory?(path)
        bn=File.basename(path)
        next if bn !~ /^(\d{3})_(.*)/
        nr,bn=$1.to_i,$2
        name = Reader_V4.mbuf2name(readFile(path))
        yield nr,name,File.stat(path),File.directory?(path) ,path
      }
    }
  end
  def mv(from,to)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::mv(_path(from),_path(to))
  end
  def rmDir(relPath)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::Verbose::rmdir(_path(relPath))
  end
  def rmFile(relPath)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::Verbose::rm(_path(relPath))
  end
  def readFile(relPath)
    return nil if ! @baseDir # empty dummy  filesys
    File.open(_path(relPath),"rb"){|f|f.read}
  end
  def addFile(relPath,nr,contents)
    return nil if ! @baseDir # empty dummy  filesys
    name=MD5.new(contents)
    d=relPath+"/%03d_#{name}"%nr
    File.open(_path(d),"wb"){|f| f.write(contents) }
    name = Reader_V4.mbuf2name(contents)
    return [d,name]
  end
  def addDir(relPath)
    return nil if ! @baseDir # empty dummy  filesys
    FileUtils::mkdir_p(p=_path(relPath))
    p
  end
  def copyLazy(srcFs,srcRelPath,dstRelPath)
    return if ! @baseDir # empty dummy  filesys
    #puts "def copyLazy(#{srcFs},#{srcRelPath},#{dstRelPath})"
    #srcFs._path(srcRelPath)
    dd=addDir(dstRelPath)
    srcFs.each(srcRelPath){|nr,bn,stat,isdir,relPath| #|bn,stat,isdir,p|
      bn=File.basename(relPath)
      if isdir
        copyLazy(srcFs,srcRelPath+"/"+bn,dstRelPath+"/"+bn)
      else
        File.link(srcFs._path(relPath),dd+"/"+bn)
      end
    }
  end
end





class FileSystemOld
  attr_reader :allowedDrop
  def initialize(baseDir,allowedDrop=true)
    @baseDir = baseDir
    @allowedDrop = allowedDrop
  end
  def _path(dir=nil)
    dir ? @baseDir+"/"+dir : @baseDir
  end
  private :_path
  def each(dir)
    return if ! @baseDir # empty dummy  filesys
    Dir[_path(dir)+"/*"].each{|n|
      next if n=~/\/\.\.?$/
      yield nil,File.basename(n),File.stat(n),File.directory?(n) ,n
    }
  end
  def addDir(dir)
    return nil if ! @baseDir # empty dummy  filesys
    FileUtils::mkdir_p(p=_path(dir))
    p
  end
  def mv(from,to)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::mv(_path(from),_path(to))
  end
  def rmFile(dir)
    return if ! @baseDir # empty dummy  filesys
    FileUtils::rm(_path(dir))
  end
  def readFile(dir)
    return nil if ! @baseDir # empty dummy  filesys
    File.open(_path(dir),"rb"){|f|f.read}
  end
  def addFile(dir,contents)
    return if ! @baseDir # empty dummy  filesys
    File.open(_path(dir),"wb"){|f| f.write(contents) }
  end
  def copyLazy(srcFs,srcDir,dstDir)
    return if ! @baseDir # empty dummy  filesys
    #puts "def copyLazy(#{srcFs},#{srcDir},#{dstDir})"
    #srcFs._path(srcDir)
    dd=addDir(dstDir)
    srcFs.each(srcDir){|nr,bn,stat,isdir| #,__p|
      if isdir
        copyLazy(srcFs,srcDir+"/"+bn,dstDir+"/"+bn)
      else
        File.link(srcDir+"/"+bn,dd+"/"+bn)
      end
    }
  end
end

