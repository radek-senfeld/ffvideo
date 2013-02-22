import os
from distutils.core import setup, Extension

try:
    from Cython.Distutils import build_ext
    sources = ["ffvideo/ffvideo.pyx"]
    cmdclass = {'build_ext': build_ext}
except ImportError:
    sources = ["ffvideo/ffvideo.c"]
    cmdclass = {}

def read(fn):
    return open(os.path.join(os.path.dirname(__file__), fn)).read()

VERSION = "0.0.11"

setup(
    name="FFVideo",
    version=VERSION,
    description="FFVideo is a python extension makes possible to access to decoded frames at two format: PIL.Image or numpy.ndarray.",
    long_description=read("README.txt"),
    ext_modules=[
        Extension("ffvideo", sources,
                  include_dirs=["/usr/include/ffmpeg"],
                  libraries=["avformat", "avcodec", "swscale"])
    ],
    cmdclass=cmdclass,
    author="Zakhar Zibarov",
    author_email="zakhar.zibarov@gmail.com",
    url="http://bitbucket.org/zakhar/ffvideo/",
)

