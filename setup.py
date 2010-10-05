from distutils.core import setup, Extension
from Cython.Distutils import build_ext

setup(
    name="FFVideo",
    version="0.0.7",
    description="FFVideo is a python extension makes possible to access to decoded frames at two format: PIL.Image or numpy.ndarray.",

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

