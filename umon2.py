from screen import Screen
import logging
# from save import Save_Class

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py

logging.basicConfig(level=logging.DEBUG)
screen_o = Screen()
setup_info = screen_o.update_screen()
print(setup_info)


#dir(screen_o)
