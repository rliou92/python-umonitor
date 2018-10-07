from screen import Screen
import json
import logging
import os

class ConfManager(Screen):

	def __init__(self, config_file):
		super().__init__()
		self.config_file = config_file
		self.setup_info = self.get_setup_info()
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

	def view_profile(self, profile_name):

		if self.config_file_exists == False:
			raise Exception("Configuration file does not exist.")

		print(json.dumps(self.profile_data, indent=4))
