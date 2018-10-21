import logging
import os
from umonitor.umonitor import Umonitor

def main():
	# setup = current state of monitors, their resolutions, positions, etc
	# profile = loaded from configuration file

	# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py
	logging.basicConfig()

	try:
		home = os.environ["HOME"]
	except KeyError:
		raise Exception("Need home environment variable to locate configuration file.")
	config_folder = home + "/.config/umon"
	config_fn = "/umon.conf"

	logging.debug("Looking here for config file: %s" % config_folder + config_fn)

	umon = Umonitor(config_folder, config_fn)
	umon.parse_args()
	umon.run()
