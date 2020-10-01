# Import modules
import getpass
import os
import progressbar
import re
import requests
from requests.auth import HTTPBasicAuth

# Ask for url
url = input("URL: ")
work_dir = input("Out directory (leave empty for current directory: ")

# Get page content
response = requests.get(url)
auth = False

# If HTTP auth, ask for credentials and try again
while response.status_code == 401:
    auth = True
    username = input("Username: ")
    password = getpass.getpass()
    response = requests.post(url, auth=HTTPBasicAuth(username, password))

# Get source
page_source = response.text

# Filter out names
files_unclean = re.findall(r'".+">', page_source)
files_clean = []
for file_unclean in files_unclean:
    files_clean.append(str(file_unclean).replace("\"", "").replace(">", ""))

# Download files
if len(work_dir) == 0:
    work_dir = os.path.dirname(os.path.realpath(__file__)) # Current directory

renamed = []
pbar = progressbar.ProgressBar(maxval=len(files_clean)).start()
for f in pbar(files_clean):
    # Paths
    file_url = url + "/" + f
    out_path = os.path.join(work_dir, f).replace(".gz", "")

    # Check if file exists already
    if os.path.isfile(out_path):
        temp_out_path = out_path
        counter = 0
        while os.path.isfile(temp_out_path):
            counter += 1
            temp_out_path = temp_out_path + "_" + str(counter)
        renamed.append(out_path + " already exists. Renaming to " + temp_out_path)
        out_path = out_path + "_" + str(counter)

    # Download file
    if auth:
        response = requests.post(file_url, auth=HTTPBasicAuth(username, password))
    else:
        response = requests.get(file_url)
    
    # Save the file
    with open(out_path, 'wb') as f:
        f.write(response.content)

# Print renamed files if any
if len(renamed) > 0:
    for message in renamed:
        print(message)
