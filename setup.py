try:
    from setuptools import setup, Extension
except ImportError:
    import sys
    print "Please, install setuptools (http://peak.telecommunity.com/DevCenter/EasyInstall#id4)"
    sys.exit(1)
from Cython.Distutils import build_ext

setup(
    name = "FFVideo",
    ext_modules=[
        Extension("ffvideo", ["ffvideo/ffvideo.pyx"],
        include_dirs=["/usr/include/ffmpeg"], 
        libraries = ["avformat","avcodec", "swscale"])
    ],
    cmdclass = {'build_ext': build_ext},
    version = "0.0.1",
    test_suite='nose.collector',
    tests_require=['nose'],
    maintainer = "Zakhar Zibarov",
    author_email = "zakhar.zibarov@gmail.com",
    url = "http://bitbucket.org/zakhar/ffvideo/",
)
