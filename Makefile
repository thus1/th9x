

SRC= simu.cpp th9x.cpp menus.cpp lcd.cpp drivers.cpp


all:  tgt_bin simu

dump:
	make.rb dump

INC=-I/home/thus/work/ruby/fox-1.6.31/include/
LIB=/home/thus/work/ruby/fox-1.6.31/src/.libs/libFOX-1.6.so.0



ifeq ($(shell hostname),HEIWS80062)
INC=-I/home2/husteret/work/sfc/gnu/ruby-1.8.5/fox-1.6.20/include
LIB=-lFOX-1.6 -L/home2/husteret/work/sfc/gnu/ruby-1.8.5/fox-1.6.20/src/.libs/
endif

# SRCO:=$(foreach f,$(SRC),../$(f))
simu: $(SRC) Makefile *.h
	gcc $(SRC) -g -o$@ $(INC) $(LIB)  -MD -DSIM
	mv *.dsimu OBJS


tgt_bin:
	make.rb bin


testMixtab: testMixtab.cpp
	gcc $< -g -o$@ $(INC) $(LIB) -DSIM


-include OBJS/*.dsimu