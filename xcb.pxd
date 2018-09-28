cdef list CONN_ERROR_LIST = [
	"XCB_CONN_ERROR",
	"XCB_CONN_CLOSED_EXT_NOTSUPPORTED",
	"XCB_CONN_CLOSED_MEM_INSUFFICIENT",
	"XCB_CONN_CLOSED_REQ_LEN_EXCEED",
	"XCB_CONN_CLOSED_PARSE_ERR",
	"XCB_CONN_CLOSED_INVALID_SCREEN",
	"XCB_CONN_CLOSED_FDPASSING_FAILED"
]

cdef extern from "<xcb/xcb.h>":

	cdef struct xcb_connection_t:
		# Opaque structure containing all data that  XCB needs to communicate with an X server.
		pass

	ctypedef struct xcb_screen_t:
		pass

	ctypedef struct xcb_intern_atom_reply_t:
		pass

	cdef struct xcb_setup_t:
		pass

	ctypedef struct xcb_screen_iterator_t:
		xcb_screen_t *data;
		pass

	ctypedef struct xcb_generic_error_t:
		pass

	xcb_setup_t *xcb_get_setup(xcb_connection_t *c)
	xcb_connection_t *xcb_connect(const char *displayname, int *screenp)
	int xcb_connection_has_error(xcb_connection_t *c)
	xcb_screen_iterator_t xcb_setup_roots_iterator (const xcb_setup_t *R)
	void xcb_screen_next (xcb_screen_iterator_t *i)
