from xcb cimport *
from screen cimport Screen
import json
import logging

cdef class ConfManager(Screen):

	def __init__(self):
		super().__init__()

	def save_profile(self, profile_name, config_file):
		setup_info = self.get_setup_info()

		try:
			with open(config_file, "r") as config_fh:
				profile_data = json.load(config_fh)
		else:
			profile_data = {}

		with open(config_file, "w") as config_fh:
			logging.debug(profile_data)
			profile_data[profile_name] = setup_info
			json.dump(profile_data, config_fh, indent=4)


	def delete_profile(self, profile_name, config_file):
		setup_info = self.get_setup_info()

		try:
			with open(config_file, "r") as config_fh:
				profile_data = json.load(config_fh)
		else:
			profile_data = {}

		logging.debug(profile_data)

		try:
			del profile_data[profile_name]
		except KeyError:
			print("Profile %s does not exist in configuration file." % profile_name)
			return

		with open(config_file, "w") as config_fh:
			logging.debug(profile_data)
			json.dump(profile_data, config_fh, indent=4)
