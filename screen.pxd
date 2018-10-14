from xcb cimport *

cdef class Screen:

	cdef xcb_connection_t *c
	cdef xcb_screen_t *default_screen
	cdef int _screenNum
	cdef xcb_intern_atom_reply_t *edid_atom
	cdef xcb_generic_error_t *e
	cdef xcb_randr_get_screen_resources_reply_t *screen_resources_reply

	cdef _get_mode_info(self, xcb_randr_get_output_info_reply_t *output_info_reply, xcb_randr_mode_t mode)
	cdef char * _get_output_name(self, xcb_randr_get_output_info_reply_t *output_info_reply)
	cdef char * _get_edid_name(self, xcb_randr_output_t * output_p)
	cdef xcb_randr_output_t _get_primary_output(self)
	# cdef handler(cdef int signum)
