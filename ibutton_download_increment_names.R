# Filename: ibutton_download_increment_names.R
# 
# Author: Luke Miller  Dec 28, 2012
###############################################################################
## *********NOTE: DAYLIGHT SAVINGS TIME WILL SCREW YOU OVER***************
#	If your ibuttons are running during a daylight savings time transition
# (i.e. 2013-03-10 02:00 -> 03:00), you need to carefully specify what timezone
# R should be using. For example, in the Pacific Timezone (America/Los_Angeles)
# you must set Sys.setenv(TZ = 'Etc/GMT+8') before running this script 
# with ibuttons that ran during a daylight savings time transition, otherwise
# R will lose an hour's worth of data during the csv file generation below. Any
# operation that relies on POSIX time values will be affected by daylight 
# savings time unless you manually specify a timezone value that doesn't have
# a daylight savings time adjustment, such as any variation of Etc/GMT+8, where
# the +8 is the offset from UTC. So the US east coast would be Etc/GMT+5, and
# Paris, France would be Etc/GMT-1. You probably think those + and - values 
# should be the other way around, but just trust me that R uses this weird 
# convention.
Sys.setenv(TZ = 'Etc/GMT+8') # Eliminate daylight savings time adjustments
cat('System timezone is set to', Sys.timezone(),'\n')

# This script will allow the user to download iButtons, giving a numeric name
# to each file that increments with each new download. It will parse the raw 
# data file and extract the useful bits (to me at least): date/time, temperature
# (Celsius), user's ID for this iButton, and the serial number for this iButton, 
# and place all of these in a comma-separated-value file that can be easily 
# opened in Excel or R. Each downloaded iButton data file has the current date 
# and time included in the filename to avoid overwriting older data files. Raw 
# data files are stored in a directory with today's date on it, while the parsed 
# csv files go in a 2nd directory.

# This version also lets the user define a time cut-off after which logged data
# should be discarded (if you harvested iButtons before they were full).
# A system alert sound will notify the user if the download fails, otherwise a
# sample of data from the start and end of the mission will be displayed on the
# console.

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


setwd('D:/R/ibuttons') # A copy of thermodl.exe should be in this directory

cur.date = Sys.Date() # Get current date
cur.date = gsub("-","",cur.date) # Remove dashes from date
# Assemble a directory name to store downloaded data into
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

cat('Enter starting file number: \n')
fnameID = scan(file = '', what = double(), n = 1)
cat('Enter cutoff time and date (YYYY-MM-DD HH:MM)\n')
cat('Leave blank to keep all data points\n')
stoptime = scan(file = '', what = character(), n = 1, sep = ",")
if (length(stoptime) > 0){
	stoptime = as.POSIXct(stoptime) # All data points after this time will be 
							 		# dropped, since they are probably bogus
}

loop = TRUE
while(loop) {
	cat('Current file number: ', fnameID, '\n') # Show current number
	Sys.sleep(1) # pause for 1 second
	# Get current time to insert in filename so we don't overwrite old data
	currTime = strftime(Sys.time(), format = "%Y%m%d_%H%M%S")
	# Assemble filename
	fname = paste(dir.name,'\\',fnameID,'_',currTime,'.dat', sep = '')
	# Call the thermodl.exe program provided by Maxim. This must be in the 
	# current R working directory. Start by assembling a command to be issued.
	sys.com = paste('thermodl.exe ds2490-0 ', fname, sep = '')
	# Now issue the command to the system using the system() function.
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
	# If there are data, they are saved in a csv file and also printed to the
	# console for your perusal.
	# Start by checking that log.start and log.end contain values
	if (length(log.start) > 0 & length(log.end) > 0) {
		# if true, then check that log.end is different than log.start
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
			
			# Check to see if user specified a cutoff time, discard extra data
			if (length(stoptime) > 0) {
				temp.data = temp.data[temp.data$Time <= stoptime, ]
			}
			# Output temperature data to console
			cat('Temperature summary data: \n')
			print(head(temp.data,3)) # Print first 3 lines of data
			cat('.\n.\n.\n') # Print some spaces
			print(tail(temp.data,3)) # Print last 3 lines of data
#			print(temp.data) # Uncomment to print all data
			flush.console()
			# Output temperature data to a comma-separated-value file for easy
			# reading in Excel or R. 
			# Start by assembling new filename, sticking output file in the 2nd
			# directory created at the start of the script.
			outputfile = paste(dir.name2,'\\',fnameID,'_',currTime,'.csv', 
					sep = '')
			# Write temp.data to a comma-separated-value file
			write.csv(temp.data, file = outputfile, quote = FALSE, 
					row.names = FALSE)	
		} else { # no data downloaded, notify user
			cat('\n\n*****No temperature data*****\a\n\n')
		}
	} else { # read failed, probably due to missing or dead ibutton
		cat('\n\n*****No temperature data*****\a\n\n')
	}
	# clear log.end and log.start variables if they are present
	if (exists("log.start")) rm(log.start)
	if (exists("log.end")) rm(log.end)
	
	cat(temp[18], '\n')
	cat(temp[20], '\n')
	cat('\n----------------------------------------------------\n')
	cat('Swap in next iButton and press enter key to download.\n') 
	cat('Press r to retry this number.\n')
	cat('Press s to skip next number.\n')
	cat('Press q to quit.\n')
	cat('Previous file number: ', fnameID, '\n')
	cat('Next file number: ', fnameID + 1, '\n')
	user.input = scan(file = '', what = character(), n = 1, quiet = TRUE)
	if (length(user.input) > 0) {
		if (user.input == 'q') loop = FALSE
		else if (user.input == 'r') { # Retry reading current ibutton
			loop = TRUE				# continue running
			fnameID = fnameID 		# do not increment name on retry
		}
		else if (user.input == 's') { # Skip next number because ibutton is 
									 # missing
			fnameID = fnameID + 2	# increment number by 2 to skip ahead
			skip.loop = TRUE # intialize "skip.loop" boolean
			# Enter into a while loop where user can increment or decrement
			# next file number as needed. A blank entry (hitting enter) will
			# kill the loop and use the current fnameID number
			while(skip.loop) {
				cat('Next file number: ', fnameID, '\n') # show user new number
				cat('Press enter to accept next file number.\n')
				cat('Press b to move back one value.\n')
				cat('Press s to skip forward one more value.\n')
				user.input = scan(file = '', what = character(), n = 1, 
						quiet = TRUE)
				if (length(user.input) > 0) {
					if (user.input == 'b') {
						fnameID = fnameID - 1 # decrement fnameID by 1
						skip.loop = TRUE # repeat loop to show current value
					} else if (user.input == 's') {
						fnameID = fnameID + 1 # increment fnameID by 1
						skip.loop = TRUE # repeat loop to show current value
					}
					} else skip.loop = FALSE # stop while loop
				}
				
				cat('Load next iButton to be read and hit enter when ready.\n')
				# Pause here and wait for user to hit enter to acknowledge that
				# they are ready to proceed.
				user.input = scan(file = '', what = character(), n = 1, 
						quiet = TRUE)
				loop = TRUE				# continue running main while loop
			}
			
			
		}
	 else { # If user hits enter or something besides r,s,q, just continue
		 	# looping in the normal sequence. 
		loop = TRUE	# no user input, continue on to next number in sequence
		fnameID = fnameID + 1 # Increment the file ID to next value (1,2,3 etc)
	}
}

cat('Finished\n')