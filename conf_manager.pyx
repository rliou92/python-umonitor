from xcb cimport *
from screen cimport Screen
import json
import logging
import os

cdef class ConfManager(Screen):

	def __init__(self):
		super().__init__()

	def save_profile(self, profile_name, config_file):
		setup_info = self.get_setup_info()

		try:
			with open(config_file, "r") as config_fh:
				profile_data = json.load(config_fh)
		except json.JSONDecodeError:
			raise Exception("Configuration file is not valid JSON.")
		except FileNotFoundError:
			profile_data = {}

		with open(config_file, "w") as config_fh:
			# TODO check for overwriting
			logging.debug(profile_data)
			profile_data[profile_name] = setup_info
			json.dump(profile_data, config_fh, indent=4)


	def delete_profile(self, profile_name, config_file):
		setup_info = self.get_setup_info()

		try:
			with open(config_file, "r") as config_fh:
				profile_data = json.load(config_fh)
		except json.JSONDecodeError:
			raise Exception("Configuration file is not valid JSON.")
		except FileNotFoundError:
			raise Exception("Configuration file does not exist.")

		logging.debug(profile_data)

		try:
			del profile_data[profile_name]
		except KeyError:
			raise Exception("Profile %s does not exist in configuration file." % profile_name)

		with open(config_file, "w") as config_fh:
			logging.debug(profile_data)
			json.dump(profile_data, config_fh, indent=4)
