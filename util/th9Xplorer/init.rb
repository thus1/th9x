#! /usr/bin/env ruby
=begin
 * Author	Thomas Husterer <thus1@t-online.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
=end

$opt_v=2

require 'fox16'
require 'fox16/colors'
require 'pp'
require "rubyscript2exe"

$: << RUBYSCRIPT2EXE.appdir
#pp $:
require "foxAdd"  # sets $FOX_VER
#require "fxList2"
require "rcList"
require "archList"
require "pref"

=begin
+ log
+ new,open
- preferences avrdude
- help
- write eeprom
- progressbar
- multiselect
- rename dir/file
- new dir
- compare arch-rc > disk=need save
=end







FR0=FRAME_RAISED|FRAME_THICK
FR1=FRAME_SUNKEN|FRAME_THICK
class Th9x < FXMainWindowPersSize
  def initialize(app)
    super(app, "th9Xplorer", nil, nil, DECOR_ALL,
          20, 20, 700, 500,*[0]*6)

    $log=TxtReader.new(self)
    $log.title="Log View"

    @menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|FR0)
    filemenu = FXMenuPane.new(self)
    FXMenuTitle.new(@menubar, "&File", nil, filemenu)
    FXMenuCommand.new(filemenu, "&New").connect(SEL_COMMAND) {
      @archList.newArch()

      #raise "not implemented"
    }
    FXMenuCommand.new(filemenu, "&Open").connect(SEL_COMMAND) {
      @archList.openArch()
      #raise "not implemented"
    }
    FXMenuSeparator.new(filemenu)
    FXMenuCommand.new(filemenu, "&Save\tCtl-S").connect(SEL_COMMAND) {
      save
    }
    FXMenuSeparator.new(filemenu)
    FXMenuCommand.new(filemenu, "&Exit\tCtl-Q").connect(SEL_COMMAND) {
      close
    }


    editmenu = FXMenuPane.new(self)
    FXMenuTitle.new(@menubar, "&Edit", nil, editmenu)
    FXMenuSeparator.new(editmenu)
    FXMenuCommand.new(editmenu, "Edit &Preferencs").connect(SEL_COMMAND) {
      editPrefs
    }


    helpmenu = FXMenuPane.new(self)
    FXMenuTitle.new(@menubar, "&Help", nil, helpmenu)
    FXMenuCommand.new(helpmenu, "&About th9Xplorer").connect(SEL_COMMAND) {
      FXMessageBox.information(self, MBOX_OK, "About th9Xplorer", "This is V0.1 of th9Xplorer\nCopyright (C) 2011 thus") 
    }
    FXMenuSeparator.new(helpmenu)
    FXMenuCommand.new(helpmenu, "&View Log").connect(SEL_COMMAND) {
      $log.show()
    }

    hf=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y, 0,0,0,0, 15,15,5,10, 40,20)

    @prefDialog = PrefDialog.new(self)
    @archList = ArchList.new(hf)
    @rcList   = RcList.new(hf)
    @rcList.connect(SELUSER_RCLOADED){|sender,sel,data|
      puts "SELUSER_RCLOADED"
      save
    }

  end
  def create
    super                  # Create the windows
    show(PLACEMENT_VISIBLE) #(PLACEMENT_SCREEN) # Make the main window appear
  end
  def save()
    @archList.save(@rcList.getFiles)
  end
  def editPrefs
    @prefDialog.execute
  end
end


def main
  initTmpDirs
  $app = FXApp.new('th9Xplorer', 'thus')
  if IS_WINDOWS
    $app.normalFont = FXFont.new($app, "Terminal", 10, FONTPITCH_FIXED|FONTWEIGHT_NORMAL)#LIGHT)
  else
    $app.normalFont = FXFont.new($app, "fixed", 10, FONTWEIGHT_BOLD)
  end
  $minidoc          = iconFromDat("minidoc.png")
  $minifolder       = iconFromDat("minifolder.png")
  #FXFileStream.open("th9Xplorer/thgx-icn-128x128.png",FXStreamLoad){|fs|
  #  $icnth9x          = FXPNGIcon.new($app,nil,FXColor::White)
  #  $icnth9x.loadPixels(fs)
  #  $icnth9x.create
  # p fs,$icnth9x
  #}
  $icnth9x         = iconFromDat("th9x-icn-128x128.png")

  $dndTypeIdentify= $app.registerDragType("application/identify#$$")#"text/uri-list"
  $dndTypeRcData = $app.registerDragType("application/rcdata#$$")#"text/uri-list"


  th9x=Th9x.new($app)
  FXToolTip.new($app)
  $app.tooltipPause=100
  $app.create

  Fox::FXPseudoTarget.startExcCatcher($app,th9x)
  $app.run if ! RUBYSCRIPT2EXE.is_compiling?
end
main
