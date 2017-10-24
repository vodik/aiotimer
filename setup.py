import os
from setuptools import setup, find_packages
from setuptools.command.sdist import sdist as _sdist
from setuptools.extension import Extension
import sys


macros = [('CYTHON_TRACE', '1')]


try:
    from Cython.Distutils import build_ext
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False


class sdist(_sdist):
    def run(self):
        # Make sure the compiled Cython files in the distribution are up-to-date
        from Cython.Build import cythonize
        cythonize(["aiotimer/timerfd.pyx"])
        _sdist.run(self)


cmdclass = {}
long_description=open('README.rst', encoding='utf-8').read()


if USE_CYTHON:
    ext_modules = [
        Extension("aiotimer.timerfd", ["aiotimer/timerfd.pyx"],
                  libraries=["rt"], define_macros=macros),
    ]
    cmdclass['build_ext'] = build_ext
    cmdclass['sdist'] = sdist
else:
    ext_modules = [
        Extension("aiotimer.timerfd", ["aiotimer/timerfd.c"],
                  libraries=["rt"], define_macros=macros),
    ]


setup(
    name='aiotimer',
    version='0.1.0',
    author='Simon Gomizelj',
    author_email='simon@vodik.xyz',
    packages=find_packages(),
    license="Apache 2",
    url='https://github.com/vodik/aiotimer',
    description='High resoltion timer for asyncio',
    keywords=['asyncio', 'timer', 'timerfd'],
    long_description=long_description,
    cmdclass = cmdclass,
    ext_modules=ext_modules,
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ],
)
