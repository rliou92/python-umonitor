from screen import Screen
import logging
import json
# from save import Save

# setup = current state of monitors, their resolutions, positions, etc
# profile = loaded from configuration file

# PYTHONMALLOC=malloc valgrind --leak-check=full --show-leak-kinds=definite python umon2.py

logging.basicConfig(level=logging.WARNING)
screen = Screen()
setup_info = screen.get_setup_info()
# print(setup_info)

# conf = {"home": setup_info}
# print(json.dumps(conf))
# 
# with open("umon2.conf", "w") as config_file:
# 	json.dump(conf, config_file, indent=4)
