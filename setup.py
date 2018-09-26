from setuptools import setup, find_packages
from Cython.Build import cythonize

setup(
	name = "umonitor",
	packages = find_packages(),
	ext_modules = cythonize("screen_change_listener.pyx")


)
