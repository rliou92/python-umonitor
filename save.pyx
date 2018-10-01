import configparser

cdef class Save_Class:

	def __init__(self, screen_o):
		self.screen_o = screen_o
		config = configparser.ConfigParser()

	def _get_primary_output(self):
		cdef xcb_randr_get_output_primary_cookie_t output_primary_cookie = xcb_randr_get_output_primary(self.screen_o.c, self.screen_o.default_screen.root)
		cdef xcb_randr_get_output_primary_reply_t *output_primary_reply = xcb_randr_get_output_primary_reply(self.screen_o.c, output_primary_cookie, &self.screen_o.e)
		self.primary_output = output_primary_reply.output

	def _fetch_output_info(self):
		cdef xcb_randr_output_t *output_p = xcb_randr_get_screen_resources_outputs(self.screen_o.screen_resources_reply)

		outputs_length = xcb_randr_get_screen_resources_outputs_length(self.screen_o.screen_resources_reply)

		for i in range(outputs_length):
			pass
