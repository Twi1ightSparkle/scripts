# Variables
send_from_name = 'Your Name'
send_from_address = 'support@domain.tld'
smtp_server = 'smtp.domain.tld'
smtp_port = 587
smtp_user = 'username'
smtp_password = 'password'
subject = 'This is a subject line'
def message(name):
    return f'''Dear {name},

This is the
email body.

Best wishes,
Support
'''


# Import modules
import csv
from datetime import datetime
import os
import progressbar
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


# Set paths
workDir = os.path.dirname(os.path.realpath(__file__))
emails_file_path = os.path.join(workDir, 'mass_send_emails.txt')
log_file_path = os.path.join(workDir, 'mass_send_emails.log')


# Read csv file to a list
with open(emails_file_path, newline='') as csvfile:
    data = list(csv.reader(csvfile, delimiter =';'))


# Get confirmation
password_dots = ''
for _ in range(len(smtp_password)):
    password_dots += '*'

print(f'''
   ==============================================================================
   =  ====  ====  =====  =====       ===  =======  ==    ==  =======  ===      ==
   =  ====  ====  ====    ====  ====  ==   ======  ===  ===   ======  ==   ==   =
   =  ====  ====  ===  ==  ===  ====  ==    =====  ===  ===    =====  ==  ====  =
   =  ====  ====  ==  ====  ==  ===   ==  ==  ===  ===  ===  ==  ===  ==  =======
   =   ==    ==  ===  ====  ==      ====  ===  ==  ===  ===  ===  ==  ==  =======
   ==  ==    ==  ===        ==  ====  ==  ====  =  ===  ===  ====  =  ==  ===   =
   ==  ==    ==  ===  ====  ==  ====  ==  =====    ===  ===  =====    ==  ====  =
   ===    ==    ====  ====  ==  ====  ==  ======   ===  ===  ======   ==   ==   =
   ====  ====  =====  ====  ==  ====  ==  =======  ==    ==  =======  ===      ==
   ==============================================================================


    WARNING, you are about to send {len(data)} emails with the following details

    SMTP server     : {smtp_server}
    SMTP port       : {smtp_port}
    SMTP username   : {smtp_user}
    SMTP password   : {password_dots}
    
    From            : {send_from_name} <{send_from_address}>

    Subject line    : {subject}
    Message:

{message('Jane Doe')}
''')
confirmation = input('Type yes in uppercase to continue: ')
if not confirmation == 'YES':
    print('Exiting...')
    exit(1)


def log_writer(message, first=False):
    """Write timestamp and message to logfile"""
    time_stamp = datetime.utcnow()
    time_stamp_short = time_stamp.strftime('%Y.%m.%dT%H.%M.%S.%fZ')
    log = open(log_file_path, 'a+')
    if first:
        log.write('\n\n')
    log.write(f'{time_stamp_short} - {message}\n')
    log.close()


# Print and log start information
print('\n\nSending emails...')
start_time = datetime.utcnow()
log_writer('New email batch job started', first=True)
error_counter = 0


# Send emails one at the time
pbar = progressbar.ProgressBar(maxval=len(data)).start()
for host in pbar(data):

    # Set up the SMTP server
    s = smtplib.SMTP(host=smtp_server, port=smtp_port)
    s.starttls()
    s.login(smtp_user, smtp_password)

    msg = MIMEMultipart() # create a message

    message_str = message(host[1]) # Add mesage body

    # setup the parameters of the message
    msg['From'] = send_from_name + ' <' + send_from_address + '>'
    msg['To'] = host[2]
    msg['Subject'] = subject

    msg.attach(MIMEText(message_str, 'plain'))

    # Send message
    try:
        s.send_message(msg)
    except Exception as err:
        log_writer(f'Error sending email to {host[1]} <{host[2]}> for hostname {host[0]} - Error message: {err}')
        error_counter += 1
    else:
        log_writer(f'Successfully sent email to {host[1]} <{host[2]}>')
        
    del msg # Delete message
    s.quit()  # Terminate the SMTP session and close the connection

# Calculate and log runtime
finish_time = datetime.utcnow()
runtime = finish_time - start_time
log_writer(f'Email batch job finished. Runtime {runtime}')


# Print end information
error_message = ''
if error_counter == 1:
    error_message = f'\n{error_counter} error handeled. Please check the log.'
elif error_counter > 1:
    error_message = f'\n{error_counter} errors handeled. Please check the log.'

print(f'\n\nEmail batch job finished. Runtime {runtime}.{error_message}\nLogged to {log_file_path}\n')
