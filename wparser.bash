#!/bin/bash

#Shyam Desai
#ECSE - U1 Software Engineering
#shyam.desai@mail.mcgill.ca

set +x  #debugging messages

#if the number of arguments passsed (i.e. $#) to invoke the script isn't equal to 1, then print usage and exit with error code 1
if [[ "$#" -ne 1 ]]; then
	echo "Usage $0 <weatherdatadir>"
	exit 1
fi

#if the directory passed as an argument (i.e. $1) doesn't exist (using ! -d), then throw error message to stderr (using >&2) and exit with error code 1
if [[ ! -d $1 ]]; then
	>&2 echo "Error! $1 is not a valid directory name"
	exit 1
fi

extractData() { 
	echo "Processing Data From $1"
	echo "===================================="
	echo "Year,Month,Day,Hour,TempS1,TempS2,TempS3,TempS4,TempS5,WindS1,WindS2,WindS3,WinDir"

	#finds the the specfic file asp    assed into the method and filters the data inside into only lines of interest i.e. temperature, wind speed, and wind dire    ction readings
	find $(dirname $1) -name $(basename $1) -exec grep -h "observation line" '{}' + |
	#removes '[data log flushed]' and 'observation line' readings, replaces 'NOINF' and 'MISSED     SYNC STEP' readings with X, and removes the first semicolons (separating hour and minute:second) from timestamps and the     first two dashes corresponding to the dates
	sed -e 's/\[data log flushed\]//' -e 's/MISSED SYNC STEP/X/g' -e 's/NOINF/X/g' -e 's/observation line//' -e 's/:/ /' -e 's/-/ /' -e 's/-/ /' | 
	awk 'BEGIN {FS=" "} {print $1, $2, $3, $4, $6, $7, $8, $9, $10, $11, $12, $13, $14}' | #filters unnecessary data i.e. minutes and seconds timestamps
	awk 'BEGIN {FS=" "}  
		{if ($13=="0") $13="N"; 
			else if ($13=="1") $13="NE"; 
				else if ($13=="2") $13="E"; 
					else if ($13=="3") $13="SE"; 
						else if ($13=="4") $13="S"; 
							else if ($13=="5") $13="SW"; 
								else if ($13=="6") $13="W"; 
									else if ($13=="7") $13="NW";} 
		{print $0}' | #replaces the wind direction readings [0,7] with [N,NE,E,SE,S,SW,W,NW] respectively
	awk 'BEGIN {FS=" "; OFS=","}
		{for(i=1; i<=NF; i++)
			{if(i>=5 && i<=9 && $i!="X")
				{temperatures[i]=$i};
			if($i=="X")
				{$i=temperatures[i]}}
		 print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13}' #stores temperature values in an array unless the reading is "X", then it replaces the existing value with reading from the previous hour (since the value was not overridden in the array). We're following the assumption the sensor is always flawless for the first hour of any day
	
	echo "===================================="
	echo "Observation Summary"
	echo "Year,Month,Day,Hour,MaxTemp,MinTemp,MaxWS,MinWS"

#similar to above, files are found and the data is filtered into a desirable format to get the minimum and maximum values of the temperature and wind sensors
	find $(dirname $1) -name $(basename $1) -exec grep -h "observation line" '{}' + | 
	sed -e 's/\[data log flushed\]//' -e 's/MISSED SYNC STEP/X/g' -e 's/NOINF/X/g' -e 's/observation line//' -e 's/:/ /' -e 's/-/ /' -e 's/-/ /' | 
	awk 'BEGIN {FS=" "} {print $1, $2, $3, $4, $6, $7, $8, $9, $10, $11, $12, $13, $14}' | 
	#set maximum and minimum values out of range of the temperature and wind speed sensors, then iterate through all the values and update the min/max values. After one line is parsed, reset the min/max to be out of range to repeat the process for all hours of the day
	awk -v maxtemp=-999 -v mintemp=999 -v maxwindspeed=-999 -v minwindspeed=999 'BEGIN {FS=" "; OFS=","} 
		{for(i=5; i<=12; i++) 
			{if($i!="X") 
				{if(i<=9 && $i>maxtemp) {maxtemp=$i}; 
				if(i<=9 && $i<mintemp) {mintemp=$i}; 
				if(i>=10 && $i>maxwindspeed) {maxwindspeed=$i}; 
				if(i>=10 && $i<minwindspeed) {minwindspeed=$i}}}
		 print $1, $2, $3, $4, maxtemp, mintemp, maxwindspeed, minwindspeed; maxtemp=-999; mintemp=999; maxwindspeed=-999; minwindspeed=999}'

	echo "===================================="
	echo
}


#iterate through the directory (i.e. $1) and recursively find all files (using type -f option) with names of the form 'weather_info_*.data'
for filepath in $(find $1 -type f -name "weather_info_*.data")
do
	extractData $filepath #send the full path of the file to the method
done

#iterate through the directory and find all the files of the desired pattern; we defined a separate for loop to take advantage of piping it's output in the end to create a HTML table
for filepath in $(find $1 -type f -name "weather_info_*.data")
do
	cat $filepath | #retrieve raw data of the file and extract lines with sensor readings
	grep -h "observation line" | 
	#data is simplified into a desirable format so we can find the number of times each temperature sensor has an error in a day and the total number of errors from all the sensors in a day
	sed -e 's/\[data log flushed\] //' -e 's/MISSED SYNC STEP/X/g' -e 's/NOINF/X/g' |
	sed 's/-/ /' | sed 's/-/ /'  | 
	awk 'BEGIN {FS=" "} {print $1, $2, $3, $7, $8, $9, $10, $11}' | #hiding wind sensor data too this time
	#if the temperature reading says "X" (which would've been recorded as 'NOINF' or 'MISSED SYNC STEP' by the temperature sensor), then increase the error count for the particular sensor by 1. after the data for all hours of the day has been parsed, then output only the necessary data for the HTML file. the 'Total' is found by taking the sum of all the errors from the sensors in the day. every sensor initially has 0 errors in a day
	awk -v error1=0 -v error2=0 -v error3=0 -v error4=0 -v error5=0	'BEGIN {FS=" "} 
		{if ($4=="X") 
			{error1++} 
		if($5=="X") 
			{error2++} 
		if($6=="X") 
			{error3++} 
		if($7=="X") 
			{error4++} 
		if($8=="X") 
			{error5++}} 
	END {print $1, $2, $3, error1, error2, error3, error4, error5, error1+error2+error3+error4+error5}'

done | 
	sed -e 's/ /-/' -e 's/ /-/' | #add back two dashes to the dates to put it in YYYY-MM-DD format
	#first, sort the dates into chronological order using the -k option that allows to take the 1st column using -t to set " " as the delimeter. Then, pipe the output and sort again in order of the total number of errors by using the -k option to pick the 7th column. The -s option ensures the order isn't random when two values are equal
	sort -s -t " " -k 1 | sort -s -k 7 |
	sed -e 's/-/ /g' | #remove the dashes from the dates again
	#creates a HTML file. The tags and the header row that occur only once goes in the 'BEGIN' block, and the closing tags for them goes in the 'END' block. In between, sets the design to have all the errors from one day in one row
	awk 'BEGIN {FS=" "; print "<HTML><BODY><H2>Sensor error statistics</H2><TABLE><TR><TH>Year</TH><TH>Month</TH><TH>Day</TH><TH>TempS1</TH><TH>TempS2</TH><TH>TempS3</TH><TH>TempS4</TH><TH>TempS5</TH><TH>Total</TH></TR>"} {print "<TR><TD>" $1 "</TD><TD>" $2 "</TD><TD>" $3 "</TD><TD>" $4 "</TD><TD>" $5 "</TD><TD>" $6 "</TD><TD>" $7 "</TD><TD>" $8" </TD><TD>" $9 "</TD></TR>"} END {print "</TABLE></BODY></HTML>"}' > sensorstats.html
