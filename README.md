# Sensor Log Parser
The Sensor Log Parser program is a Bash script designed to parse and analyze data files generated from a weather monitoring process. Using advanced Unix utilities, this script processes temperature and wind sensor data from multiple files, extracts relevant information, and generates detailed summaries and reports.

The data files are generated from five different temperature sensors, three wind speed sensors, and one wind direction sensor.

## Features
1. **Log Parsing**: Extracts temperature and wind readings from log files, ignoring diagnostic and irrelevant lines.
2. **Data Aggregation**: Handles missing temperature sensor readings by using the last known valid reading.
3. **Observation Summaries**: Generates summaries with minimum and maximum temperatures and wind speeds for each hour.
4. **Error Report Generation**: Produces a daily report of sensor errors, including an HTML file ranking the days with the highest number of errors.

## Functions
### `extractData`
This function processes each log file to:
- Extract relevant temperature and wind data, handling "NOINF" and "MISSED SYNC STEP" errors by substituting the previous valid reading.
- Generate hourly summaries of max/min temperatures and wind speeds.

## Execution Output
The script processes each log file and produces formatted output for temperature and wind readings, as shown below:
![image](https://user-images.githubusercontent.com/21160813/187308254-8b4f9524-a0c5-44db-8a9c-226e462494a0.png)
Example output generated after parsing the data files

### Observation Summary
The script also generates an observation summary with maximum and minimum temperature and wind speed readings reported for every hour.
![image](https://user-images.githubusercontent.com/21160813/187308391-ed412f8e-d92a-4ad8-a24b-ae13aab3418d.png)
Example output generated showing the maximum and minimum temperature and wind speed reported for every hour.

### Sensor Error Statistics
The program generates an HTML report (`sensorstats.html`) showing the number of times each temperature sensor reports an error daily. This HTML table is sorted in descending order based on the number of errors.
![image](https://user-images.githubusercontent.com/21160813/187308509-868d93dd-e294-4912-a878-d0c2c493844d.png)
Example sensor error statistics generated using HTML showing the number of times each temperature sensor reports an error every day.

---

## Setup
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/shyamddesai/WeatherSense
   cd WeatherSense
   ```

2. **Make the Script Executable**:
   Ensure the script has executable permissions:
   ```bash
   chmod +x wparser.bash
   ```

3. **Run the Script**:
   Execute the script with the directory containing log files:
   ```bash
   ./wparser.bash <weatherdatadir>
   ```

## Requirements
- **Directory Argument**: The script requires a directory as an argument containing weather data files (`weather_info_*.data`). If not provided or incorrect, an error message will display.
- **Data Format**: Log files should follow the specified structure, containing temperature and wind readings with occasional sensor errors.

## Error Handling
- **Invalid Directory**: If the specified directory does not exist, the script exits with an error message.
- **Missing Arguments**: If the directory argument is missing, the script provides usage instructions.
