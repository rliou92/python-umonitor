#!/usr/bin/python

import logging
import argparse
import sys
from screen import Screen
import json
import logging

class Umonitor(Screen):

	def __init__(self, config_file):
		super().__init__()
		self.config_file = config_file
		self.setup_info = self.get_setup_info()
		self.dry_run = False

		try:
			with open(self.config_file, "r") as config_fh:
				self.profile_data = json.load(config_fh)
		except json.JSONDecodeError:
			raise Exception("Configuration file is not valid JSON.")
		except FileNotFoundError:
			self.profile_data = {}
			self.config_file_exists = False
		else:
			self.config_file_exists = True

	def save_profile(self, profile_name):

		with open(self.config_file, "w") as config_fh:
			# TODO check for overwriting
			logging.debug(self.profile_data)
			if self.profile_data[profile_name]:
				logging.warning("Overwriting previous profile")
			self.profile_data[profile_name] = self.setup_info
			json.dump(self.profile_data, config_fh, indent=4)

		print("Profile %s saved." % (profile_name))

	def delete_profile(self, profile_name):

		if self.config_file_exists == False:
			raise Exception("Configuration file does not exist.")

		logging.debug(self.profile_data)

		try:
			del self.profile_data[profile_name]
		except KeyError:
			raise Exception("Profile %s does not exist in configuration file." % profile_name)

		with open(self.config_file, "w") as config_fh:
			logging.debug(self.profile_data)
			json.dump(self.profile_data, config_fh, indent=4)

		print("Profile %s deleted." % (profile_name))

	def load_profile(self, profile_name):

		if self.config_file_exists == False:
			raise Exception("Configuration file does not exist.")

		try:
			target_profile_data = self.profile_data[profile_name]
		except KeyError:
			raise Exception("Profile %s does not exist in configuration file." % profile_name)

		logging.debug("Setup info: %s" % json.dumps(self.setup_info))
		logging.debug("Target profile data: %s" % json.dumps(target_profile_data))
		if self.setup_info == target_profile_data:
			print("Profile %s is already loaded." % profile_name)
			return

		if self.setup_info["Monitors"].keys() != target_profile_data["Monitors"].keys():
			logging.warning("Trying to load a profile that doesn't match the current configuration（monitors don't match)")
		else:
			for k in self.setup_info["Monitors"]:
				if self.setup_info["Monitors"][k]["edid"] != target_profile_data["Monitors"][k]["edid"]:
					logging.warning("Trying to load a profile that doesn't match the current configuration (edid don't match)")
					break

		# Determine which outputs need to be changed
		keep_outputs = []
		delta_profile_data = {"Screen": target_profile_data["Screen"], "Monitors": {}}
		for k in self.setup_info["Monitors"]:
			if k in target_profile_data["Monitors"]:
				if self.setup_info["Monitors"][k] == target_profile_data["Monitors"][k]:
					keep_outputs.append(k)
					continue
				delta_profile_data["Monitors"][k] = target_profile_data["Monitors"][k]
			else:
				delta_profile_data["Monitors"][k] = {}
				delta_profile_data["Monitors"][k]["mode_id"] = 0


		logging.debug("Delta profile: %s" % json.dumps(delta_profile_data))

		# Disable outputs
		logging.debug("Candidate crtcs: %s" % json.dumps(self.candidate_crtc))
		self._disable_outputs(keep_outputs)
		# Change screen size
		self._change_screen_size(delta_profile_data["Screen"])
		# Enable outputs
		self._enable_outputs({k:delta_profile_data["Monitors"][k] for k in delta_profile_data["Monitors"] if delta_profile_data["Monitors"][k].get("mode_id", 0) != 0})

		print("Profile %s loaded" % (profile_name))

	def autoload(self):
		# Loads first profile that matches the current configuration outputs
		for profile in self.profile_data:
			if self.profile_data[profile]["Monitors"].keys() == self.setup_info["Monitors"].keys():
				logging.debug("Outputs in profile %s matches current setup, loading" % (profile))
				print("Profile %s found to match, loading..." % (profile))
				self.load_profile(profile)
				return

		logging.info("No profile matches current configuration.")

	def view_current_status(self):
		if not self.profile_data:
			print("No configuration file found. Start by saving one using 'umon2.py -s <profile_name>'.")
		for profile in self.profile_data:
			out = profile
			if self.profile_data[profile] == self.setup_info:
				logging.debug("Profile %s matches current setup" % (profile))
				out += "*"
			print(out)

def view_profiles(config_file):

	try:
		with open(config_file, "r") as config_fh:
			profile_data = json.load(config_fh)
	except json.JSONDecodeError:
		raise Exception("Configuration file is not valid JSON.")
	except FileNotFoundError:
		raise Exception("Configuration file does not exist.")

	print(json.dumps(profile_data, indent=4))

def main():
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
	umon = Umonitor(config_file)

	if not args:
		umon.view_current_status()
		sys.exit(0)

	if "verbose" in args:
		logging_map = {
			1: logging.INFO,
			2: logging.DEBUG
		}
		logging.setLevel(logging_map[args["verbose"]])
		del args["verbose"]


	if "dry_run" in args:
		umon.dry_run = args["dry_run"]
		del args["dry_run"]

	def save(umon):
		umon.save_profile(args["save"])

	def load(umon):
		umon.load_profile(args["load"])

	def delete(umon):
		umon.delete_profile(args["delete"])

	def autoload(umon):
		umon.autoload()

	def listen(umon):
		umon.listen()

	actions = {
		"save": self.save_profile,
		"load": self.load_profile,
		"delete": self.delete_profile,
		"autoload": self.autoload,
		"listen": self.listen
	}

	for k in args:
		action_map[k]()

if __name__ == "__main__":
	main()
