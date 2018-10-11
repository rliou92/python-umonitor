#!/usr/bin/python

# from screen import Screen
from conf_manager import ConfManager
import logging
import argparse

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py

logging.basicConfig(level=logging.DEBUG)
config_file = "umon2.conf"
conf_manager = ConfManager(config_file)

parser = argparse.ArgumentParser(description="Manage monitor configuration.")
parser.add_argument("-w", "--view", dest="action", action="store_const", const=conf_manager.view_profiles, help="view configuration file")
parser.add_argument("profile_name", nargs="?", metavar="PROFILE", help="profile name")
mut_ex_group = parser.add_mutually_exclusive_group()
mut_ex_group.add_argument("-s", "--save", dest="action", action="store_const", const=conf_manager.save_profile, help="saves current setup into profile name")
mut_ex_group.add_argument("-l", "--load", dest="action", action="store_const", const=conf_manager.load_profile, help="load setup from profile name")
mut_ex_group.add_argument("-d", "--delete", dest="action", action="store_const", const=conf_manager.delete_profile, help="delete profile name from configuration file")

args = parser.parse_args()
# print(vars(args))
args.action(args.profile_name)
