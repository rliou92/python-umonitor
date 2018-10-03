from libc.stdint cimport *

cdef extern from "<xcb/xcb.h>":

	cdef struct xcb_connection_t:
		# Opaque structure containing all data that  XCB needs to communicate with an X server.
		pass

	ctypedef uint32_t xcb_window_t
	ctypedef struct xcb_screen_t:
		xcb_window_t root
		pass

	ctypedef uint32_t xcb_atom_t
	ctypedef struct xcb_intern_atom_reply_t:
		xcb_atom_t atom;
		pass

	cdef struct xcb_setup_t:
		pass

	ctypedef struct xcb_screen_iterator_t:
		xcb_screen_t *data;
		pass

	ctypedef struct xcb_generic_error_t:
		pass

	ctypedef struct xcb_intern_atom_cookie_t:
		pass

	xcb_setup_t *xcb_get_setup(xcb_connection_t *c)
	xcb_connection_t *xcb_connect(const char *displayname, int *screenp)
	int xcb_connection_has_error(xcb_connection_t *c)
	xcb_screen_iterator_t xcb_setup_roots_iterator (const xcb_setup_t *R)
	void xcb_screen_next (xcb_screen_iterator_t *i)
	xcb_intern_atom_cookie_t xcb_intern_atom (
				xcb_connection_t *c,
				uint8_t           only_if_exists,
				uint16_t          name_len,
				const char       *name)
	xcb_intern_atom_reply_t *xcb_intern_atom_reply (xcb_connection_t *c,
 	                       xcb_intern_atom_cookie_t cookie,
 	                       xcb_generic_error_t **e)


cdef extern from "<xcb/randr.h>":
	ctypedef uint32_t xcb_randr_crtc_t
	ctypedef uint32_t xcb_timestamp_t
	ctypedef uint32_t xcb_randr_output_t

	ctypedef struct xcb_randr_get_screen_resources_cookie_t:
		pass

	ctypedef struct xcb_randr_get_screen_resources_reply_t:
		pass

	ctypedef struct xcb_randr_get_output_primary_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_primary_reply_t:
		xcb_randr_output_t output
		pass

	ctypedef struct xcb_randr_get_crtc_info_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_info_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_info_reply_t:
		pass


	xcb_randr_get_screen_resources_reply_t * xcb_randr_get_screen_resources_reply (
			xcb_connection_t                         *c,
			xcb_randr_get_screen_resources_cookie_t   cookie,
			xcb_generic_error_t                     **e)

	xcb_randr_get_screen_resources_cookie_t xcb_randr_get_screen_resources ( xcb_connection_t *c, xcb_window_t window)


	xcb_randr_get_output_primary_cookie_t xcb_randr_get_output_primary (xcb_connection_t *c, xcb_window_t window);

	xcb_randr_get_output_primary_reply_t * xcb_randr_get_output_primary_reply (xcb_connection_t *c, xcb_randr_get_output_primary_cookie_t cookie, xcb_generic_error_t **e)

	xcb_randr_get_crtc_info_cookie_t xcb_randr_get_crtc_info ( xcb_connection_t *c, xcb_randr_crtc_t  crtc, xcb_timestamp_t config_timestamp)

	xcb_randr_output_t * xcb_randr_get_screen_resources_outputs (const xcb_randr_get_screen_resources_reply_t *R)

	int xcb_randr_get_screen_resources_outputs_length (const xcb_randr_get_screen_resources_reply_t *R)

	xcb_randr_get_output_info_cookie_t xcb_randr_get_output_info (xcb_connection_t *c, xcb_randr_output_t output, xcb_timestamp_t config_timestamp)

	xcb_randr_get_output_info_reply_t * xcb_randr_get_output_info_reply (xcb_connection_t *c, xcb_randr_get_output_info_cookie_t cookie, xcb_generic_error_t **e)


cdef enum:
	XCB_INTERN_ATOM = 16
	XCB_ATOM_NONE = 0
	XCB_CURRENT_TIME = 0L

CONN_ERROR_LIST = (
	"XCB_CONN_ERROR",
	"XCB_CONN_CLOSED_EXT_NOTSUPPORTED",
	"XCB_CONN_CLOSED_MEM_INSUFFICIENT",
	"XCB_CONN_CLOSED_REQ_LEN_EXCEED",
	"XCB_CONN_CLOSED_PARSE_ERR",
	"XCB_CONN_CLOSED_INVALID_SCREEN",
	"XCB_CONN_CLOSED_FDPASSING_FAILED"
)
