from screen import Screen
import logging
# from save import Save_Class

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

logging.basicConfig(level=logging.DEBUG)
screen_o = Screen_Class()
setup_info = screen_o.update_screen()
print(conf_info)


#dir(screen_o)
