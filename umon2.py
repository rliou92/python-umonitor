#!/usr/bin/python

# from screen import Screen
from conf_manager import ConfManager, view_profiles
import logging
import argparse
import sys

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py



logging.basicConfig(level=logging.DEBUG)
config_file = "umon2.conf"

parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS, description="Manage monitor configuration.")

mut_ex_group = parser.add_mutually_exclusive_group()
mut_ex_group.add_argument("-w", "--view", action="store_true", help="view configuration file")
mut_ex_group.add_argument("-s", "--save", metavar="PROFILE", help="saves current setup into profile name")
mut_ex_group.add_argument("-l", "--load", metavar="PROFILE", help="load setup from profile name")
mut_ex_group.add_argument("-d", "--delete", metavar="PROFILE", help="delete profile name from configuration file")

args = parser.parse_args()
args_list = list(vars(args).keys())
print(args_list)
if not args_list:
	print("Print out current state")
	sys.exit()

action = args_list[0]

if action == 'view':
	view_profiles(config_file)
	sys.exit()

profile_name = args_list[1]
conf_manager = ConfManager(config_file)
function_map = {
	"save": conf_manager.save_profile,
	"load": conf_manager.load_profile,
	"delete": conf_manager.delete_profile
	}
function_map[action](profile_name)
