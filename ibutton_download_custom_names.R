# Filename: ibutton_download_custom_names.R
# 
# Author: Luke Miller  Jul 11, 2012
###############################################################################
# This script will allow the user to download iButtons, giving a unique name 
# to each file. It will parse the raw data file and extract the useful bits
# (to me at least): date/time, temperature (Celsius), user's ID for this 
# iButton, and the serial number for this iButton, and place all of these in a
# comma-separated-value file that can be easily opened in Excel or R. Each 
# downloaded iButton data file has the current date and time included in the 
# filename to avoid overwriting older data files. Raw data files are stored in a 
# directory with today's date on it, while the parsed csv files go in a 2nd 
# directory. 

# The thermodl.exe file was originally downloaded as part of the Maxim iButton 
# 1-Wire Public Domain Kit. 
# There are several versions of the Kit available, including
# versions with pre-compiled binaries (executables) for Windows/Linux/OSX.
# http://www.maxim-ic.com/products/ibutton/software/1wire/wirekit.cfm
# On my Windows 7 x64 computer using the DS9490B USB ibutton adapter, I used the
# precompiled binary build for Win64 USB (DS9490 + WinUSB) Preliminary Version 
# 3.11 Beta 2,
# filename: winusb64vc311Beta2_r2.zip, downloaded 2012-03-15
# Unzip this file and find the .exe files thermoms.exe and thermodl.exe in the
# builds\winusb64vc\release folder. Copy these to your R working directory.
# The drivers for the DS9490 USB iButton adapter must also be downloaded and 
# installed: 
# http://www.maxim-ic.com/products/ibutton/software/tmex/
# I downloaded and installed the file "install_1_wire_drivers_x64_v403.msi"
# The Java OneWireViewer app can also be downloaded and used to verify that your
# drivers work and that you can communicate with iButtons successfully through 
# the USB adapter. You can download this app here: 
# http://www.maxim-ic.com/products/ibutton/software/1wire/OneWireViewer.cfm


# NOTE: the Maxim program "thermodl.exe" must be present in the current R 
# working directory. Uncomment the setwd() line below to change the R working 
# directory. Enter your working directory location inside the quotes.
# setwd('D:/R/ibuttons') 

cur.date = Sys.Date() # Get current date
# Assemble a directory name to store raw downloaded data into
dir.name = paste('.\\',as.character(cur.date), '_raw_downloads',sep = '')
# Assemble a directory name to store the parsed csv output files in
dir.name2 = paste('.\\',as.character(cur.date),'_iButton_data', sep = '')
# Check to see if that folder already exists, if not then create it.
if (is.na(file.info(dir.name)$isdir)) {
	dir.create(dir.name)	
}
# Check to see if the other folder already exists, if not then create it.
if (is.na(file.info(dir.name2)$isdir)) {
	dir.create(dir.name2)	
}
#######################################
# Enter main while loop to repeatedly download buttons until user decides to 
# quit.
# Have user enter their own ibutton ID to be included in the filename
cat('Enter starting number for file name: \n')
fnameID = scan(file = '', what = character(), n = 1)
loop = TRUE
while(loop) {
	# Get current time to insert in filename so we don't overwrite old data
	currTime = strftime(Sys.time(), format = "%Y%m%d_%H%M")
	# Assemble filename
	fname = paste(dir.name,'\\',fnameID,'_',currTime,'.dat', sep = '')
	# Call the thermodl.exe program provided by Maxim. This must be in the 
	# current R working directory. Start by assembling a command to be issued
	sys.com = paste('thermodl.exe ds2490-0 ', fname, sep = '')
	# Now issue the command to the system using the system() function
	temp = system(sys.com, wait = TRUE, intern = TRUE)
	# The raw downloaded data should now be in the "raw_downloads" directory 
	# created at the start of the script.
	# Output the status updates from thermodl.exe 
	cat(temp[7], '\n')
	cat(temp[9],'\n')
	cat(temp[18], '\n')
	cat(temp[20], '\n')
	# Open the data file created by thermodl.exe
	x = readLines(fname) # read data into a character vector
	# Extract serial number from line 4 of file
	serialnum = substr(x[4], 26, nchar(x[4]))

	# Parse the iButton data file to extract the relevant temp/time data
	log.start = grep('Log Data', x) # Find what line the log data starts below
	log.start = log.start + 3 # change value to first line of log data
	log.end = grep('Debug Dump', x) # Find where the log data ends (roughly)
	log.end = log.end - 2 # change value to last line of log data
	# Check if there were any logged temperature data
	if (!(log.end - log.start < 0)) {
		temps = x[log.start:log.end] # extract log data, still as characters
		
		# Convert time stamps to POSIX object
		times = as.POSIXct(strptime(substr(temps,1,17), 
						format = '%m/%d/%Y %H:%M'))
		temp.data = data.frame(Time = times) # stick into a new data frame
		# convert temps to numeric and insert into temp.data
		temp.data$TempC = as.numeric(substr(temps,20,26))
		# Insert column with iButton's unique serial number
		temp.data$Serial.number = serialnum
		# Insert new column with ibutton ID from file name
		temp.data$ID = fnameID
		# Output temperature data to console
		cat('Temperature summary data: \n')
		sprintf('%s', temp.data)
		print(temp.data)
		flush.console()
		# Output temperature data to a comma-separated-value file for easy
		# reading in Excel or R. 
		# Start by assembling new filename, sticking output file in the 2nd
		# directory created at the start of the script.
		outputfile = paste(dir.name2,'\\',fnameID,'_',currTime,'.csv', sep = '')
		# Write temp.data to a comma-separated-value file
		write.csv(temp.data, file = outputfile, quote = FALSE, 
				row.names = FALSE)
	} else {
		cat('\n\n*****No temperature data*****\a\n\n')
	}
	
	cat(temp[18], '\n')
	cat(temp[20], '\n')
	cat('\a\n---------------------\n')
	cat('Swap in next iButton and hit enter. Enter q to quit.\n')
	# Read next iButton ID from user's input 
	fnameID = scan(file = '', what =character(), n = 1)
	if (length(fnameID) > 0) {
		if (fnameID == 'q') loop = FALSE # quit out of while loop
	} else loop = TRUE # return to start of while loop to download next iButton
	
}

cat('Finished\n')