#!/usr/bin/env bash

# Provide the dataset URL and local filename
URL="https://data.virginia.gov/dataset/3f21b42b-efd9-44e5-b9ef-aeaef6cbb0e2/resource/6442c5a2-4aa0-4e1f-8701-c4d89ace2bfd/download/vdh-covid-19-publicusedataset-ww-viral-load.csv"
CSV_FILE="wastewater_data.csv"

# Download the CSV file, following redirects
curl -s -S -L -o $CSV_FILE $URL

# Check that the file was downloaded successfully
if [[ ! -f $CSV_FILE ]]; then
    echo "Error: Failed to download the CSV file"
    exit 1
fi

# Use csvkit's csvgrep to filter rows with 'Sewershed' equal to 'Moores Creek'
cville_rows=$(csvgrep -c "Sewershed" -m "Moores Creek" $CSV_FILE)

# Prepare a data file (e.g., from the filtered CSV)
echo "$cville_rows" | csvcut -c "Sample Collect Date","Concentration" > cville_data.csv

# Sort the data by 'Sample Collect Date' in descending order and extract the 200 most recent samples
csvsort -c "Sample Collect Date" -r cville_data.csv | head -n 201 > cville_data_recent.csv

# Verify that the file has at least 201 lines
line_count=$(wc -l < cville_data_recent.csv)

if [ "$line_count" -lt 10 ]; then
    echo "Not enough data to be plausible -- quitting"
    exit 1
fi

# Plot the data using Gnuplot
gnuplot -persist <<-EOFMarker
    set datafile separator ","
    set title "C'ville Covid Wastewater Concentration" font ",18"
    set xlabel "Sample Date" font ",14"
    set ylabel "Concentration (Gene Copies per Liter)" font ",14"
    set xdata time
    set timefmt "%Y-%m-%d"
    set format x "%Y-%m"
    set terminal png size 1200,800
    set style line 1 lc rgb '#0000aa' lw 3
    set output "wastewater.png"
    plot 'cville_data_recent.csv' using 1:2 smooth csplines with lines linestyle 1 title 'Concentration'
EOFMarker

echo "Done"
