

SRC= simu.cpp th9x.cpp menus.cpp foldedlist.cpp pulses.cpp pers.cpp file.cpp lcd.cpp drivers.cpp simpgmspace.cpp
SRC:=$(foreach f,$(SRC),src/$(f))

TGT_SRC= th9x.cpp menus.cpp foldedlist.cpp pulses.cpp pers.cpp file.cpp  lcd.cpp drivers.cpp

all:  tgt_bin simu


INC=-I/usr/local/include/fox-1.6 -I/usr/include/fox-1.6 \
    -I$(FOXPATH)/include

LIB=-L/usr/local/lib \
    -L$(FOXPATH)/src/.libs \
    -lFOX-1.6 \
    -Wl,-rpath,$(FOXPATH)/src/.libs



CFLAGS= -g -Wall
simu: $(SRC) Makefile src/*.h src/*.lbm eeprom.bin
	gcc src/stamp.cpp $(SRC) $(CFLAGS) -o$@ $(INC) $(LIB)  -MD -DSIM
	#mv *.dsimu OBJS



th9x.bin: $(patsubst %,src/%,$(TGT_SRC)) src/*.h
	mkdir -p TGT_OBJS
	(cd TGT_OBJS;\
	avr-gcc  -o ../th9x.elf \
	-Wno-variadic-macros -Wl,-Map=th9x.map,--cref,-v -mmcu=atmega64 \
	-I. \
	-g2 -gdwarf-2 -Os -Wall -pedantic --save-temps \
	../src/stamp.cpp \
	$(patsubst %,../src/%,$(TGT_SRC));\
	)
	avr-objcopy -O binary th9x.elf th9x.bin

eeprom.bin:
	dd if=/dev/zero of=$@ bs=1 count=2048

tgt_bin:
	ruby ./make.rb bin

dump:
	ruby ./make.rb dump

file: src/file.cpp
	g++  -DTEST -DSIM $(CFLAGS) src/file.cpp -o$@

