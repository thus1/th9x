

class  PrefDialog < FXDialogBox
  def initialize(owner)
    super(owner,"Preferences", DECOR_ALL, 10,10,0,0, 6, 6, 6, 6, 4, 4)
    #persSize()
    hfb=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|
        PACK_UNIFORM_WIDTH, 0,0,0,0, *[5]*6)
    ok=FXButton.new(hfb, "&Ok", nil,  self, FXDialogBox::ID_ACCEPT,
                    FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT,0,0,0)
    cnc=FXButton.new(hfb, "&Cancel", nil,  self, FXDialogBox::ID_CANCEL,
                     FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT,0,0,0,0,10,10)

    gb1=FXGroupBox.new(self, "avrdude" ,LAYOUT_FILL_X|GROUPBOX_NORMAL|GROUPBOX_TITLE_CENTER|FRAME_RIDGE, 
                         0,0,0,0, 0,0,0,0, 0,0) # x y w h  l r t b  h v

    @getSetProcs={}

    exe  = RUBYSCRIPT2EXE.appdir 
    exe += IS_WINDOWS ? "/avrdude.exe" : "/avrdude"
    conf = RUBYSCRIPT2EXE.appdir + "/avrdude.conf"
    
    matrix = FXMatrix.new(gb1, 2,LAYOUT_FILL_X|FRAME_RAISED|LAYOUT_TOP|MATRIX_BY_COLUMNS)
    [
     [:AVRDUDEPATH,     "Avrdude Exe with path",   exe],
     [:AVRDUDECONF,     "Avrdude conf file",       conf],
     [:AVRDUDEPROGARGS, "Programmer Args",["-c usbtiny","-c usbasp","-c stk500v2 -P com4"]],
    ].each{|tag,lab,vals|
      lb=FXLabel.new(matrix,lab)
      if tag==:AVRDUDEPATH or tag==:AVRDUDECONF
        hf=FXHorizontalFrame.new(matrix, LAYOUT_FILL_X, *[0]*10)
        tf=FXTextField.new(hf,80)
        tf.text = vals
        b1=FXButton.new(hf,"",$minifolder,nil, 0, BUTTON_NORMAL,*[0]*8)
        b1.connect(SEL_COMMAND){|sender,sel,event|
          #puts "SEL_COMMAND",cb.getItemData(cb.currentItem)
          ret = FXFileDialog.getOpenFilename(self, lab, tf.text, "*", 0) 
          tf.text = ret if ret != ""
        }
        getProc,setProc = proc{tf.text},proc{|tf.text|}
      else
        cb=FXComboBox.new(matrix, 80, nil, 0,
                          LAYOUT_FILL_X|COMBOBOX_REPLACE|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
        cb.numVisible=5
        vals.each{|v|cb.appendItem(v) }
        getProc,setProc = proc{cb.text},proc{|cb.text|}
      end
      @getSetProcs[tag] = [ getProc,setProc ]

      v = getApp().reg.get("PrefDialog:#{tag}",getProc.call){  getProc.call   }
      setProc.call(v)
      
    }
  end
  def getVal(tag)
    @getSetProcs[tag][0].call
  end
  def execute()
    save={}
    @getSetProcs.each{|k,v| getProc,setProc=v
      save[k]=getProc.call
    }
    ret=super
    pp ret
    if ret!=1 #restore the values if not pressed OK
      @getSetProcs.each{|k,v| getProc,setProc=v
        setProc.call( save[k] )
      }
    end
  end
end
