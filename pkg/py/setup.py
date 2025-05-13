from setuptools import setup, find_packages

setup(
    name="autux",
    version="0.1",
    packages=find_packages(),
    install_requires=[],
    entry_points={
        'console_scripts': [
            'autux = autux.cli:main',
        ],
    },
)