from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

extensions = [
	Extension(
		"screen",
		["screen.c"]
	),
]

setup(
	name = "umonitor",
	packages = find_packages(),
	ext_modules = extensions,
	license="MIT",
	version="20181018",
	author="Ricky Liou",
	author_email="rliou92@gmail.com",
	description="Manage monitor configuration automatically.",
	url="https://github.com/rliou92/python-umonitor",

	zip_safe=False

)
