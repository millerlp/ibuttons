R scripts for launching and downloading iButton Thermochron dataloggers.
Currently only tested on Windows 7 with DS1921G Thermochrons. 

In order to work, these scripts require a copy of thermoms.exe and thermodl.exe
to be present in the R working directory. 

The thermodl.exe and thermoms.exe files were originally downloaded as part of the 
Maxim iButton 1-Wire Public Domain Kit. 
There are several versions of the Kit available, including
versions with pre-compiled binaries (executables) for Windows/Linux/OSX.
http://www.maxim-ic.com/products/ibutton/software/1wire/wirekit.cfm
On my Windows 7 x64 computer using the DS9490B USB ibutton adapter, I used the
precompiled binary build for Win64 USB (DS9490 + WinUSB) Preliminary Version 
3.11 Beta 2,
filename: winusb64vc311Beta2_r2.zip, downloaded 2012-03-15
Unzip this file and find the .exe files thermoms.exe and thermodl.exe in the
builds\winusb64vc\release folder. Copy these to your R working directory.
The drivers for the DS9490 USB iButton adapter must also be downloaded and 
installed: 
http://www.maxim-ic.com/products/ibutton/software/tmex/
I downloaded and installed the file "install_1_wire_drivers_x64_v403.msi"
The Java OneWireViewer app can also be downloaded and used to verify that your
drivers work and that you can communicate with iButtons successfully through 
the USB adapter. You can download this app here: 
http://www.maxim-ic.com/products/ibutton/software/1wire/OneWireViewer.cfm
