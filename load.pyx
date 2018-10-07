from xcb import *
from screen cimport Screen

class Load:

	def __init__(self):
		pass

	def load_profile(self, profile_name):
		# Find candidate crtcs
		screen = Screen()
		setup_info = screen.get_setup_info()
		
