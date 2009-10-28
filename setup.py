
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
    name="FFVideo",
    ext_modules=[
        Extension("ffvideo", ["ffvideo/ffvideo.pyx"],
        include_dirs=["/usr/include/ffmpeg"],
        libraries=["avformat", "avcodec", "swscale"])
    ],
    cmdclass={'build_ext': build_ext},
    version="0.0.5dev2",
#    test_suite='nose.collector',
#    tests_require=['nose'],
    maintainer="Zakhar Zibarov",
    author_email="zakhar.zibarov@gmail.com",
    url="http://bitbucket.org/zakhar/ffvideo/",
)
