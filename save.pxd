from xcb cimport *
from screen cimport Screen_Class

cdef class Save_Class:
	cdef Screen_Class screen_o
	cdef xcb_randr_output_t primary_output
# class umon_setting:
