from cpython.mem cimport PyMem_Free, PyMem_Malloc
import logging
from libc.stdio cimport snprintf
from libc.string cimport strcpy

cdef class Screen_Class:

	def __cinit__(self):
		self.screen_resources_reply = NULL
		# self.output_info_reply_list = NULL

	def __init__(self):
		logging.basicConfig(level=logging.DEBUG)
		self._open_connection()
		self._get_default_screen()
		self._get_edid_atom()
		# self.update_screen()

	def _open_connection(self):
		self.c = xcb_connect(NULL, &self._screenNum)
		conn_error = xcb_connection_has_error(self.c)
		if conn_error != 0:
			raise SystemExit("Error connecting to X11 server. %s" % CONN_ERROR_LIST[conn_error - 1])
		logging.info("Connected to X11 server.")

	def _get_default_screen(self):
		cdef const xcb_setup_t *setup

		setup = xcb_get_setup(self.c)
		iter = xcb_setup_roots_iterator(setup)

		# we want the screen at index screenNum of the iterator
		for i in range(0, self._screenNum):
			xcb_screen_next(&iter)

		self.default_screen = iter.data

	def _get_edid_atom(self):
		only_if_exists = 1
		cdef const char *edid_name = "EDID"
		name_len = len(edid_name)
		atom_cookie = xcb_intern_atom(self.c, only_if_exists, name_len, edid_name)
		self.edid_atom = xcb_intern_atom_reply(self.c, atom_cookie, &self.e)
		while self.edid_atom.atom == XCB_ATOM_NONE:
			atom_cookie = xcb_intern_atom(self.c, only_if_exists, name_len, edid_name)
			self.edid_atom = xcb_intern_atom_reply(self.c, atom_cookie, &self.e)

	def _get_output_info(self):
		cdef xcb_randr_get_output_info_cookie_t output_info_cookie
		cdef xcb_randr_get_output_info_reply_t *output_info_reply
		cdef xcb_randr_output_t primary_output
		cdef xcb_randr_get_crtc_info_cookie_t crtc_info_cookie
		cdef xcb_randr_get_crtc_info_reply_t *crtc_info_reply

		cdef xcb_randr_output_t *output_p = xcb_randr_get_screen_resources_outputs(self.screen_resources_reply)

		outputs_length = xcb_randr_get_screen_resources_outputs_length(self.screen_resources_reply)

		primary_output = self._get_primary_output()

		screen_info = {}
		cdef int i
		for i in range(outputs_length):
			output_info_cookie = xcb_randr_get_output_info(self.c, output_p[i], XCB_CURRENT_TIME)
			output_info_reply = xcb_randr_get_output_info_reply(self.c, output_info_cookie, &self.e)

			if output_info_reply.connection:
				PyMem_Free(output_info_reply)
				continue

			# Output is connected
			output_name = self._get_output_name(output_info_reply)
			screen_info[output_name] = {}
			edid_name = self._get_edid_name(output_p + i)
			screen_info[output_name]["edid"] = edid_name

			if output_info_reply.crtc:
				# This output is enabled
				if output_p[i] == primary_output:
					# This output is the primary output
					screen_info[output_name]["primary"] = True

				crtc_info_cookie = xcb_randr_get_crtc_info(self.c, output_info_reply.crtc, self.screen_resources_reply.config_timestamp)
				crtc_info_reply = xcb_randr_get_crtc_info_reply(self.c, crtc_info_cookie, &self.e)

				screen_info[output_name]["x"] = crtc_info_reply.x
				screen_info[output_name]["y"] = crtc_info_reply.y
				screen_info[output_name]["rotate_setting"] = crtc_info_reply.rotation

		return screen_info





	cdef char * _get_output_name(self, xcb_randr_get_output_info_reply_t *output_info_reply):
		cdef uint8_t *output_name_raw = xcb_randr_get_output_info_name(output_info_reply)
		output_name_length = xcb_randr_get_output_info_name_length(output_info_reply)
		output_name = <char *> PyMem_Malloc((output_name_length + 1) * sizeof(char))

		for i in range(output_name_length):
			output_name[i] = <char> output_name_raw[i]

		output_name[output_name_length] = '\0'
		logging.info("Output name %s" % output_name)
		return output_name

	cdef char * _get_edid_name(self, xcb_randr_output_t * output_p):
		cdef int i, j, model_name_found, edid_length
		cdef uint8_t delete = 0
		cdef uint8_t pending = 0
		cdef xcb_randr_get_output_property_cookie_t output_property_cookie
		cdef xcb_randr_get_output_property_reply_t *output_property_reply
		cdef uint8_t *edid

		cdef char vendor[4]
		cdef char modelname[13]

		output_property_cookie = xcb_randr_get_output_property(
			self.c, output_p[0], self.edid_atom.atom,
			AnyPropertyType, 0, 100, delete, pending)
		output_property_reply = xcb_randr_get_output_property_reply(
			self.c, output_property_cookie, &self.e)

		edid_length = xcb_randr_get_output_property_data_length(output_property_reply)

		edid = xcb_randr_get_output_property_data(output_property_reply)

		edid_string = <char *> PyMem_Malloc(17 * sizeof(char))

		if edid_length == 0:
			strcpy(vendor,"N/A")
			strcpy(modelname, "unknown")
			snprintf(edid_string, 17, "%s %s", vendor, modelname)
			PyMem_Free(output_property_reply)
			logging.info("Finished edid_to_string on output %s" % edid_string)
			return NULL

		cdef char sc = <char> (ord('A') - 1)
		vendor[0] = <char> (sc + (edid[8] >> 2))
		vendor[1] = <char> (sc + (((edid[8] & 0x03) << 3) | (edid[9] >> 5)))
		vendor[2] = <char> (sc + (edid[9] & 0x1F))
		vendor[3] = '\0'

		# product = (edid[11] << 8) | edid[10];
		# serial = edid[15] << 24 | edid[14] << 16 | edid[13] << 8 | edid[12];
		# edid_info = malloc(length*sizeof(char));
		# snprintf(edid_info, length, "%04X%04X%08X", vendor, product, serial);

		model_name_found = 0
		for i in range(0x36, 0x7E, 0x12): # read through descriptor blocks...
			if edid[i] != 0x00 or edid[i + 3] != 0xfc:
				continue	# not a timing descriptor
			model_name_found = 1
			for j in range(0, 13):
				if edid[i + 5 + j] == 0x0a:
					modelname[j] = <char> 0x00
				else:
					modelname[j] = <char> edid[i + 5 + j]

		if not model_name_found:
			strcpy(modelname, "unknown")

		# printf("vendor: %s\n",vendor);
		# printf("modelname: %s\n",modelname);
		# 3 for vendor, 1 for space, 12 for modelname, 1 for null
		snprintf(edid_string, 17, "%s %s", vendor, modelname)

		PyMem_Free(output_property_reply)
		logging.info("Finished edid_to_string on output %s" % edid_string)
		return edid_string



	cdef xcb_randr_output_t _get_primary_output(self):
		cdef xcb_randr_get_output_primary_cookie_t output_primary_cookie = xcb_randr_get_output_primary(self.c, self.default_screen.root)
		cdef xcb_randr_get_output_primary_reply_t *output_primary_reply = xcb_randr_get_output_primary_reply(self.c, output_primary_cookie, &self.e)
		cdef xcb_randr_output_t primary_output = output_primary_reply.output
		PyMem_Free(output_primary_reply)
		return primary_output



	def update_screen(self):
		PyMem_Free(self.screen_resources_reply)
		screen_resources_cookie = xcb_randr_get_screen_resources(self.c, self.default_screen.root)
		self.screen_resources_reply = xcb_randr_get_screen_resources_reply(self.c, screen_resources_cookie, &self.e)
		return self._get_output_info()
