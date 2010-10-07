FFVideo
=======

Installation
------------

In Ubuntu you can install the above using the following commands::

    sudo aptitude install ffmpeg cython

    tar -xf FFVideo-0.0.9.tar.gz
    cd FFVideo-0.0.9
    python setup.py install

or::

    sudo aptitude install ffmpeg python-pip
    pip install ffvideo

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

