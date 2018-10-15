#!/usr/bin/python

import logging
import argparse
from screen import Screen
import json
import os
import subprocess

class Umonitor(Screen):

	def __init__(self, config_folder):
		self.config_folder = config_folder
		self.config_file = config_folder + "/umon2.conf"
		self.dry_run = False
		self.connected = False

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

	def run(self):
		if self.save:
			self.save_profile()
		elif self.load:
			self.load_profile()
		elif self._autoload:
			self.autoload()
		elif self.view:
			self.view_profiles()
		elif self.gap:
			self.get_active_profile()
		elif self._listen:
			self.listen()
		elif self.delete:
			self.delete_profile()
		else:
			self.view_current_status()

	def get_active_profile(self):
		self.connect_to_server()
		self.setup_info = self.get_setup_info()

		if not self.profile_data:
			print("No configuration file found. Start by saving one using 'umon2.py -s <profile_name>'.")

		for profile in self.profile_data:
			if self.profile_data[profile] == self.setup_info:
				logging.debug("Profile %s matches current setup" % (profile))
				print(profile)

	def save_profile(self, profile_name=None):
		if profile_name is None:
			profile_name = self.save
		self.connect_to_server()
		self.setup_info = self.get_setup_info()

		with open(self.config_file, "w") as config_fh:
			# TODO check for overwriting
			logging.debug(self.profile_data)
			if self.profile_data.get(profile_name, False):
				logging.warning("Overwriting previous profile")
			self.profile_data[profile_name] = self.setup_info
			json.dump(self.profile_data, config_fh, indent=4)

		print("Profile %s saved." % (profile_name))

	def delete_profile(self, profile_name=None):
		if profile_name is None:
			profile_name = self.delete

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

	def load_profile(self, profile_name=None):
		if profile_name is None:
			profile_name = self.load

		if self.connected == False:
			self.connect_to_server()
			self.setup_info = self.get_setup_info()

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
				if self.setup_info["Monitors"][k] == target_profile_data["Monitors"][k] \
					and target_profile_data["Monitors"][k].get("mode_id", False):
					keep_outputs.append(k)
					continue
				delta_profile_data["Monitors"][k] = target_profile_data["Monitors"][k]
			else:
				delta_profile_data["Monitors"][k] = {}
				delta_profile_data["Monitors"][k]["mode_id"] = 0


		logging.debug("Delta profile: %s" % json.dumps(delta_profile_data))

		# Disable outputs
		logging.debug("Candidate crtcs: %s" % json.dumps(self.candidate_crtc))
		logging.debug("Keep outputs: %s" % json.dumps(keep_outputs))
		self._disable_outputs(keep_outputs)
		# Change screen size
		self._change_screen_size(delta_profile_data["Screen"])
		# Enable outputs
		self._enable_outputs({k:delta_profile_data["Monitors"][k] for k in delta_profile_data["Monitors"] if delta_profile_data["Monitors"][k].get("mode_id", 0) != 0})

		print("Profile %s loaded" % (profile_name))

	def autoload(self):
		if self.connected == False:
			self.connect_to_server()
			self.setup_info = self.get_setup_info()

		# Loads first profile that matches the current configuration outputs
		for profile in self.profile_data:
			if self.profile_data[profile]["Monitors"].keys() == self.setup_info["Monitors"].keys():
				logging.debug("Outputs in profile %s matches current setup, loading" % (profile))
				print("Profile %s found to match, loading..." % (profile))
				self.load_profile(profile)
				self.exec_scripts(profile)
				return

		logging.info("No profile matches current configuration.")

	def view_current_status(self):
		self.connect_to_server()
		self.setup_info = self.get_setup_info()

		if not self.profile_data:
			print("No configuration file found. Start by saving one using 'umon2.py -s <profile_name>'.")
		for profile in self.profile_data:
			out = profile
			if self.profile_data[profile] == self.setup_info:
				logging.debug("Profile %s matches current setup" % (profile))
				out += "*"
			print(out)

		logging.debug("Current status: %s" % self.setup_info)
		logging.debug("Candidate crtcs: %s" % self.candidate_crtc)

	def view_profiles(self):
		print(json.dumps(self.profile_data, indent=4))

	def exec_scripts(self, profile_name):
		os.environ["UMONITOR_PROFILE"] = profile_name
		for script in os.listdir(self.config_folder):
			if script != "umon2.conf":
				logging.info("Running script %s" % script)
				subprocess.run("./" + self.config_folder + "/" + script)

def main():
	# setup = current state of monitors, their resolutions, positions, etc
	# profile = loaded from configuration file

	# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py
	logging.basicConfig()

	try:
		config_folder = os.environ["HOME"]
	except KeyError:
		raise Exception("Need home environment variable to locate configuration file.")
	config_folder+= "/.config/umon"

	parser = argparse.ArgumentParser(description="Manage monitor configuration.")

	mut_ex_group = parser.add_mutually_exclusive_group()
	mut_ex_group.add_argument("-w", "--view", action="store_true", help="view configuration file")
	mut_ex_group.add_argument("-s", "--save", metavar="PROFILE", help="saves current setup into profile name")
	mut_ex_group.add_argument("-l", "--load", metavar="PROFILE", help="load setup from profile name")
	mut_ex_group.add_argument("-d", "--delete", metavar="PROFILE", help="delete profile name from configuration file")
	mut_ex_group.add_argument("-a", "--autoload", dest="_autoload", action="store_true", help="load profile that matches with current configuration once")
	mut_ex_group.add_argument("-n", "--listen", dest="_listen", action="store_true", help="listens for changes in the setup, and applies the new configuration automatically")
	mut_ex_group.add_argument("-g", "--get_active_profile", dest="gap", action="store_true", help="returns current active profile")
	parser.add_argument("--dry_run", action="store_true", help="run program without changing configuration")
	parser.add_argument("-v", "--verbose", default=0, action="count", help="set verbosity level, 1 = info, 2 = debug")

	umon = Umonitor(config_folder)
	parser.parse_args(namespace=umon)

	logging_map = {
		0: logging.WARNING,
		1: logging.INFO,
		2: logging.DEBUG
	}
	logger = logging.getLogger()
	logger.setLevel(logging_map[umon.verbose])

	umon.run()


if __name__ == "__main__":
	main()
