import logging

cdef class Screen_Class:

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

	def _fetch_output_info(self):
		cdef xcb_randr_get_output_info_cookie_t output_info_cookie
		cdef xcb_randr_get_output_info_reply_t *output_info_reply

		cdef xcb_randr_output_t *output_p = xcb_randr_get_screen_resources_outputs(self.screen_resources_reply)

		outputs_length = xcb_randr_get_screen_resources_outputs_length(self.screen_resources_reply)

		self.output_info_reply_list = []
		for i in range(outputs_length):
			output_info_cookie = xcb_randr_get_output_info(self.c, output_p[i], XCB_CURRENT_TIME)
			output_info_reply = xcb_randr_get_output_info_reply(self.c, output_info_cookie, &self.e)
			self.output_info_reply_list.append(output_info_reply)

	def _get_primary_output(self):
		cdef xcb_randr_get_output_primary_cookie_t output_primary_cookie = xcb_randr_get_output_primary(self.c, self.default_screen.root)
		cdef xcb_randr_get_output_primary_reply_t *output_primary_reply = xcb_randr_get_output_primary_reply(self.c, output_primary_cookie, &self.e)
		self.primary_output = output_primary_reply.output



	def update_screen(self):
		PyMem_Free(self.screen_resources_reply)
		screen_resources_cookie = xcb_randr_get_screen_resources(self.c, self.default_screen.root)
		self.screen_resources_reply = xcb_randr_get_screen_resources_reply(self.c, screen_resources_cookie, &self.e)
		self._get_primary_output()
		self._fetch_output_info()
