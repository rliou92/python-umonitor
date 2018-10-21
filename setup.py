from setuptools import setup, find_packages
from setuptools.extension import Extension

extensions = [
	Extension(
		"screen",
		["umonitor/screen.c"],
		libraries = ["xcb-randr", "xcb"]
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

	entry_points={
		'console_scripts': [
			'umonitor = umonitor:main',
		]
	},

	zip_safe=False

)
