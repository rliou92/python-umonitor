from xcb cimport *
from cpython.mem cimport PyMem_Free

cdef class Screen_Class:
	cdef xcb_connection_t *c
	cdef xcb_screen_t *default_screen
	cdef int _screenNum
	cdef xcb_intern_atom_reply_t *edid_atom
	cdef xcb_generic_error_t *e
	cdef xcb_randr_get_screen_resources_reply_t *screen_resources_reply
