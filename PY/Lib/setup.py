from setuptools import setup, find_packages
import io

setup(
    name="autux",                # the name pip will use
    version="0.0.1",                         # start with 0.1.0, bump as you release
    description="Auto-User-Termux",       # one‑line summary
    author="AngrySatan666",
    author_email="666angrysatan+Autux@gmail.com",
    url="https://github.com/AngrySatan666/Autux",  # project homepage or repo
    packages=find_packages(),                # auto‑find all subpackages
    install_requires=[                       # your runtime dependencies
        "requests>=2.25.0",
    ],
    python_requires=">=3.6",                 # minimum Python version
    entry_points={                           # optional: create console scripts
        "console_scripts": [
            "autux=autux.cli:main",
        ],
    },
    classifiers=[                            # for PyPI metadata
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)