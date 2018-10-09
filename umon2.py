# from screen import Screen
from conf_manager import ConfManager
import logging

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py

logging.basicConfig(level=logging.DEBUG)
config_file = "umon2.conf"

conf_manager = ConfManager(config_file)
# conf_manager.save_profile("media")
# conf_manager.delete_profile("home")
# conf_manager.view_profiles()
conf_manager.load_profile("home")

# load = Load()
# load.load_profile(setup_info)
