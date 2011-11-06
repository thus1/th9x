

class  PrefDialog < FXDialogBox
  def initialize(owner)
    super(owner,"Preferences", DECOR_ALL, 10,10,500,400, 6, 6, 6, 6, 4, 4)
    persSize()
    hfb=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|
        PACK_UNIFORM_WIDTH, 0,0,0,0, *[5]*6)
    ok=FXButton.new(hfb, "&Ok", nil,  self, FXDialogBox::ID_ACCEPT,
                    FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT,0,0,0)
    cnc=FXButton.new(hfb, "&Cancel", nil,  self, FXDialogBox::ID_CANCEL,
                     FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT,0,0,0,0,10,10)

    gb1=FXGroupBox.new(self, "avrdude" ,LAYOUT_FILL_X|GROUPBOX_NORMAL|GROUPBOX_TITLE_CENTER|FRAME_RIDGE, 
                         0,0,0,0, 0,0,0,0, 0,0) # x y w h  l r t b  h v

    @refs={}
    matrix = FXMatrix.new(gb1, 2,LAYOUT_FILL_X|FRAME_RAISED|LAYOUT_TOP|MATRIX_BY_COLUMNS)
    [
     [:EXEPATH,"avrdude exe path",["./avrdude.exe"]],
     [:PROGARGS,"programmer args",["-c usbtiny","-c usbasp"]],
    ].each{|ref,lab,vals|
      lb=FXLabel.new(matrix,lab)
      cb=FXComboBox.new(matrix, 50, nil, 0,
                        LAYOUT_FILL_X|COMBOBOX_REPLACE|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
      cb.numVisible=5
      vals.each{|v|cb.appendItem(v) }
      cb.connect(SEL_COMMAND){|sender,sel,event|
        puts "SEL_COMMAND",cb.getItemData(cb.currentItem)
      }
      #tf=FXTextField.new(matrix,50)
      @refs[ref]=[cb]
    }
#      hf3=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|
#                                PACK_UNIFORM_WIDTH, 0,0,0,0, *[5]*6)


#    FXLabel.new(hf2,"Branch or Tag URL: ")
#    @ent=FXTextField.new(hf3,80,nil,0,TEXTFIELD_NORMAL|LAYOUT_FILL_X)
#    hf1=FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|
#          LAYOUT_SIDE_BOTTOM|FRAME_SUNKEN|FRAME_THICK, 0,0,0,0, 0,0,0,0, 0,0)
#    @treeList=FXTreeList.new(hf1,nil,0,
#              TREELIST_SINGLESELECT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|
#              TREELIST_ROOT_BOXES|LAYOUT_FILL_X|LAYOUT_FILL_Y)
#    @treeList.connect(SEL_SELECTED){|sender,sel,item|
#      @ent.text=item.data
#    }
  end
  def getVal(tag)
    @refs[tag][0].value
  end
  
end
