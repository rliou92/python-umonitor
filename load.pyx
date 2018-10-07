import configparser

class Save_Class:

	def __init__(self, screen_info):
		config = configparser.ConfigParser()
		with open("umon2.conf", "w") as configfile:
			config.write(screen_info)
