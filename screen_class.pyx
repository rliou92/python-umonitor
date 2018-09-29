import logging

cdef class Screen_Class:
	cdef xcb_connection_t *c
	cdef xcb_screen_t *default_screen
	cdef int _screenNum
	cdef xcb_intern_atom_reply_t *edid_atom
	cdef xcb_generic_error_t *e
	cdef xcb_randr_get_screen_resources_reply_t *screen_resources_reply


	def __init__(self):
		self.screen_resources_reply = NULL
		logging.basicConfig(level=logging.DEBUG)
		self._open_connection()
		self._fetch_default_screen()
		self._fetch_edid_atom()
		self.update_screen()

	def _open_connection(self):
		self.c = xcb_connect(NULL, &self._screenNum)
		conn_error = xcb_connection_has_error(self.c)
		if conn_error != 0:
			raise SystemExit("Error connecting to X11 server. %s" % CONN_ERROR_LIST[conn_error - 1])
		logging.info("Connected to X11 server.")

	def _fetch_default_screen(self):
		cdef const xcb_setup_t *setup

		setup = xcb_get_setup(self.c)
		iter = xcb_setup_roots_iterator(setup);

		# we want the screen at index screenNum of the iterator
		for i in range(0, self._screenNum):
			xcb_screen_next(&iter)

		self.default_screen = iter.data

	def _fetch_edid_atom(self):
		only_if_exists = 1
		cdef const char *edid_name = "EDID"
		name_len = len(edid_name)
		atom_cookie = xcb_intern_atom(self.c, only_if_exists, name_len, edid_name)
		self.edid_atom = xcb_intern_atom_reply(self.c, atom_cookie, &self.e)
		while self.edid_atom.atom == XCB_ATOM_NONE:
			atom_cookie = xcb_intern_atom(self.c, only_if_exists, name_len, edid_name)
			self.edid_atom = xcb_intern_atom_reply(self.c, atom_cookie, &self.e)

	def update_screen(self):
		PyMem_Free(self.screen_resources_reply)
		screen_resources_cookie = xcb_randr_get_screen_resources(self.c, self.default_screen.root)
		self.screen_resources_reply = xcb_randr_get_screen_resources_reply(self.c, screen_resources_cookie, &self.e)
