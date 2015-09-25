# Inhalt #



# Ihr braucht #

  * Den Sender (Turnigy 9X/Eurgle 9X/iMAX 9X/FlySky FS-TH9X)
  * Lötkolben
  * AVR Programmer
  * Computer mit Linux/Mac OS/Windows
  * Multimeter



# Welchen Programmer? #

Prinzipiell eignet sich jeder AVR kompatible ISP (AVR ISP, In-System Programmer). Persöhnlich kann ich nur AVRdude kompatible programmer empfehlen! Warum?

AVRdude ist Open Source, verfügbar für Windows, Linux&Mac, unterstützt COM/LPT&USB,
ist breit unterstützt und wird aktiv weiterentwickelt.

Programmer gibt es für die serielle, parallele und USB Schnittstelle.
Vorteile der Seriell- und Parallelport-Programmer sind nicht notwendige Treiber,
Nachteile sind die Verfügbarkeit dieser Schnittstellen an neuen Rechnern und die
manchmal notwendige externe Stromversorgung der ISP’s.

USB ISP’s versorgen sich aus der USB Schnittstelle und können das Target (i.e. den Sender)
gleich mit Strom mitversorgen, es muss aber darauf geachtet werden das für Windows
notwendige Treiber bereitgestellt sind.

Eine Liste der von AVRdude unterstützen Programmer findet sich [hier](http://www.nongnu.org/avrdude/user-manual/avrdude_4.html). Diese können von eBay oder den gängigen Elektronikversandhäusern zwischen 4 und 30Euro erworben werden.

Achtung!! Die TH9X hat an den Programmiereingängen eine Störschutzbeschaltung bestehend aus einem Kondensator und einem 200 Ohm Widerstand. Dies bedeutet, dass die Ausgänge des Programmers deutlich niederohmiger als 200 Ohm sein sollten. z.B. 33-56 Ohm. Alle Programmer die grössere Schutzwiderstände in ihren Ausgangsleitungen (SCK,MOSI,RES) haben machen daher Probleme (z.B. USBTinyISP oder USBASP). Wenn man diese Schutzwiderstände verkleinert, dann funktionieren auch diese Programmer.

Von Forenmitgliedern benutzte programmer sind nachfolgend aufgelistet.

## USB erfolgreich ##
  * [Pocket AVR Programmer](http://www.sparkfun.com/commerce/product_info.php?products_id=9231)
  * AVR ISP MKII
  * [USB-ASP MySmartUSB MKII](http://shop.myavr.de/Programmer/mySmartUSB%2520MK2%2520(Programmer%2520und%2520Bridge).htm?sp=article.sp.php&artID=42)
  * [USB-ASP protostack](http://www.protostack.com/accessories/usbasp-avr-programmer)
  * [USB-ASP eXtreme Burner](http://extremeelectronics.co.in/avr-tutorials/gui-software-for-usbasp-based-usb-avr-programmers/)
  * [AVRProgUSB](http://and-tech.pl/Stk500/AVRProgUSB-v1.3-ang.pdf)
## USB problematisch ##
  * [USBASP 4Euro](http://www.ebay.de/itm/USBASP-USBISP-AVR-Programmer-USB-ATMEGA8-ATMEGA128-New-/370532286436?pt=LH_DefaultDomain_0&hash=item564571ffe4)  Schutzwiderstand 4x100 Ohm (101) ersetzen durch 4x33 Ohm oder Drahtbrücken!
  * [USBTinyISP](http://www.mikrocontroller.net/articles/AVR-ISP-Stick) Schutzwiderstände [R6](https://code.google.com/p/th9x/source/detail?r=6),[R7](https://code.google.com/p/th9x/source/detail?r=7) von 1.5K auf 33 Ohm verkleinern!
  * [USB-AVRlab](http://wiki.ullihome.de/index.php/USBAVR-ISP/de#USB_AVR_Lab_als_Programmier.2FDebugadapter)
  * AVR-Dragon


## LPT erfolgreich ##
  * [AVR-ISP-Parallelport-Programmer](http://home.arcor.de/dh2iw/shop.html)
  * [AVR Atmel ISP parallel Programmer](http://cgi.ebay.de/AVR-Atmel-ISP-parallel-Programmer-/170491386034?cmd=ViewItem&pt=Bauteile&hash=item27b21418b2#ht_1489wt_889)
## LPT problematisch ##
  * [Primitiv Parallelport programmer](http://s-huehn.de/elektronik/avr-prog/avr-prog.htm)




Vermutlich wird ein USB programmer dem LPT pendant bevorzugt. Abgesehen von der Stromversorgung und der Schnittstellenwahl in AVRdude ist das meiste allerdings gleich.




# Verbinden der Th9x mit dem Programmer #

Die Anschlüsse des Programmers müssen mit dem Mikrocontroller im Sender (ATmega64) verbunden werden. Atmel hat als Standard einen 6 oder 10 poligen Anschluss. Mindestens einer von beiden ist auf jedem AVR programmer zu finden. Die Atmel Standardbelegung sieht wie folgt aus.
Achtung!! Blickrichtung auf die Steckerpins. Die Verpolschutzkerbe am Stecker ist bei Pin3 bzw. Pin5.

<img src='https://github.com/thus1/th9x/blob/wiki/atmel_6-10pin_new.png' width='600'>



diese müssen wie nachfolgend abgebildet mit dem Sender verbunden werden. Den Turnigy Sender gibt es<br>
in 2 Versionen, abgebildet ist die v1, bei der v2 ist an SCK ein Lötpad (roter Kreis).<br>
<br>
<img src='https://github.com/thus1/th9x/blob/wiki/turnigy9x_pcb.png' width='600'>


Es wird empfohlen dünnes und flexibles Kabel zu benutzen (z.B. die Litze aus einem Netzwerkkabel), da sich ansonsten bei starker Belastung u.U. Leiterbahnen von der Platine lösen könnten. Es ist auch empfehlenswert die Lötstellen mit einer Heißklebepistole zu sichern. Heißkleber ist einfach anwendbar und auch einfach wieder zu entfernen!<br>
<br>
Bei den meisten Programmern ist ein Stecker mit Kabel für den 6 Pin Anschluss dabei. Nach erfolgtem Löten überprüfen ob die Verbindung vom Programmerstecker bis hin zu den Pins des Mikrocontroller besteht (siehe Pfeile Pinbelegung Prozessor). Falls nicht, siehe Fehlerquellen.<br>
<br>
Parallelport Programmer benötigen oftmals die Stromversorgung durch die Batterie im Sender, daher muss der Vcc pin angeschlossen sein. USB programmer können üblicherweise den Sender mit Strom versorgen (meist muss ein Jumper geschlossen werden). Deshalb muss dabei keine Batterie angeschlossen sein.<br>
<br>
Im Fall der Stromversorgung über den USB Programmer kann mit abgenommener Rückseite und nicht angeschlossenem 12pin connector der Sender nun zum Test mit dem Programmer verbunden werden. Bei angeschlossenem Vcc sollte sich der Sender nun anschalten und mit SwitchError melden, da die meisten Schalter über den 12Pin connector ja abgeklemmt sind.<br>
<br>
<br>
<br>
<h1>Einrichten der Software</h1>

Alle <code>klein</code> geschriebenen Wörter sind Konsolenbefehle, d.h. in Windows gibt man sie in<br>
Start -> ausführen -> <code>cmd</code> ein, in Mac OS öffnet man Anwendungen/Dienstprogramme/Terminal.<br>
<br>
<ol><li>Für Windows den mitgelieferten Treiber des Programmers installieren, Mac OS und Linux Benutzer benötigen meist keinen Treiber.<br>
</li><li>AVRdude installieren:<br>
<ul><li>Windows Benutzer laden sich am besten <a href='http://winavr.sourceforge.net/'>WinAVR</a>, welches AVRdude beinhaltet.<br>
</li><li>Mac OS Nutzer installieren <a href='http://www.macports.org/install.php'>MacPorts</a> (setzt Xcode vom Mac App Store vorraus, kostenloser download). Dann ein Terminal Fenster öffnen und folgenden Befehl eintippen: <code>sudo port install avrdude</code> jetzt kann man einen Kaffee trinken und warten bis MacPorts AVRdude und alles was es dazu benötigt installiert.<br>
</li><li>Linux user wissen sicher wie sie an die aktuelle Version von AVRdude herankommen :)<br>
</li><li>Die aktuelle Version von AVRdude ist 5.11<br>
</li></ul></li><li>Optionale GUI’s (Grafische Benutzeroberflächen) gibt es für AVRdude sowohl für für Windows (z.B. <a href='http://sourceforge.net/projects/avrdude-gui/files/avrdude-gui/avrdude-gui_0.2.0/avrdude-gui_v0.2.0.zip/download'>avrdude-gui_v0.2.0</a>), Windows & Mac OS (z.B. <a href='http://avr8-burn-o-mat.aaabbb.de/'>AVR Burn-O-Mat</a>, <a href='http://www.vonnieda.org/software/avrfuses'>AVRFuses</a>) oder Windows & Linux (z.B. <a href='http://www.soft-land.de/'>AVRBurner</a>)<br>
</li><li>Benötigte Parameter für avrdude:<br>
<ul><li><code>-c xxxx</code> -> xxxx steht für den verwendeten Programmer, siehe <a href='http://www.nongnu.org/avrdude/user-manual/avrdude_4.html'>Liste</a>
</li><li><code>-p m64</code> -> gibt den Target Prozessor an (ATmega64)<br>
</li><li><code>-P xxx</code> -> xxx gibt den Port an, z.B. <code>com1</code>, <code>lpt1</code>, <code>usb</code>, dieser Parameter ist bei USB Programmer meist unnötig<br>
</li><li><code>-B  xx</code> -> xx ist die Periodendauer eines Taktes in uS, höhere Werte bedeuten niedrigere Programmierfrequenz<br>
</li></ul></li><li>Überprüfen der Verbindung mit AVRdude: bei Eingabe von <code>avrdude -c xxxx -p m64</code> sollte, wenn alles richtig gemacht wurde, u.a. folgendes erscheinen:					<code>avrdude: Device signature = 0x1e9602</code>
</li><li>Aktuelles binary herunderladen: <a href='http://th9x.googlecode.com/svn/trunk/th9x.bin'>th9x.bin</a></li></ol>


<h1>Sichern und Flashen der Software</h1>

Bevor die neue Software aufgespielt wird empfiehlt es sich die alte zu sichern.<br>
Wer das vergisst findet die Originalsoftware aber auch wieder im Internet .<br>
<br>
<b>ACHTUNG: Beim Flashen des EEPROM gehen alle Modelleinstellungen verloren! Das ist unumgänglich, deshalb alle Einstellungen notieren.</b>

Folgende Befehle sichern den aktuellen Flash und eeprom Inhalt in .bin:<br>
<br>
<blockquote><code>avrdude -c xxxx -p m64 -U flash:r:backupflash.bin:r</code></blockquote>

<blockquote><code>avrdude -c xxxx -p m64 -U eeprom:r:"backupeeprom.bin":r</code></blockquote>

Zum aufpielen des neuen flash-Images th9x.bin gibt man folgendes ein:<br>
<br>
<blockquote><code>avrdude -c xxxx -p m64 -U flash:w:th9x.bin:a</code></blockquote>

Parameter Werte:<br>
<ul><li>speichertyp = flash/eeprom<br>
</li><li>operation = r/w (read/write)<br>
</li><li>format = r (raw binary, a=autodetect geht nicht bei read)</li></ul>

Und das wars auch schon! Der eeprom inhalt muss nicht überschrieben werden, beim ersten Start des Senders wird er neu initialisiert. Falls man eine GUI benutzen möchte: diese tut auch nichts anderes als AVRdude mit diesen Parametern zu starten. Meist sind GUI’s nur bequemer um Ordner bzw. Dateien auszuwählen.<br>
<br>
<b>ACHTUNG: Bei Benutzung von GUI’s auf keinen Fall die Fuses verändern!</b>

Beim ersten Starten mit der neuen Firmware sollten noch die Knüppel<br>
neu kalibriert werden.<br>
<br>
<br>
<br>
<h1>Fehlersuche</h1>

Es gibt immer etwas was schiefgehen kann, bis jetzt ist aber noch kein Fall bekannt bei dem eine Th9x dauerhaften Schaden genommen hat. Bekannte und gelöste Fehler sind der nachfolgenden Tabelle zu entnehmen. Bei allen anderen unbekannten Fehlern einfach im Forum (siehe Links) melden. Da wird sehr schnell und gut geholfen! Viel Spaß!<br>
<br>
<br>
<table><thead><th> Meldung </th><th> Problem -> Lösung </th><th> Bild </th></thead><tbody>
<tr><td> <code>Setting mode and device parameters.. OK! Entering programming mode.. FAILED! Leaving programming mode.. OK!</code> </td><td> nicht angeschlossenes RST, evtl. durch zerstörte Leiterbahn auf der Platine (nachmessen) -> Leiterbahn vom Lötpad zum Prozessorpin überbrücken </td><td> <img src='http://th9x.googlecode.com/svn/wiki/rst_bridge.png' width='200'> </td></tr>
<tr><td> <code>avrdude: Error: Could not find xxxx device</code> </td><td> ISP am USB Port aus und wieder einstecken; Stromversorgung des USB Ports reicht bei manchen Laptops nicht aus  -> anderen Port ausprobieren oder an Desktop PC versuchen </td><td>      </td></tr>
<tr><td> <code>initialization failed, rc=-1 : AVR device initialized and ready to accept instructions : Device signature = 0x000000 : Yikes! Invalid device signature. : Expected signature for ATMEGA64 is 1E 96 02</code> </td><td> Programmierfrequenz absenken: <code>-B xx</code>, xx erhöhen, z.b. 10...200); 				vertauschte Anschlusskabel -> richtig anschliessen; 				Ail D/R und Thr Cut Schalter auf AUS stellen (v1); Ail D/R und Thr Cut Schalter auf AN stellen (v2); 				Falls der RST Pegel unter 5V Volt ist (nachmessen) -> Pull Up Widerstand von RST nach Vcc am Eingang des Programmers anschließen (anfangen bei etwa 1kOhm, falls nicht ausreichend bis etwa 200Ohm; 				gelben 10/46uF Tantal Elektrolytkondensator über RST Pad entfernen </td><td> <img src='http://th9x.googlecode.com/svn/wiki/rst_elko.png' width='200'> </td></tr></tbody></table>



<h1>Links</h1>

<ul><li>Review der Turnigy 9X v2 auf <a href='http://rcmodelreviews.com/turnigy9xv2review.shtml'>RCModelReviews</a>
</li><li>Alles zu AVRdude: <a href='http://www.nongnu.org/avrdude/user-manual/'>http://www.nongnu.org/avrdude/user-manual/</a>
</li><li>Einführung zu AVR Programmer <a href='http://www.mikrocontroller.net/articles/AVR_In_System_Programmer#Einf.C3.BChrung'>http://www.mikrocontroller.net/articles/AVR_In_System_Programmer#Einf.C3.BChrung</a>
</li><li>Tutorial zu AVR allgemein: <a href='http://www.mikrocontroller.net/articles/AVR-Tutorial'>http://www.mikrocontroller.net/articles/AVR-Tutorial</a>
</li><li>Elektronik Einführung (auch SMD löten): <a href='http://www.mikrocontroller.net/articles/Elektronik_Allgemein'>http://www.mikrocontroller.net/articles/Elektronik_Allgemein</a>
</li><li>Thread auf <a href='http://www.rclineforum.de/forum/thread.php?threadid=239048&sid=&threadview=0&hilight=&hilightuser=&page=50'>rclineforum.de</a>
</li><li>Threads auf <a href='http://www.rcgroups.com/forums/showthread.php?t=1266162'>#1 rcgroups.com</a>, <a href='http://www.rcgroups.com/forums/showthread.php?t=1035575&page=172'>#2 rcgroups.com</a>
</li><li>Alternative Firmware: <a href='http://radioclone.org/;'>http://radioclone.org/;</a> <a href='http://sourceforge.net/projects/radioclone/'>http://sourceforge.net/projects/radioclone/</a>
