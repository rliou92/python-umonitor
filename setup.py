from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

extensions = [
	Extension(
		"*",
		["*.pyx"],
		libraries = ["xcb-randr", "xcb"]
	),
]

setup(
	name = "umon2",
	packages = find_packages(),
	ext_modules = cythonize(extensions),

	zip_safe=False

)
