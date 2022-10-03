R scripts for launching and downloading iButton Thermochron dataloggers.
Currently only tested on Windows 10 with DS1921G Thermochrons. 

In order to work, these scripts require a copy of thermoms.exe and thermodl.exe
to be present in the R working directory. 

The thermodl.exe and thermoms.exe files were originally downloaded as part of the 
Maxim iButton 1-Wire Public Domain Kit. 
There are several versions of the Kit available, including
versions with pre-compiled binaries (executables) for Windows/Linux/OSX.

https://www.maximintegrated.com/en/products/ibutton-one-wire/one-wire/software-tools/public-domain-kit.html


On my Windows 10 x64 computer using the DS9490B USB ibutton adapter, I used the
precompiled binary build for Win64 USB (DS9490 + WinUSB) Preliminary Version 
3.11 Beta 2,
filename: winusb64vc311Beta2_r2.zip, downloaded 2022-10-03

Unzip this file and find the .exe files thermoms.exe and thermodl.exe in the
builds\winusb64vc\Release folder. Copy these to your R working directory.
The drivers for the DS9490 USB iButton adapter must also be downloaded and 
installed: 

https://www.maximintegrated.com/en/products/ibutton-one-wire/one-wire/software-tools/drivers.html

I downloaded and installed the file OneWireDrivers_x64.msi found in the zip file install_1_wire_drivers_x64_v405.msi.

The Java OneWireViewer app can also be used to verify that your
drivers work and that you can communicate with iButtons successfully through 
the USB adapter. If you install the driver package linked above, it should also
create a folder on your C: drive in \Program Files\Maxim Integrated Products\1-Wire Drivers x64\ that contains
the Java file OneWireViewer.jar. 

If you're playing around with the command line OneWire example programs in the Windows terminal, you will probably need to 
refer to launch the program as follows:

`.\thermoms ds2490-0`

where the first argument is the designator for the OneWire USB adapter. Note that the common USB adapter DS9490 needs to be referred to as ds2490 when 
using these command line tools. You will see the same reference in the R scripts in this repository. The OneWire USB drivers don't use the 
typical 'COM1' style port naming scheme you might be expecting. 
