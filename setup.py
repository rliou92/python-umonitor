from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

extensions = [
	Extension(
		"screen_class",
		["screen_class.pyx"],
		libraries = ["X11", "xcb-randr", "xcb"]
	),
]

setup(
	name = "umonitor",
	packages = find_packages(),
	ext_modules = cythonize(extensions),

	zip_safe=False

)
