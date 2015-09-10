This project is an alternative firmware for the 9 channel rc-control FS-TH9X manufactured by FlySky (other brand names: Turnigy 9X / Eurgle 9X / iMax 9X)

# Documentation #
  * [Documentation (engl)](http://th9x.googlecode.com/svn/trunk/doc/th9x-en.pdf)
  * [Dokumentation (deutsch)](http://th9x.googlecode.com/svn/trunk/doc/th9x.pdf)
  * [atmega64A.pdf](http://th9x.googlecode.com/svn/trunk/doc/atmega64A.pdf)
  * [th9x-schaltplan.pdf](http://th9x.googlecode.com/svn/trunk/doc/schaltplan-transmitter.pdf)

# Installation Instructions #
  * [Installationsanleitung/Installation Instructions](installation_de.md)
  * http://www.rcgroups.com/forums/showpost.php?p=14901247&postcount=1700
  * http://www.rcgroups.com/forums/showpost.php?p=14909360&postcount=1714

# Forums #
  * [rcline forum](http://www.rclineforum.de/forum/thread.php?threadid=239048&sid=&threadview=0&hilight=&hilightuser=&page=73)
  * [9x forums](http://9xforums.com/forum/index.php)
  * [rcgroups forum](http://www.rcgroups.com/forums/showthread.php?t=1266162)

# Links to similar Projects #
  * http://code.google.com/p/er9x/
  * http://radioclone.sourceforge.net/
  * http://forum.rcdesign.ru/f8/thread182549.html#post1840751
  * http://www.lib.aero/~ari/rc/]
  * http://pfmrc.eu/viewtopic.php?t=25564
  * http://www.farmclubrc.com/Articles/ArticleSoaring.pdf




# Binary Images #
You can find some Snapshots as binary-Images below:

**Attention!! This software is developed continuously.**

We try to convert the persistent data from one version to the next one automatically as good as it can be done.
There might also be some bugs in any version, if you find some, then please report them with the [issue-form](http://code.google.com/p/th9x/issues/entry)

It is possible to safe the whole **eeprom-contents** from time to time as a **backup** with each flash progammer.
This data can be replayed afterwards if anything goes wrong. It can also be analyzed offline e.g. with the ruby-script in utils/eeprom.rb:
```
  > ruby utils/eeprom.rb info eeprom.bin
  > ruby utils/eeprom.rb info eeprom.bin -v
```

**th9x** is free to use under the GNU v2.0 License. Feel free to use, copy and modify it as you wish! If you feel that this software has been beneficial you can show your support by donating. This will be greatly appreciated and you'll be added to the "contributors" list in the code.

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QSZ3KKDHJFPB6)
[![](https://www.paypal.com/en_US/i/logo/PayPal_mark_60x38.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QSZ3KKDHJFPB6)

## head: [th9x.bin](http://th9x.googlecode.com/svn/trunk/th9x.bin) - [th9Xplorer-win](http://th9x.googlecode.com/svn/trunk/th9Xplorer.exe) -  [th9Xplorer-linux](http://th9x.googlecode.com/svn/trunk/th9Xplorer) ##
This is the newest version with minor changes or fixes or even with incomplete new features.
```
VERS: V1.3075-thus
DATE: 12.10.2012
TIME: 22:26:06
SVN:  th9x-r285
```
  * list navigation: insert at end of block, edit-end with menu-key, select-cursor=solid
  * 8-Binary-Switches in one output channel

## [th9x.bin-r235](http://th9x.googlecode.com/svn-history/r235/trunk/th9x.bin) ##
```
VERS: V1.2976-thus
DATE: 23.10.2011
TIME: 00:14:16
SVN:  trunk-r232
```
  * [issue99](https://code.google.com/p/th9x/issues/detail?id=99), SWIFT protocol without 38KHz modulation
  * [issue70](https://code.google.com/p/th9x/issues/detail?id=70), template servo-test
  * switch check warning with step-by-step hints
  * bugfix simu-calib-template, submenu restore in menu0
  * Attention!! eeprom format V06 in [r229](https://code.google.com/p/th9x/source/detail?r=229) is slightly incompatible to [r226](https://code.google.com/p/th9x/source/detail?r=226)!!! Please check switches-menu and trim values. Maybe you have to delete the switches lines and generate them new.  Conversion from V05 should be ok.
  * menunavigation: 3-column ranges: 1.chan-column for new lines, 2.value columns 3.line edit coumn
  * list header can scroll away when more than 6 lines are needed.
  * setup option navigation: simple/advanced
  * [issue96](https://code.google.com/p/th9x/issues/detail?id=96), [issue97](https://code.google.com/p/th9x/issues/detail?id=97): Setup Key Long, [issue98](https://code.google.com/p/th9x/issues/detail?id=98)
  * bugfix Trim-Mode T-
  * different trim-modes 1,2,4,8 experimental
  * new main-screen, less beeps in silent mode, [issue75](https://code.google.com/p/th9x/issues/detail?id=75)
  * new menunavigation with Up-Down,Left-Right. The Value-Change-Mode is entered with a LONG-Press to the Left- or Right-Key, [issue78](https://code.google.com/p/th9x/issues/detail?id=78), [issue94](https://code.google.com/p/th9x/issues/detail?id=94), [issue95](https://code.google.com/p/th9x/issues/detail?id=95)
  * Timer now controlled by a switch, second Timer displays current flight-time [issue45](https://code.google.com/p/th9x/issues/detail?id=45), [issue34](https://code.google.com/p/th9x/issues/detail?id=34)
  * model data version: V06, converted from older versions 1,2,3,4,5
  * [issue57](https://code.google.com/p/th9x/issues/detail?id=57), [issue59](https://code.google.com/p/th9x/issues/detail?id=59), [issue88](https://code.google.com/p/th9x/issues/detail?id=88), [issue89](https://code.google.com/p/th9x/issues/detail?id=89), [issue90](https://code.google.com/p/th9x/issues/detail?id=90), [issue92](https://code.google.com/p/th9x/issues/detail?id=92)
  * 8 virtual switches. experimental version
  * New Protocols DSM2, Swift, Picco-z


## [th9x.bin-r199](http://th9x.googlecode.com/svn-history/r199/trunk/th9x.bin) ##
```
VERS: V1.2245-thus
DATE: 13.07.2011
TIME: 22:12:02
SVN:  trunk-r199
```

  * model data version: 4, converted from older versions 1,2,3
  * [issue74](https://code.google.com/p/th9x/issues/detail?id=74), [issue77](https://code.google.com/p/th9x/issues/detail?id=77), [issue76](https://code.google.com/p/th9x/issues/detail?id=76), [issue84](https://code.google.com/p/th9x/issues/detail?id=84), [issue85](https://code.google.com/p/th9x/issues/detail?id=85), [issue86](https://code.google.com/p/th9x/issues/detail?id=86), [issue63](https://code.google.com/p/th9x/issues/detail?id=63)
  * instant trim
  * mix mode + x =
  * switch mode oOff iNeg,iNul,Ipos
  * Input FUL is now removed. Same function is done with Input MAX and switch-mode iNeg
  * negativ curves f(-x) allows ´querruderdifferenzierung´ with one single curve
  * assym potis as input (p1-p3)
  * trainer1-8 as input (T1-T8)
  * CH1-8 as inputs (Ch1-Ch8)
  * accept any Trainer Inputs from 3ch to 8ch
  * slightly enhanced file compression, saves some Bytes


## [th9x.bin-r184](http://th9x.googlecode.com/svn-history/r184/trunk/th9x.bin) ##
```
VERS: V1.2038-thus
DATE: 27.01.2011
TIME: 00:15:51
SVN:  trunk-r184
```

  * model data version: 4, converted from older versions 1,2,3
> Attention!! save old eeprom contents in case you want to go back to the previous version

  * [issue73](https://code.google.com/p/th9x/issues/detail?id=73) mode change works each time
  * [Issue71](https://code.google.com/p/th9x/issues/detail?id=71):Unterschiedliche Expo Werte fuer Flugphasen
  * [Issue36](https://code.google.com/p/th9x/issues/detail?id=36):special assymetric trim mode for throttle
  * [Issue18](https://code.google.com/p/th9x/issues/detail?id=18):EXPO with curve,
  * [issue17](https://code.google.com/p/th9x/issues/detail?id=17):three values for expo,
  * [issue16](https://code.google.com/p/th9x/issues/detail?id=16):split expo values,

  * use foldedlist for mixers
  * edit all values in mixer menu
  * use foldedlist for expo
  * expo values are unequally distributed like limit-values 0 10 20 30 40 50 55 60 65 70 75 80 85 90 95 100
  * same change has happened to the dualrate values: 0 1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100

## [th9x.bin-r167](http://th9x.googlecode.com/svn-history/r167/trunk/th9x.bin) ##
```
VERS: V1.1869-thus
DATE: 07.12.2010
TIME: 23:17:49
SVN:  trunk-r167
```

  * model data version: 3
  * [issue69](https://code.google.com/p/th9x/issues/detail?id=69): only trim beep in mode 1 (silent)
  * [issue68](https://code.google.com/p/th9x/issues/detail?id=68): thr-alert sign-bug, larger stick zero limit
  * [issue64](https://code.google.com/p/th9x/issues/detail?id=64): double clicks (changed to tripple click)
  * [issue60](https://code.google.com/p/th9x/issues/detail?id=60): vbat blinks, bat warn up to 12V
  * [issue58](https://code.google.com/p/th9x/issues/detail?id=58): falsches tasten-handling
  * [issue55](https://code.google.com/p/th9x/issues/detail?id=55): limit with scaling. This feature is activated in the Limits Menu 6/7 when a ´`*`´ is visible in the Scale-column (´scl´)
  * The values for the limits are no longer with stepwidth 1. Now the values are unequally distributed 0 1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150
  * adc-peak-filter, show adc errors (experimental)
  * optional adc-statistic (not activated)
  * experimental double-beep and inc-dec dynamic
  * measuring output calculation time
  * move and duplicate mixer lines
  * show slope-vals in sec
  * leave THR-Alarm with THR-movement
  * show slave-mode in trainer menu
  * trim repeat slow
  * inc/dec with nicevals when doubleclick



## [th9x.bin-r153](http://th9x.googlecode.com/svn-history/r153/trunk/th9x.bin) ##
```
VERS: V1.1710-thus
DATE: 22.09.2010
TIME: 00:04:44
SVN:  trunk-r153
```
  * menucontrol refined: Some Menus now navigate with left-right (as in early revisions) some Menus allow column change via their header-lines
  * FADE renamed to SLOPE
  * copy expo and weight when dualrate switch is activated
  * Potis are calibrated like the sticks
  * adjutable inactivity warning (1-30min)
  * show file version info in model overview
  * automatic light-control triggered by keypress (adjustable timeout)
  * Trainer input is shown in main screen as 'Stud.'
  * [issue54](https://code.google.com/p/th9x/issues/detail?id=54): new Model-template: 'Empty' (is used by default)
  * [issue53](https://code.google.com/p/th9x/issues/detail?id=53): doku
  * [issue51](https://code.google.com/p/th9x/issues/detail?id=51): Backlight OFF when error message, should be ON
  * [issue49](https://code.google.com/p/th9x/issues/detail?id=49): Sim calibration enhancement (new template 'Sim Calib')
  * [issue42](https://code.google.com/p/th9x/issues/detail?id=42): key repeat changed from 160ms -> 320ms


## [th9x.bin-r146](http://th9x.googlecode.com/svn-history/r146/trunk/th9x.bin) ##
```
VERS: V1.1613-thus
DATE: 14.09.2010
TIME: 22:06:17
SVN:  trunk-r146
```
  * mixer debug support
  * trim steps and max range halved (50%)
  * [issue 48](https://code.google.com/p/th9x/issues/detail?id=48) negativ trim large steps.
  * 4 default models plain,v-tail,delta,CCCP
  * [issue 38](https://code.google.com/p/th9x/issues/detail?id=38), calibration simplified
  * [issue 47](https://code.google.com/p/th9x/issues/detail?id=47) filesize larger 256


## [th9x.bin-r143](http://th9x.googlecode.com/svn-history/r143/trunk/th9x.bin) ##
```
VERS: V1.1562-thus
DATE: 09.09.2010
TIME: 00:49:58
SVN:  trunk-r143
```
> # Attention!! Bug negative Trim (iss48) #

  * eeprom data is changed! Auto-conversion from previous version
  * model data version: 2
  * [issue 15](https://code.google.com/p/th9x/issues/detail?id=15) Enhancement: Neue Standard-Kurve : additional 3\*3-point curves
  * ([issue 26](https://code.google.com/p/th9x/issues/detail?id=26)) more curves
  * [issue 37](https://code.google.com/p/th9x/issues/detail?id=37) THR warning with inverted THR use.: like proposed with auto learning
    * Procedure in case you have the incorrect THR alarm:
    * Put the stick in the THR idle position
    * Go to the alarms menu, and turn the THR alarm off and on again.

  * [issue 42](https://code.google.com/p/th9x/issues/detail?id=42) Key-debounce insufficient: increased from 20ms to 40ms
  * [issue 46](https://code.google.com/p/th9x/issues/detail?id=46)  Stick latency : Filter degree adjustable from 0-3
  * change in mixercalculation: sign of weight is evaluated before curve is evaluated this allows 'querruderdifferenzierung' with one single 3-point-curve

## [th9x.bin-r141](http://th9x.googlecode.com/svn-history/r141/trunk/th9x.bin) ##
```
VERS: V1.1538-thus
DATE: 27.08.2010
TIME: 17:07:04
SVN:  trunk-r141
```
  * [issue 35](https://code.google.com/p/th9x/issues/detail?id=35), [issue 39](https://code.google.com/p/th9x/issues/detail?id=39), no key repeat when incrementing trim-values
  * [issue 29](https://code.google.com/p/th9x/issues/detail?id=29), switch is recognized when changed
  * [issue 40](https://code.google.com/p/th9x/issues/detail?id=40), subtrim works with inverted channels
  * [issue 4](https://code.google.com/p/th9x/issues/detail?id=4), [issue 41](https://code.google.com/p/th9x/issues/detail?id=41), frame duration is now 22.5ms

## [th9x.bin-r133](http://th9x.googlecode.com/svn-history/r133/trunk/th9x.bin) ##
```
VERS: V1.1532-thus
DATE: 15.07.2010
TIME: 00:08:12
SVN:  trunk-r133
```
  * **model data is changed!** Auto-conversion from previous version
  * [issue 33](https://code.google.com/p/th9x/issues/detail?id=33)
  * TRIM-menu changed into TRIM-SUBTRIM menu. This allows rearrangement of current trim-values into subtrim-values shown in the limits menu. **Attention!! the former values trim-base are converted to trim values.** Please use now the subtrim function.
  * edit function is now available for all values shown in the expo-overview
  * 4 beep levels: quiet,silent,normal,loud
  * ([issue 31](https://code.google.com/p/th9x/issues/detail?id=31)) changed the navigation logic. Now any cursor navigation is done with the up-down keys
    * a short key-press moves the cursor up-down
    * a long key-press moves the cursor left-right (if needed in menu)
  * [issue 30](https://code.google.com/p/th9x/issues/detail?id=30) Throttle warning NON functioning
  * [issue 20](https://code.google.com/p/th9x/issues/detail?id=20) Timer für Flugzeit sollte in Statistiken angezeigt werden können

## [th9x.bin-r119](http://th9x.googlecode.com/svn-history/r119/trunk/th9x.bin) ##
```
VERS: V1.1385-thus
DATE: 06.07.2010
TIME: 00:27:22
SVN:  trunk-r119
```
  * **model data is changed!** Auto-conversion from previous version
  * [issue 27](https://code.google.com/p/th9x/issues/detail?id=27): Trim action will interfere with CH4
  * [issue 23](https://code.google.com/p/th9x/issues/detail?id=23): Sticks have dead band
  * [issue 14](https://code.google.com/p/th9x/issues/detail?id=14): the speed steps are a little bit inhomogenuous
  * auto convert eeprom-format for older revisions oldrev <[r119](https://code.google.com/p/th9x/source/detail?r=119)
  * !! no backward conversion of eeprom possible. (save old eeprom before)

## [th9x.bin-r116](http://th9x.googlecode.com/svn-history/r116/trunk/th9x.bin) ##
```
VERS: V1.1346-thus
DATE: 30.06.2010
TIME: 00:58:18
SVN:  trunk-r116
```
  * [issue 7](https://code.google.com/p/th9x/issues/detail?id=7)
  * [issue 13](https://code.google.com/p/th9x/issues/detail?id=13)
  * [issue 19](https://code.google.com/p/th9x/issues/detail?id=19)
  * [issue 21](https://code.google.com/p/th9x/issues/detail?id=21)
  * [issue 22](https://code.google.com/p/th9x/issues/detail?id=22)
  * [issue 24](https://code.google.com/p/th9x/issues/detail?id=24)
  * fsck with repair
  * DR with expo and weight
  * Limits with offset -63% to +63%
  * increased mixers from 20 to 25
  * auto convert eeprom-format from some older revisions [r46](https://code.google.com/p/th9x/source/detail?r=46)<= oldrev <[r84](https://code.google.com/p/th9x/source/detail?r=84)
  * !! no backward conversion of eeprom possible. (save old eeprom before)

## [th9x.bin-r76](http://th9x.googlecode.com/svn-history/r76/trunk/th9x.bin) ##
```
VERS: V1.1281-thus
DATE: 07.06.2010
TIME: 00:16:41
```

  * bugfix calibration overflow, THR error detection


## [th9x.bin-r72](http://th9x.googlecode.com/svn-history/r72/trunk/th9x.bin) ##
```
VERS: V1.1268-thus
DATE: 17.05.2010
TIME: 22:09:43
```

  * optimized latency
  * default mixer with 4 chans
  * inc/dec pause at zero pos
  * handling of switches in mixer lines differentiated by input source
  * handling of curves now after delay function

## [th9x.bin-r65](http://th9x.googlecode.com/svn-history/r65/trunk/th9x.bin) ##
```
VERS: V1.1233-thus
DATE: 10.05.2010
TIME: 22:37:39
```

  * bugfix: scrolling to end of mixer menu
  * bugfix: uncomplete model copy
  * Curves with Range -100 .. +100 instead of (-128..+127)
  * additional throttle- and memory-warning.
  * Warnings customizable
  * stick-mode is now global instead of model-specific


## [th9x.bin-r59](http://th9x.googlecode.com/svn-history/r59/trunk/th9x.bin) ##
```
VERS: V1.1163-thus
DATE: 04.05.2010
TIME: 22:07:05
```
  * bugfix bad negativ switches display
  * bugfix potential endlessloop

## [th9x.bin-r55](http://th9x.googlecode.com/svn-history/r55/trunk/th9x.bin) ##
```
VERS: V1.1161-thus
DATE: 03.05.2010
TIME: 23:51:57
```
  * bugfix: write time overflow
  * temporary backup-files used for data reliability
  * timer beep stop with exit-key
  * timer restart   with exit-key-long
  * timer in silent mode when value is 0
  * two view-modes: numeric output channels or bargraphes for output channels switched with cursor up/down

## Attention ##
bug in [r44](https://code.google.com/p/th9x/source/detail?r=44)-[r54](https://code.google.com/p/th9x/source/detail?r=54): Due to very long writing times of the eeprom-data, a watchdog reset can occur during configuration. In this case the curent model data is corrupted and gets deleted.
a bugfix is in preparation...



## [th9x.bin-r46](http://th9x.googlecode.com/svn-history/r46/trunk/th9x.bin) ##
```
VERS: V1.1045-thus
DATE: 21.04.2010
TIME: 23:11:50
```

  * with dynamic eeprom manager
  * up to 16 models
  * 4 curves per model
  * delay up and down
  * hw-watchdog
  * !! eeprom incompatible to revs before



## [th9x.bin-r37](http://th9x.googlecode.com/svn-history/r37/trunk/th9x.bin) ##
```
 VERS: V1.952-thus
 DATE: 16.04.2010
 TIME: 11:51:49
```
  * with persistent Trainermode
  * Delay and Curves
  * !! eeprom incompatible to revs before


## [th9x.bin-r36](http://th9x.googlecode.com/svn-history/r36/trunk/th9x.bin) ##
```
 VERS: V1.938-thus
 DATE: 16.04.2010
 TIME: 10:14:49
```
  * with Delay and Curves
  * eeprom incompatible to revs before


## [th9x.bin-r28](http://th9x.googlecode.com/svn-history/r28/trunk/th9x.bin) ##
```
 VERS: V1.926-thus
 DATE: 11.04.2010
 TIME: 12:33:48
```

  * with Trainermode, not persistent