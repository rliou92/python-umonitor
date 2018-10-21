#!/usr/bin/python

import logging
import argparse
from screen import Screen
import json
import os
import subprocess
import daemon

class Umonitor(Screen):

	def __init__(self, config_folder, config_fn):
		self.config_folder = config_folder
		self.config_file = config_folder + config_fn
		self.config_fn = config_fn
		self.dry_run = False
		self.connected = False
		self._exec_scripts = True

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
			self._prevent_duplicate_running()
			if self._daemonize:
				with daemon.DaemonContext() as my_daemon:
					self.listen()
			else:
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

		self._prevent_duplicate_running()

		logging.debug("Setup info: %s" % json.dumps(self.setup_info))
		logging.debug("Target profile data: %s" % json.dumps(target_profile_data))
		if self.setup_info == target_profile_data and not self.force_load:
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
					and target_profile_data["Monitors"][k].get("width", False):
					keep_outputs.append(k)
					continue
				delta_profile_data["Monitors"][k] = target_profile_data["Monitors"][k]
			else:
				delta_profile_data["Monitors"][k] = {}
				delta_profile_data["Monitors"][k]["width"] = 0


		logging.debug("Delta profile: %s" % json.dumps(delta_profile_data))

		# Disable outputs
		logging.debug("Candidate crtcs: %s" % json.dumps(self.candidate_crtc))
		logging.debug("Keep outputs: %s" % json.dumps(keep_outputs))
		if self.force_load:
			self._disable_outputs([])
		else:
			self._disable_outputs(keep_outputs)
		# Change screen size
		self._change_screen_size(delta_profile_data["Screen"])
		# Enable outputs
		enable_outputs = {k:delta_profile_data["Monitors"][k] for k in delta_profile_data["Monitors"] if delta_profile_data["Monitors"][k].get("width", 0) != 0}
		if enable_outputs:
			logging.info("Enabling outputs.")
			self._enable_outputs(enable_outputs)
		else:
			logging.info("No outputs to enable.")

		print("Profile %s loaded" % (profile_name))

		if self._exec_scripts:
			self.exec_scripts(profile_name)

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
				return

		logging.info("No profile matches current configuration.")

	def view_current_status(self):
		self.connect_to_server()
		self.setup_info = self.get_setup_info()

		if not self.profile_data:
			print("No configuration file found. Start by saving one using 'umon2.py -s <profile_name>'.")
		for profile in self.profile_data:
			out = profile
			logging.debug("Profile data: %s" % self.profile_data[profile])
			if self.profile_data[profile]["Monitors"] == self.setup_info["Monitors"]:
				logging.debug("Profile %s matches current setup" % (profile))
				out += "*"
			print(out)

		logging.debug("Current status: %s" % self.setup_info)
		logging.debug("Candidate crtcs: %s" % self.candidate_crtc)

	def _prevent_duplicate_running(self):
		with open(os.devnull, "w") as devnull_fh:
			pgrep_out = subprocess.run(["pgrep", "-c", "umonitor"], capture_output=True)
		# logging.debug(float(pgrep_out.stdout.decode("UTF-8")))
		if float(pgrep_out.stdout.decode("UTF-8")) > 1:
			raise Exception("umonitor is already running. Please kill that process and try again.")

	def view_profiles(self):
		print(json.dumps(self.profile_data, indent=4))

	def exec_scripts(self, profile_name):
		os.environ["UMONITOR_PROFILE"] = profile_name
		for script in os.listdir(self.config_folder):
			if script != self.config_fn[1:] and not script.startswith("."):
				logging.info("Running script %s" % script)
				if self.dry_run:
					continue
				subprocess.run(self.config_folder + "/" + script)

	def parse_args(self):
		parser = argparse.ArgumentParser(description="Manage monitor configuration.")

		mut_ex_group = parser.add_mutually_exclusive_group()
		# TODO add a version option
		mut_ex_group.add_argument("-w", "--view", action="store_true", help="view configuration file")
		mut_ex_group.add_argument("-s", "--save", metavar="PROFILE", help="saves current setup into profile name")
		mut_ex_group.add_argument("-l", "--load", metavar="PROFILE", help="load setup from profile name")
		mut_ex_group.add_argument("-d", "--delete", metavar="PROFILE", help="delete profile name from configuration file")
		mut_ex_group.add_argument("-a", "--autoload", dest="_autoload", action="store_true", help="load profile that matches with current configuration once")
		mut_ex_group.add_argument("-n", "--listen", dest="_listen", action="store_true", help="listens for changes in the setup, and applies the new configuration automatically")
		mut_ex_group.add_argument("-g", "--get_active_profile", dest="gap", action="store_true", help="returns current active profile")
		parser.add_argument("--dry_run", action="store_true", help="run program without changing configuration")
		parser.add_argument("-v", "--verbose", default=0, action="count", help="set verbosity level, 1 = info, 2 = debug")
		parser.add_argument("-f", "--force", dest="force_load", action="store_true", help="disable all outputs even if they do not change during loading")
		parser.add_argument("--daemonize", dest="_daemonize", action="store_true", help="daemonize when listening to events")

		parser.parse_args(namespace=self)

		logging_map = {
			0: logging.WARNING,
			1: logging.INFO,
			2: logging.DEBUG
		}
		logger = logging.getLogger()
		logger.setLevel(logging_map[self.verbose])
