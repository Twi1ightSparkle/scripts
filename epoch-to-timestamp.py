# Import modules
from datetime import datetime, timezone
from sys import argv

# Check input parameter, ask if none
if len(argv) == 2:
	time_stamp = argv[1]
elif len(argv) > 2:
	print("Error. Only zero or one parameters accepted.")
	exit(1)
else:
	time_stamp = input("Enter timestamp: ")

# Make sure input in an integer
try:
    time_stamp = int(time_stamp)
except ValueError:
    print("Invalid epoch timestamp supplied")
    exit(1)

# Validate input length and value
if 8 > int(len(str(time_stamp))) > 13 or time_stamp < 0:
    print("Invalid epoch timestamp supplied")
    exit(1)

# Convert to human readable
try:
    time_date = datetime.fromtimestamp(time_stamp, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
except ValueError:
    time_date = datetime.fromtimestamp(time_stamp / 1000, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

# Print answer
print(time_stamp, ': ', time_date, ' Zulu', sep='')