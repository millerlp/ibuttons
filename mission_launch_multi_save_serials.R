# Filename: mission_launch_multi_save_serials.R
# A script to upload new missions to iButton Thermochron temperature 
# dataloggers. See the comments below for the additional external software 
# needed to make this run. This version will loop continuously and upload the 
# same mission to multiple iButtons so that they all start at the same 
# absolute time and sample at the same frequency. This version saves the serial
# number of each launched iButton in order in a csv file. 
# Author: Luke Miller  Nov 15, 2012
###############################################################################
setwd('D:/R/ibuttons') # Alter this for your needs, thermoms.exe must be in the
# current R working directory.

mem.length = 2048 # Number of data points the ibutton can hold. This is just 
# used to calculate when the last sample will be taken, so you can write it 
# down somewhere. 

# The thermoms.exe file was originally downloaded as part of the Maxim iButton 
# 1-Wire Public Domain Kit. 
# There are several versions of the Kit available, including
# versions with pre-compiled binaries (executables) for Windows/Linux/OSX.
# http://www.maxim-ic.com/products/ibutton/software/1wire/wirekit.cfm
# On my Windows 7 x64 computer using the DS9490B USB ibutton adapter, I used the
# precompiled binary build for Win64 USB (DS9490 + WinUSB) Preliminary Version 
# 3.11 Beta 2,
# filename: winusb64vc311Beta2_r2.zip, downloaded 2012-03-15
# Unzip this file and find the .exe files thermoms.exe (and thermodl.exe) in the
# builds\winusb64vc\release folder. Copy these to your R working directory.
# The drivers for the DS9490 USB iButton adapter must also be downloaded and 
# installed: 
# http://www.maxim-ic.com/products/ibutton/software/tmex/
# I downloaded and installed the file "install_1_wire_drivers_x64_v403.msi"
# The Java OneWireViewer app can also be downloaded and used to verify that your
# drivers work and that you can communicate with iButtons successfully through 
# the USB adapter. You can download this app here: 
# http://www.maxim-ic.com/products/ibutton/software/1wire/OneWireViewer.cfm
cat('*************************************************************\n\a')
cat('************RESET COMPUTER CLOCK TO STANDARD TIME************\n')
Sys.sleep(2)
cat('\a')
Sys.sleep(2)
cat('************SERIOUSLY, RESET YOUR CLOCK TO STANDARD TIME*********\a\n')
cat('*****************************************************************\n')
cat('Enter a desired mission start time as YYYY-MM-DD HH:MM\n')
cat('Or else enter 0 for immediate start. Delay must be less than 45.5 days.\n')
time.delay = scan(file = '', what = character(), n = 1, sep = ',')
# The sep value in scan is necessary so that spaces are not interpreted as the
# default record delimiter.

if (time.delay == '0') {
	launch = TRUE
} else {
	# Convert the date/time into a POSIX time object
	time.delay = as.POSIXct(strptime(time.delay, format = '%Y-%m-%d %H:%M'))
	
	# Check to make sure that the delay time is usable
	if (is.na(time.delay)) { # If time.delay can't be interpreted, fail 
		cat('Time could not be interpreted\a\n')
		cat('Quitting now\n')
		launch = FALSE
	}
	# If time.delay is a valid POSIX time, check that it is within limits
	if (!is.na(time.delay)) {
		curr.time = as.POSIXct(Sys.time()) # get current time
		# Check time difference between user's delay and current computer time
		t.diff = as.numeric(time.delay) - as.numeric(curr.time)
		t.diff = t.diff / 60 # convert to minutes
		
		if (t.diff < 0) {
			cat('Time delay is less than zero. Check your watch.\a\n')
			cat('Quitting now\n')
			launch = FALSE
		} else if (t.diff > 65535) {
			cat('Time delay is longer than 45.5 days. You are bad at math.\a\n')
			cat('Quitting now\n')
			launch = FALSE
		} else if (t.diff > 0 & t.diff < 1) {
			cat('Time delay is being set to 0 for immediate launch.\a\n')
			launch = TRUE
		} else { 
			# time.delay is a readable time, and t.diff is between 0 and 65535
			launch = TRUE
		}
	} # end of !is.na(time.delay) if-statement
} # end of time.delay if-statement

################################################################################
## Start the launch loop. 

if (launch) { # only do this part if launch == TRUE
	cat('Enter the desired sampling frequency in minutes (1 to 255):\n')
	freq = scan(file = '', what = numeric(), n = 1)
	freq = as.character(freq) # convert to character
	loop = TRUE # Set loop continuation variable to TRUE initially
	
	################
	# Calculate time of last sample
	ftime = time.delay + ((as.numeric(freq) * (mem.length - 1)) * 60)
	cat('Time of final sample: \n')
	cat(strftime(ftime),'\n*******************\n')
	################
	
	# Get current time to insert in filename so we don't overwrite old data
	currTime = strftime(Sys.time(), format = "%Y%m%d_%H%M")
	ser.file = paste('Launch_serials_',currTime,'.csv',sep = '')
	
	# The script will keep a tally of how many ibuttons have been
	# launched during this run. You can set a different starting 
	# number than 1 here.
	cat('Enter starting ibutton number (just to keep track):\n')
	num = scan(file="", what = numeric(), n = 1)
	if (length(num) == 0){
		num = 1 # If user didn't enter any thing, start at 1
	} else if (is.numeric(num)){
		num = num
	} else if (!is.numeric(num)){
		loop = FALSE
		launch = FALSE
		cat("Invalid number. Aborting\n")
	}
	
	# This while loop will repeat continuously to launch multiple iButtons.
	# The same parameters will be used to launch every iButton, except that the 
	# start delay (if >0) will automatically adjust as time elapses so that each
	# iButton will start at the same absolute time. The serial number of each
	# successfully launched iButton will be stored in the Launch_serials_xxx 
	# output file, in order of launching. 
	while (loop) {
		
		if (time.delay != '0') {
			curr.time = as.POSIXct(Sys.time()) # Get current time
			# Calculate difference between current time and time.delay value
			time.diff = as.numeric(time.delay) - as.numeric(curr.time)
			time.diff = time.diff / 60 # convert from seconds to minutes
			time.diff = floor(time.diff) # round down to nearest minute
			# iButtons only read out to the nearest minute. Rounding down to the
			# nearest minute should produce the proper delay to start at the 
			# desired time. 
			
			# If too much time elapses during this script, the time difference 
			# could eventually shrink to zero or less than zero. In that case, 
			# warn the user and set the iButton for immediate launch. 
			if (time.diff < 1) {
				time.diff = 0 # set for immediate launch.
				cat('*********************************\n')
				cat('Delay has shrunk to zero. Setting for immediate launch.')
				cat('*********************************\a\n')
			}
			time.diff = as.character(time.diff) # convert to character	
		} else { # time.delay was originally set to 0, so keep that.
			time.diff == '0'
		}
		cat('Calculated delay: ', time.diff, ' minutes\n')
# The thermoms.exe program expects a series of inputs in order to establish the
# mission parameters. Rgui doesn't work all that well with interactive command 
# line programs (Rterm is just fine, but our goal is to not have to interact), 
# so instead we'll create a character vector of answers to thermoms.exe's 
# queries and supply those via the input option of the system() function. 
# The parameters are as follows:
# Erase current mission (0) yes, (1) no. Answer: 0
# Enter start delay in minutes (0 to 65535). Answer: whatever you choose
# Enter sample rate in minutes (1 to 255). Answer: whatever you choose
# Enable roll-over (0) yes, (1) no. Answer: 1
# Enter high temperature threshold in Celsius (-40 to 70). Answer: 70
# Enter low temperature threshold in Celsius (-40 to 70). Answer: -40
		
		mission.params = c('0', # erase current mission 
				time.diff, # start delay in minutes (0 to 65535)
				freq, # sample rate in minutes (1 to 255)
				'1', # enable roll-over? 1 = no roll over
				'70', # high temperature threshold
				'-40') # low temperature threshold
		
# Launch thermoms.exe
# The 1st argument supplied to thermoms needs to be the location of the iButton 
# in the system. If using a DS9490B USB reader on Windows, you will probably get 
# away with using ds2490-0. The DS9490 USB reader uses a ds2490 chip internally, 
# so you need to tell thermoms.exe to look for a ds2490. 
		out = system('thermoms.exe ds2490-0', intern = TRUE, wait = TRUE, 
				input = mission.params)
		
# Check the output from the mission launch to ensure that the correct parameters
# were registered. Occasionally the time delay will not be properly registered 
# on the first launch, so the loops below will immediately relaunch the mission
# to get the time delay to register properly.

		# If no iButton is plugged in, this should be the failure message
		if (out[7] == 'Thermochron not present on 1-Wire') {
			cat('******************************************\n')
			cat(out[7],'\n')
			cat('******************************************\n')
		} else { # if out[7] is blank, a mission was probably uploaded
			for (i in 73:90) { # Display read-back from mission upload
				cat(out[i],'\n')
			}
			
			# Make sure the delay was actually entered correctly if it's >0
			# This while loop will run a maximum of 3 times. Each time through 
			# it will compare the output in out[73] to make sure the correct 
			# delay was returned from the iButton. If not, it will re-launch the
			# mission up to two more times before sending a failure message
			retry = 0
			while (retry < 3) {
				setting = out[79]
				nums = gregexpr('[0-9]', setting) # Find numbers in the string
				digs = substr(setting, nums[[1]][1], 
						nums[[1]][length(nums[[1]])]) # Extract delay value
				if (digs != time.diff & retry < 2) {
					# If delay value returned by iButton doesn't match the 
					# programmed delay, warn the user and re-launch the mission
					cat('*****************************************\n')
					cat('****Launch did not work, re-launching****\n')
					cat('*****************************************\n')
					out = system('thermoms.exe ds2490-0', intern = TRUE,
							wait = TRUE, input = mission.params)
					for (i in 73:90) { # Display the newly returned values
						cat(out[i],'\n')
					}
					retry = retry + 1 # increment the loop counter
					cat('---------------------------\n')
				} else if (digs != time.diff & retry == 2) {
					# If the returned delay still doesn't match the programmed
					# delay after two more iterations, send a failure message
					# to the user and let them deal with this issue. 
					# A common failure mode is due to a dead battery, which will
					# keep returning a clock time of 01/01/1970 00:00:00
					retry = 3
					cat('****************************************\n')
					cat('*****Uploaded failed, check iButton*****\n')
					cat('****************************************\n')
					for (i in 73:90) {
						cat(out[i],'\n')
					}
					
					answer = out[85] # Check the iButton's internal clock
					
					# Find the location of the date in this line (if present)
					d1 = regexpr('[0-9]{2}/[0-9]{2}/[0-9]{4}', answer)
					
					# Extract the date as a character string
					button.date = substr(answer, d1, 
							d1 + attr(d1,'match.length') - 1)
					
					# If the iButton date returns 01/01/1970, the iButton 
					# battery is probably dead
					if (button.date == '01/01/1970') {
						cat('********************************\n')
						cat('The iButton battery may be dead.\n')
						cat('********************************\n')
					}
					
				} else if (digs == time.diff) { # iButton mission launch worked
					# Read iButton serial number 
					ser.num = substr(out[73],26,nchar(out[73]))
					# Save the iButton serial number to the output file. Each
					# new serial is appended to the existing output file on a 
					# new line.
					write.table(ser.num,ser.file, append = TRUE, quote = FALSE,
							row.names = FALSE, col.names = FALSE)
					cat('\n----------Success---------\a\n')
					cat('Launch number ', num,'\n')
					num = num + 1 # increment number counter
					retry = 3 # This kills the retry while loop
				}
			} # End of retry while-loop
		} # End of if (out[7]... if-else statements

		# Ask the user to load the next iButton or quit.
		cat('Swap next iButton and press Enter to launch. Enter q to quit.\n')
		user.input = scan(file = '', what = character(), n = 1)
		if (length(user.input) > 0) { # Allows user to not type anything
			if (user.input == 'q') loop = FALSE # Kills loop
		} else {loop = TRUE}	
	} # End of 'loop' while-loop
} # End of 'launch' if-statement
cat('Time of final sample: \n')
cat(strftime(ftime),'\n*******************\n')
cat('Finished\n')
