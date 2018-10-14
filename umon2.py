#!/usr/bin/python

from conf_manager import ConfManager, view_profiles
import logging
import argparse
import sys

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py

logging.basicConfig()
config_file = "umon2.conf"

parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS, description="Manage monitor configuration.")

mut_ex_group = parser.add_mutually_exclusive_group()
mut_ex_group.add_argument("-w", "--view", action="store_true", help="view configuration file")
mut_ex_group.add_argument("-s", "--save", metavar="PROFILE", help="saves current setup into profile name")
mut_ex_group.add_argument("-l", "--load", metavar="PROFILE", help="load setup from profile name")
mut_ex_group.add_argument("-d", "--delete", metavar="PROFILE", help="delete profile name from configuration file")
mut_ex_group.add_argument("-a", "--autoload", action="store_true", help="load profile that matches with current configuration once")
mut_ex_group.add_argument("-n", "--listen", action="store_true", help="listens for changes in the setup, and applies the new configuration automatically")
parser.add_argument("--dry_run", action="store_true", help="run program without changing configuration")
parser.add_argument("-v", "--verbose", action="count", help="set verbosity level, 1 = info, 2 = debug")

args = vars(parser.parse_args())

# Actions that do not require X11 connection

if "view" in args:
	view_profiles(config_file)
	sys.exit()

# Actions that require X11 connection
conf_manager = ConfManager(config_file)

if not args:
	conf_manager.view_current_status()
	sys.exit(0)

if "verbose" in args:
	logging_map = {
		1: logging.INFO,
		2: logging.DEBUG
	}
	logging.setLevel(logging_map[args["verbose"]])
	del args["verbose"]


if "dry_run" in args:
	conf_manager.dry_run = args["dry_run"]
	del args["dry_run"]

def save():
	conf_manager.save_profile(args["save"])

def load():
	conf_manager.load_profile(args["load"])

def delete():
	conf_manager.delete_profile(args["delete"])

def autoload():
	conf_manager.autoload()

def listen():
	conf_manager.listen()

action_map = {
	"save": save,
	"load": load,
	"delete": delete,
	"autoload": autoload,
	"listen": listen
}

for k in args:
	action_map[k]()
# if "save" in args:
#
# elif "load" in args:
#
# elif "delete" in args:
#
# elif "autoload" in args:
#
# elif "listen" in args:
