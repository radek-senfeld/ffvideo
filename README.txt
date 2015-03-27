FFVideo - Python FFmpeg extension
=================================

Based on https://bitbucket.org/zakhar/ffvideo/

Installation
------------

In CentOS you can install the above using the following commands::

    sudo rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm
    sudo yum install -y ffmpeg-devel libjpeg-turbo-devel

    pip install Cython Pillow numpy
    pip install git+https://github.com/radek-senfeld/ffvideo.git#egg=ffvideo

In Ubuntu you can install the above using the following commands::

    sudo aptitude install python-dev cython libavcodec-dev libavformat-dev libswscale-dev

    pip install git+https://github.com/radek-senfeld/ffvideo.git#egg=ffvideo

How to use
----------

Getting thumnails or videostream info
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
::

    from ffvideo import VideoStream

    def print_info(vs):
        print '-' * 20
        print "codec: %s" % vs.codec_name
        print "duration: %.2f" % vs.duration
        print "bit rate: %d" % vs.bitrate
        print "frame size: %dx%d" % (vs.frame_width, vs.frame_height)
        print "frame_mode: %s" % vs.frame_mode


    vs = VideoStream('0.flv')
    print_info(vs)

    vs = VideoStream('0.flv',
                     frame_size=(128, None), # scale to width 128px
                     frame_mode='L') # convert to grayscale
    print_info(vs)

    frame = vs.get_frame_at_sec(2)
    print frame.size

    # PIL image, required installed PIL
    frame.image().save('frame2sec.jpeg')

    # numpy.ndarray, required installed numpy
    print frame.ndarray().shape

Iterating over frame sequence
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
::

    from ffvideo import VideoStream

    for frame in VideoStream('0.flv'):
        print frame.timestamp
