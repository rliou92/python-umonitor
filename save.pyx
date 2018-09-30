import configparser

cdef class Save_Class:
	cdef Screen_Class screen_o

	def __init__(self, screen_o):
		self.screen_o = screen_o
		config = configparser.ConfigParser()

	def _fetch_output_info(self):
		pass
