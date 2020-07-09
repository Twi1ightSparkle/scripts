# Import modules
import argparse
import dns.resolver
import json
import os
import smtplib
import socket
import time
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from notify_on_dns_change_config import Config



# Functions

def lookup_dns(hostname, dns_server='1.1.1.1'):
    """Look up DNS

    Look up CNAME DNS record

    Args:
        hostname: a hostname to look up
        dns_server: which DNS server to query

    Returns:
        a list of records, empty list of none found
    """

    records = []

    # Specify DNS server
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [socket.gethostbyname(dns_server)]

    # Look up CNAME records
    try:
        answers = dns.resolver.query(hostname, 'CNAME', raise_on_no_answer=False)
    except dns.resolver.NXDOMAIN:
        pass
    else:
        for rdata in answers:
            records.append(rdata.to_text()[:-1])

    return records


def send_email(subject, body):
    """Send an email"""

    # Set up the SMTP server
    s = smtplib.SMTP(host=Config.smtp_server, port=Config.smtp_port)
    s.starttls()
    s.login(Config.smtp_user, Config.smtp_password)

    msg = MIMEMultipart() # create a message

    # setup the parameters of the message
    msg['From'] = Config.send_from_name + ' <' + Config.send_from_address + '>'
    msg['To'] = Config.send_to_address
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    # Send message
    try:
        s.send_message(msg)
    except Exception:
        pass
        
    del msg # Delete message
    s.quit()  # Terminate the SMTP session and close the connection


def delete(x):
    # Remove the item
    for record in records[:]:
        if x == record['id']:
            records.remove(record)

    # Save to json file
    with open(json_file_path, 'w') as json_file:
        json.dump(records, json_file)


if __name__ == '__main__':
    # Get command line arguments
    parser = argparse.ArgumentParser(description='Periodically check if a CNAME record is changed to something new.')

    timer_group = parser.add_argument_group()
    timer = timer_group.add_mutually_exclusive_group(required=False)
    
    config_group = parser.add_argument_group(title='configure program')
    config = config_group.add_mutually_exclusive_group(required=True)
    
    timer.add_argument('-t', '--time', type=int, action='store', metavar='', default=1800, help='how often to recheck in seconds. default 1800 (30 minutes)')

    config.add_argument('-a', '--add', type=str, action='store', metavar='', help='add new record to watch in format somewhere.example.com;expected.target.com')
    config.add_argument('-d', '--delete', type=int, action='store', metavar='', help='delete a record')
    config.add_argument('-l', '--list', action='store_true', help='list records to check')
    config.add_argument('-r', '--run', action='store_true', help='run until there are no more records left')

    args = parser.parse_args()

    # Paths
    work_dir = os.path.dirname(os.path.realpath(__file__))
    json_file_path = os.path.join(work_dir, 'notify_on_dns_change.json')

    # Load file
    if os.path.isfile(json_file_path):
        with open(json_file_path, 'r') as json_file:
            try:
                records = json.load(json_file)
            except json.decoder.JSONDecodeError:
                records = []
    else:
        records = []


    if args.add:
        cname, target = str(args.add).split(';')

        # Get taken IDs
        ids = []
        for record in records:
            ids.append(record['id'])
        
        # Find first available ID
        for i in range(1, 999999):
            if not i in ids:
                record_id = i
                break

        # Add new record
        records.append({'id': record_id, 'cname': cname, 'target': target})

        # Save to json file
        with open(json_file_path, 'w') as json_file:
            json.dump(records, json_file)


    if args.delete:
        delete(args.delete)


    if args.list:
        for record in records:
            print(f"{record['id']}: {record['cname']} ---> {record['target']}")


    if args.run:
        print(f'Program running. Checking {len(records)} DNS records every {args.time} seconds. CTRL + C to exit')
        try:
            # Run forever until all records are removed from the list
            while len(records) > 0:
                found = []

                # Go through all records in json file
                for record in records:
                    # Look up CNAME records
                    cname_results = lookup_dns(record['cname'])

                    if record['target'] in cname_results:
                        found.append(record['id'])
                        send_email(
                            f"CNAME for {record['cname']} changed",
                            f"CNAME record {record['cname']} now points to {record['target']}"
                        )

                # Remove found ones from the json data and file
                if len(found) > 99:
                    for f in found:
                        delete(f)

                # Wait
                time.sleep(args.time)
        except KeyboardInterrupt:
            print('\nExiting')
            exit(0)
