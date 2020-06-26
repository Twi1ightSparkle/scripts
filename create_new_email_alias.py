import pyperclip
import random
import sys
from subprocess import call
from sys import argv
from sys import platform


if len(argv) == 2:
	email = argv[1]
elif len(argv) > 2:
	print("Error. Only zero or one parameters accepted.")
	sys.exit(1)
else:
	email = input("Enter the site name: ")

characters = "abcdefghijklmnopqrstuvwxyz0123456789"
email += "-"
for i in range(5):
	r = random.SystemRandom()
	email += r.choice(characters)
email += "@twilightsparkle.dev"

pyperclip.copy(email)

print(
	"\nNew randomized email:", email,
	"\nThis has been copied to the clipboard\n"
)

if platform == "win32":
	input("Press Enter to exit")
