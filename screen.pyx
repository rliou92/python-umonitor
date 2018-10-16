from cpython.mem cimport PyMem_Free, PyMem_Malloc
from cpython.pycapsule cimport PyCapsule_New, PyCapsule_GetPointer
import logging
import json
from libc.stdio cimport snprintf
from libc.string cimport strcpy

# Seems like certain cdefs are necessary, sometimes when I don't include the
# event detection doesn't work

cdef class Screen:

	def __cinit__(self):
		self.screen_resources_reply = NULL
		self.last_time = <xcb_timestamp_t> 0

	def connect_to_server(self):
		self._open_connection()
		self._get_default_screen()
		self._get_edid_atom()
		self.connected = True

	def __dealloc__(self):
		xcb_disconnect(self.c)
		PyMem_Free(self.edid_atom)
		PyMem_Free(self.screen_resources_reply)

	def _open_connection(self):
		self.c = xcb_connect(NULL, &self._screenNum)
		conn_error = xcb_connection_has_error(self.c)
		if conn_error != 0:
			raise Exception("Error connecting to X11 server. %s" % CONN_ERROR_LIST[conn_error - 1])
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
		cdef xcb_intern_atom_reply_t *edid_atom

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
		cdef xcb_randr_crtc_t *output_crtcs

		cdef xcb_randr_output_t *output_p = xcb_randr_get_screen_resources_outputs(self.screen_resources_reply)

		outputs_length = xcb_randr_get_screen_resources_outputs_length(self.screen_resources_reply)

		primary_output = self._get_primary_output()

		output_info = {}
		self.candidate_crtc = {}
		self.output_name_to_p = {}
		cdef int i
		for i in range(outputs_length):
			output_info_cookie = xcb_randr_get_output_info(self.c, output_p[i], XCB_CURRENT_TIME)
			output_info_reply = xcb_randr_get_output_info_reply(self.c, output_info_cookie, &self.e)

			if output_info_reply.connection:
				PyMem_Free(output_info_reply)
				continue

			# Output is connected
			output_name_bytes = self._get_output_name(output_info_reply)
			output_name = output_name_bytes.decode("UTF-8")
			output_info[output_name] = {}
			edid_name = self._get_edid_name(output_p + i)
			output_info[output_name]["edid"] = edid_name.decode("UTF-8")

			self.output_name_to_p[output_name] = PyCapsule_New(<void *> (output_p + i), NULL, NULL)

			if output_info_reply.crtc:
				# This output is enabled
				self.candidate_crtc[output_name] = output_info_reply.crtc

				if output_p[i] == primary_output:
					# This output is the primary output
					output_info[output_name]["primary"] = True

				crtc_info_cookie = xcb_randr_get_crtc_info(self.c, output_info_reply.crtc, self.screen_resources_reply.config_timestamp)
				crtc_info_reply = xcb_randr_get_crtc_info_reply(self.c, crtc_info_cookie, &self.e)

				output_info[output_name]["x"] = crtc_info_reply.x
				output_info[output_name]["y"] = crtc_info_reply.y
				output_info[output_name]["rotate_setting"] = crtc_info_reply.rotation

				mode_info = self._get_mode_info(output_info_reply, crtc_info_reply.mode)
				output_info[output_name] = {**output_info[output_name], **mode_info}

				PyMem_Free(crtc_info_reply)
			else:
				output_crtcs = xcb_randr_get_output_info_crtcs(output_info_reply)
				self.candidate_crtc[output_name] = [output_crtcs[j] for j in range(output_info_reply.num_crtcs)]

			PyMem_Free(output_info_reply)
			PyMem_Free(output_name_bytes)
			PyMem_Free(edid_name)

		self._assign_crtcs()
		return output_info

	def _assign_crtcs(self):
		already_assigned_crtcs = []

		for k in self.candidate_crtc:
			candidate_crtcs = self.candidate_crtc[k]
			if isinstance(candidate_crtcs, int):
				already_assigned_crtcs.append(candidate_crtcs)

		for k in self.candidate_crtc:
			candidate_crtcs = self.candidate_crtc[k]
			if isinstance(candidate_crtcs, list):
				available_crtcs = set(candidate_crtcs) - set(already_assigned_crtcs)
				chosen_crtc = list(available_crtcs)[0]
				self.candidate_crtc[k] = chosen_crtc
				already_assigned_crtcs.append(chosen_crtc)

	cdef _get_mode_info(self, xcb_randr_get_output_info_reply_t *output_info_reply, xcb_randr_mode_t mode):
		cdef xcb_randr_mode_t *mode_id_p
		cdef xcb_randr_mode_info_iterator_t mode_info_iterator

		num_output_modes = xcb_randr_get_output_info_modes_length(output_info_reply)
		mode_id_p = xcb_randr_get_output_info_modes(output_info_reply)

		mode_info = {}
		for i in range(num_output_modes):
			if mode_id_p[i] != mode:
				continue
			mode_info_iterator = xcb_randr_get_screen_resources_modes_iterator(self.screen_resources_reply)
			num_screen_modes = xcb_randr_get_screen_resources_modes_length(self.screen_resources_reply)
			for j in range(num_screen_modes):
				if mode_info_iterator.data.id == mode_id_p[i]:
					mode_info["width"] = mode_info_iterator.data.width
					mode_info["height"] = mode_info_iterator.data.height
					mode_info["mode_id"] = mode_id_p[i]
					# logging.debug("Dot clock: %s" % json.dumps(mode_info_iterator.data.dot_clock))
				xcb_randr_mode_info_next(&mode_info_iterator)

		return mode_info


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
		output_primary_cookie = xcb_randr_get_output_primary(self.c, self.default_screen.root)
		output_primary_reply = xcb_randr_get_output_primary_reply(self.c, output_primary_cookie, &self.e)
		primary_output = output_primary_reply.output
		PyMem_Free(output_primary_reply)
		return primary_output

	def _disable_outputs(self, keep_outputs):
		# Disable all crtcs except the ones that are the same as the target profile
		crtcs_p = xcb_randr_get_screen_resources_crtcs(self.screen_resources_reply)
		num_crtcs = self.screen_resources_reply.num_crtcs
		keep_crtcs = [self.candidate_crtc[output] for output in keep_outputs]
		logging.debug("Keep crtcs: %s" % json.dumps(keep_crtcs))

		cdef int i
		for i in range(num_crtcs):
			logging.debug("Checking to see if crtc %d should be disabled" % crtcs_p[i])
			if crtcs_p[i] in keep_crtcs:
				continue
			logging.debug("Disabling crtc %d" % (crtcs_p[i]))
			if self.dry_run:
				continue
			crtc_config_cookie = xcb_randr_set_crtc_config(
				self.c, crtcs_p[i],
				XCB_CURRENT_TIME,
				XCB_CURRENT_TIME, 0,
				0, XCB_NONE,
				XCB_RANDR_ROTATION_ROTATE_0,
				0, NULL)

		if self.dry_run:
			return

		crtc_config_reply = xcb_randr_set_crtc_config_reply(
			self.c,
			crtc_config_cookie,
			&self.e)
		self.last_time = crtc_config_reply.timestamp
		PyMem_Free(crtc_config_reply)

	def _change_screen_size(self, screen_info):
		# Recover widthMM, heightMM?
		# As I understand, not that important
		logging.debug("Changing screen size here: %s" % json.dumps(screen_info))
		if self.dry_run:
			return
		xcb_randr_set_screen_size(
			self.c,
			<xcb_window_t> self.default_screen.root,
			<uint16_t> screen_info["width"],
			<uint16_t> screen_info["height"],
			<uint16_t> screen_info["widthMM"],
			<uint16_t> screen_info["heightMM"])

	def _enable_outputs(self, output_info):
		for output in output_info:
			# Mode id seems to change on a laptop I use, so trying to recover it instead
			# Recover mode id
			# self._get_mode_id(output, output_info[output]["x"], output_info[output]["y"])

			logging.debug("Enabling crtc %d output %s" % (self.candidate_crtc[output], output))
			logging.debug(json.dumps(output_info[output]))
			if self.dry_run:
				continue
			crtc_config_cookie = xcb_randr_set_crtc_config(
				self.c,
				<xcb_randr_crtc_t> self.candidate_crtc[output],
				XCB_CURRENT_TIME,
				XCB_CURRENT_TIME,
				<int16_t> output_info[output]["x"],
				<int16_t> output_info[output]["y"],
				<xcb_randr_mode_t> output_info[output]["mode_id"],
				<uint16_t> output_info[output]["rotate_setting"],
				<uint32_t> 1, <xcb_randr_output_t *> PyCapsule_GetPointer(self.output_name_to_p[output], NULL))
			if output_info[output].get("primary", False):
				xcb_randr_set_output_primary(
					self.c,
					self.default_screen.root,
					<xcb_randr_crtc_t> self.candidate_crtc[output]
				)
		if self.dry_run:
			return
		crtc_config_reply = xcb_randr_set_crtc_config_reply(
			self.c,
			crtc_config_cookie,
			&self.e)
		self.last_time = crtc_config_reply.timestamp
		PyMem_Free(crtc_config_reply)

	# def _get_mode_id(output, x, y):
	#
	#

	def listen(self):
		self.connect_to_server()

		# self._exec_scripts = True

		# Subscribe to screen change events
		xcb_randr_select_input(self.c, self.default_screen.root, XCB_RANDR_NOTIFY_MASK_SCREEN_CHANGE)
		xcb_flush(self.c)

		while True:
			logging.info("Waiting for event")
			evt = xcb_wait_for_event(self.c)
			logging.debug("After the event, event response type is %d" % evt.response_type)
			if evt.response_type & XCB_RANDR_NOTIFY_MASK_SCREEN_CHANGE:
				logging.info("Received screen change event")
				randr_evt = <xcb_randr_screen_change_notify_event_t *> evt
				if randr_evt.timestamp >= self.last_time:
					logging.info("Event time is after last time of configuration")
					self.setup_info = self.get_setup_info()
					self.autoload()
			PyMem_Free(evt)

	def autoload(self):
		# To be overwritten
		pass

	def _get_screen_info(self):
		return {
			"width": self.default_screen.width_in_pixels,
			"height": self.default_screen.height_in_pixels,
			"widthMM": self.default_screen.width_in_millimeters,
			"heightMM": self.default_screen.height_in_millimeters
		}

	def get_setup_info(self):
		PyMem_Free(self.screen_resources_reply)
		screen_resources_cookie = xcb_randr_get_screen_resources(self.c, self.default_screen.root)
		self.screen_resources_reply = xcb_randr_get_screen_resources_reply(self.c, screen_resources_cookie, &self.e)
		screen_info = self._get_screen_info()
		output_info = self._get_output_info()
		return {"Screen":{**screen_info}, "Monitors":{**output_info}}
