import pyperclip
import random

# import sys
# from sys import argv
# if len(argv) == 2:
# 	email = argv[1]
# elif len(argv) > 2:
# 	print("Error. Only zero or one parameters accepted.")
# 	sys.exit(1)
# else:
# 	email = input("Enter the site name: ")

characters = "abcdefghijklmnopqrstuvwxyz0123456789"
email = ""
for i in range(20):
	r = random.SystemRandom()
	email += r.choice(characters)
email += "@"
for i in range(20):
	r = random.SystemRandom()
	email += r.choice(characters)
email += ".twily.me"

pyperclip.copy(email)

print(
	"\nNew randomized email:", email,
	"\nThis has been copied to the clipboard\n"
)
