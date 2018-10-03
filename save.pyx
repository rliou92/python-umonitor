import configparser

cdef class Save_Class:

	def __init__(self, screen_o):
		self.screen_o = screen_o
		config = configparser.ConfigParser()
