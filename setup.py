import os
from distutils.core import setup, Extension
from Cython.Distutils import build_ext

def read(fn):
    return open(os.path.join(os.path.dirname(__file__), fn)).read()

VERSION = "0.0.7"

setup(
    name="FFVideo",
    version=VERSION,
    description="FFVideo is a python extension makes possible to access to decoded frames at two format: PIL.Image or numpy.ndarray.",
    long_description=read("README.txt"),

    ext_modules=[
        Extension("ffvideo", ["ffvideo/ffvideo.pyx"],
        include_dirs=["/usr/include/ffmpeg"],
        libraries=["avformat", "avcodec", "swscale"])
    ],
    cmdclass={'build_ext': build_ext},
#    test_suite='nose.collector',
#    tests_require=['nose'],
    author="Zakhar Zibarov",
    author_email="zakhar.zibarov@gmail.com",
    url="http://bitbucket.org/zakhar/ffvideo/",
)

