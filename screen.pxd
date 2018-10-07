from xcb cimport *

cdef class Screen:
	cdef xcb_connection_t *c
	cdef xcb_screen_t *default_screen
	cdef int _screenNum
	cdef xcb_intern_atom_reply_t *edid_atom
	cdef xcb_generic_error_t *e
	cdef xcb_randr_get_screen_resources_reply_t *screen_resources_reply
	# cdef xcb_randr_get_output_info_reply_t **output_info_reply_list
	# cdef xcb_randr_get_output_info_reply_t *output_info_reply
	cdef char * _get_output_name(Screen, xcb_randr_get_output_info_reply_t *output_info_reply)
	cdef char * _get_edid_name(Screen, xcb_randr_output_t * output_p)
	cdef xcb_randr_output_t _get_primary_output(Screen)
	cdef _get_mode_info(Screen, xcb_randr_get_output_info_reply_t *output_info_reply, xcb_randr_mode_t mode)
