from libc.stdint cimport *

cdef extern from "<xcb/xcb.h>":

	cdef struct xcb_connection_t:
		# Opaque structure containing all data that  XCB needs to communicate with an X server.
		pass

	ctypedef uint32_t xcb_window_t
	ctypedef struct xcb_screen_t:
		xcb_window_t root
		uint16_t       width_in_pixels
		uint16_t       height_in_pixels
		uint16_t       width_in_millimeters
		uint16_t       height_in_millimeters


	ctypedef uint32_t xcb_atom_t
	ctypedef struct xcb_intern_atom_reply_t:
		xcb_atom_t atom

	cdef struct xcb_setup_t:
		pass

	ctypedef struct xcb_screen_iterator_t:
		xcb_screen_t *data

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
	ctypedef uint32_t xcb_randr_mode_t

	ctypedef struct xcb_randr_get_screen_resources_cookie_t:
		pass

	ctypedef struct xcb_randr_get_screen_resources_reply_t:
		xcb_timestamp_t config_timestamp


	ctypedef struct xcb_randr_get_output_primary_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_primary_reply_t:
		xcb_randr_output_t output


	ctypedef struct xcb_randr_get_crtc_info_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_info_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_info_reply_t:
		xcb_randr_crtc_t crtc
		uint16_t num_crtcs
		uint16_t num_modes
		uint8_t connection

	ctypedef struct xcb_randr_get_output_property_cookie_t:
		pass

	ctypedef struct xcb_randr_get_output_property_reply_t:
		pass

	ctypedef struct xcb_randr_get_crtc_info_cookie_t:
		pass

	ctypedef struct xcb_randr_get_crtc_info_reply_t:
		int16_t x
		int16_t y
		uint16_t num_outputs
		uint16_t num_possible_outputs
		uint16_t rotation
		xcb_randr_mode_t mode

	ctypedef struct xcb_randr_mode_info_iterator_t:
		xcb_randr_mode_info_t *data

	ctypedef struct xcb_randr_mode_info_t:
		uint32_t id
		uint16_t width
		uint16_t height

	xcb_randr_get_screen_resources_reply_t * xcb_randr_get_screen_resources_reply (
		xcb_connection_t                         *c,
		xcb_randr_get_screen_resources_cookie_t   cookie,
		xcb_generic_error_t                     **e)

	xcb_randr_get_screen_resources_cookie_t xcb_randr_get_screen_resources ( xcb_connection_t *c, xcb_window_t window)


	xcb_randr_get_output_primary_cookie_t xcb_randr_get_output_primary (xcb_connection_t *c, xcb_window_t window)

	xcb_randr_get_output_primary_reply_t * xcb_randr_get_output_primary_reply (xcb_connection_t *c, xcb_randr_get_output_primary_cookie_t cookie, xcb_generic_error_t **e)

	xcb_randr_get_crtc_info_cookie_t xcb_randr_get_crtc_info ( xcb_connection_t *c, xcb_randr_crtc_t  crtc, xcb_timestamp_t config_timestamp)

	xcb_randr_output_t * xcb_randr_get_screen_resources_outputs (const xcb_randr_get_screen_resources_reply_t *R)

	int xcb_randr_get_screen_resources_outputs_length (const xcb_randr_get_screen_resources_reply_t *R)

	xcb_randr_get_output_info_cookie_t xcb_randr_get_output_info (xcb_connection_t *c, xcb_randr_output_t output, xcb_timestamp_t config_timestamp)

	xcb_randr_get_output_info_reply_t * xcb_randr_get_output_info_reply (xcb_connection_t *c, xcb_randr_get_output_info_cookie_t cookie, xcb_generic_error_t **e)

	uint8_t * xcb_randr_get_output_info_name (const xcb_randr_get_output_info_reply_t *R)

	int xcb_randr_get_output_info_name_length (const xcb_randr_get_output_info_reply_t *R)

	xcb_randr_get_output_property_cookie_t xcb_randr_get_output_property (
		xcb_connection_t   *c,
		xcb_randr_output_t  output,
		xcb_atom_t          property,
		xcb_atom_t          type,
		uint32_t            long_offset,
		uint32_t            long_length,
		uint8_t             _delete,
		uint8_t             pending)

	xcb_randr_get_output_property_reply_t *xcb_randr_get_output_property_reply (
		xcb_connection_t                        *c,
		xcb_randr_get_output_property_cookie_t   cookie,
		xcb_generic_error_t                    **e)

	int xcb_randr_get_output_property_data_length (
		const xcb_randr_get_output_property_reply_t *R)

	uint8_t *xcb_randr_get_output_property_data (
		const xcb_randr_get_output_property_reply_t *R)

	xcb_randr_get_crtc_info_cookie_t xcb_randr_get_crtc_info (
		xcb_connection_t *c,
		xcb_randr_crtc_t  crtc,
		xcb_timestamp_t   config_timestamp)

	xcb_randr_get_crtc_info_reply_t * xcb_randr_get_crtc_info_reply (
		xcb_connection_t *c,
		xcb_randr_get_crtc_info_cookie_t cookie,
		xcb_generic_error_t **e)

	int xcb_randr_get_output_info_modes_length (const xcb_randr_get_output_info_reply_t *R)
	xcb_randr_mode_t * xcb_randr_get_output_info_modes (const xcb_randr_get_output_info_reply_t *R)
	xcb_randr_mode_info_iterator_t xcb_randr_get_screen_resources_modes_iterator (const xcb_randr_get_screen_resources_reply_t *R)
	int xcb_randr_get_screen_resources_modes_length (const xcb_randr_get_screen_resources_reply_t *R)
	void xcb_randr_mode_info_next (xcb_randr_mode_info_iterator_t *i)



cdef enum:
	XCB_INTERN_ATOM = 16
	XCB_ATOM_NONE = 0
	XCB_CURRENT_TIME = 0L
	AnyPropertyType = 0L

CONN_ERROR_LIST = (
	"XCB_CONN_ERROR",
	"XCB_CONN_CLOSED_EXT_NOTSUPPORTED",
	"XCB_CONN_CLOSED_MEM_INSUFFICIENT",
	"XCB_CONN_CLOSED_REQ_LEN_EXCEED",
	"XCB_CONN_CLOSED_PARSE_ERR",
	"XCB_CONN_CLOSED_INVALID_SCREEN",
	"XCB_CONN_CLOSED_FDPASSING_FAILED"
)
