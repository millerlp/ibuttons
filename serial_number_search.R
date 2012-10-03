# Filename: serial_number_search.R
# This script collects a list of ibutton serial numbers from csv files so that
# you can check whether the current ibutton has already been downloaded. 
# The intended use case is when you have been downloading ibuttons using a 
# script like 'ibutton_download_increment_names.R', and one of the ibuttons
# didn't download properly, but you weren't paying attention and moved on to 
# further ibuttons. Now you have an iButton in your discard pile that wasn't 
# read properly, but you can't identify it. The un-read ibutton didn't produce
# a csv file (since there were no data), so you know which number you missed,
# but not which ibutton it was. Use this script to get a list of all of the 
# ibutton serial numbers that have been read (by reading all of the output csv
# files in the output folder), and then placing ibuttons in the ibutton reader
# and comparing the current ibutton's serial number to the list of successfully
# downloaded iButtons. If the current ibutton doesn't match any of those, this
# script will beep at you and notify you that it doesn't match. Ideally, this is
# iButton that didn't download successfully the first time, and you can now 
# return to the ibutton download script to download it. 
# Author: Luke Miller  Oct 3, 2012
###############################################################################

# Set the current R working directory to whatever folder you need to search in

fnames = dir(pattern = '.csv'); # get list of csv file names in current directory

serials = vector(mode = "character", length = 0)
# Step through each file and extract the ibutton serial number from the 3rd
# column
for (i in 1:length(fnames)) {
	temp = read.csv(fnames[i])
	serials[i] = as.character(temp[1,3]) # pull serial from 1st row, 3rd column	
}
loop = TRUE
while (loop) {
	cat('Hit return to continue and read ibutton, or hit q to quit.\n')
	toss = scan(file = '', what = double(), n = 1)
	if (length(toss) == 0) {
# Read
		fname = paste(getwd(),'\\test.dat', sep = '')
# Call the thermodl.exe program provided by Maxim. This must be in the 
# current R working directory. Start by assembling a command to be issued.
		sys.com = paste('d:/R/ibuttons/thermodl.exe ds2490-0 ', fname, sep = '')
# Now issue the command to the system using the system() function.
		temp = system(sys.com, wait = TRUE, intern = TRUE)
# Open the data file created by thermodl.exe
		x = readLines(fname) # read data into a character vector
# Extract serial number from line 4 of file
		serialnum = substr(x[4], 26, nchar(x[4]))
		
		if (serialnum %in% serials) {
			cat('Serial number exists in set of current files.\n')
		} else if (!(serialnum %in% serials)) {
			cat('\aSerial number not found in current files.\n')
		}
		loop = TRUE 	# repeat loop
	} else if (length(toss) > 0 & toss == 'q') {
		loop = FALSE 	# quit loop
	} else if (length(toss) > 0 & toss != 'q') {
		loop = TRUE # user screwed up, repeat loop
	}
	
}


