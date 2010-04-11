

SRC= simu.cpp th9x.cpp menus.cpp lcd.cpp drivers.cpp
SRC:=$(foreach f,$(SRC),src/$(f))


all:  tgt_bin simu


INC=-I/usr/local/include/fox-1.6 -I/usr/include/fox-1.6
LIB=-L/usr/local/lib -lFOX-1.6



simu: $(SRC) Makefile src/*.h src/*.lbm eeprom.bin
	gcc $(SRC) -g -o$@ $(INC) $(LIB)  -MD -DSIM
	mv *.dsimu OBJS


eeprom.bin:
	dd if=/dev/null of=$@ bs=1 count=2048

tgt_bin:
	ruby ./make.rb bin

dump:
	ruby ./make.rb dump


-include OBJS/*.dsimu