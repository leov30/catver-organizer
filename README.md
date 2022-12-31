# catver-organizer
batch script to organize roms using datafile + catver.ini
the script will generate another script in the output folder which can be used to move/copy roms<br>
the script can generate a script to COPY (will add parents for matched clones and bios) games and make a playable pack or MOVE (will add all clones for matched parents) games to removed them from the collection

* option 1 : drag and drop emulator datafile + catver.ini matching the datafile
* option 2: only drag and drop datafile, this option will need mamediff http://www.logiqx.com/Tools/MAMEDiff/
and  the current catver.ini and ARCADE.dat from https://www.progettosnaps.net/ in the _source folder next to the script
this option is for emulators that dont have a well maintanted catver.ini, the script will match games using mamediff to the current MAME catver.ini



