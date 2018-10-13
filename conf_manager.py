from screen import Screen
import json
import logging

class ConfManager(Screen):

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
			self.profile_data[profile_name] = self.setup_info
			json.dump(self.profile_data, config_fh, indent=4)

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

	def autoload(self):
		# Loads first profile that matches the current configuration outputs
		for profile in self.profile_data:
			if self.profile_data[profile]["Monitors"].keys() == self.setup_info["Monitors"].keys():
				logging.debug("Outputs in profile %s matches current setup, loading" % (profile))
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
