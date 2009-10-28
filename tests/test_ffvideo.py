import os

v0 = 'tests/data/0.flv'
v3 = 'tests/data/ve3.flv'

def test_import():
    try:
        import ffvideo
    except ImportError:
        raise AssertionError, "can't import pyffmpeg module"

def test_open():
    from ffvideo import VideoStream, DecoderError, FAST_BILINEAR, BILINEAR
    try:
        VideoStream('non-existing-file')
    except IOError:
        pass
    else:
        raise AssertionError, "expected IOError"

    try:
        VideoStream('tests/test_ffvideo.py')
    except DecoderError:
        pass
    else:
        raise AssertionError, "expected DecodeError"


    VideoStream(v0)
    VideoStream(v0, frame_size=(128, 128), frame_mode='L')
    VideoStream(v0, frame_size=(None, 128), frame_mode='L')
    VideoStream(v0, frame_size=(None, 128), frame_mode='L', scale_mode=BILINEAR)
    VideoStream(v0, scale_mode=FAST_BILINEAR, frame_size=(None, 128))

    try:
        VideoStream(v0, frame_size=(None, 128, 33), frame_mode='L')
    except ValueError:
        pass
    else:
        raise AssertionErrror, "expected ValueError"

    try:
        VideoStream(v0, frame_size=344, frame_mode='L')
    except ValueError:
        pass
    else:
        raise AssertionErrror, "expected ValueError"

def test_videoinfo():
    from ffvideo import VideoStream

    vs = VideoStream(v0)
    assert vs.duration == 15.987
    assert vs.width == vs.frame_width
    assert vs.height == vs.frame_height
    assert vs.width == 320
    assert vs.height == 240
    assert vs.codec_name == 'flv'
    assert vs.frame_mode == 'RGB'

    vs = VideoStream(v0, frame_size=(128, 128), frame_mode='L')
    assert vs.width != vs.frame_width
    assert vs.frame_width == 128
    assert vs.frame_height == 128
    assert vs.frame_mode == 'L'

    vs = VideoStream(v0, frame_size=(129, None), frame_mode='L')
#    raise AssertionError, "(%d, %d)" % (vs.frame_width, vs.frame_height)
    assert vs.width != vs.frame_width
    assert vs.height != vs.frame_height
    assert vs.frame_height == 97


def test_frames_getting():
    from ffvideo import VideoStream

    vs = VideoStream(v0)

    f1 = vs.current() # first frame
    f2 = vs.next()
    assert f2.timestamp > f1.timestamp

    f = vs[0] # first frame
    assert f.frameno == 0
    f = vs.get_frame_no(100)
#    f = vs[100]
#    assert f.frameno == 100

    f = vs.get_frame_no(100)
    f = vs.get_frame_at_sec(1)
    assert f.timestamp - 1 < 0.1
    f = vs.get_frame_at_pts(133000)

    assert f.width == vs.frame_width
    assert f.height == vs.frame_height
    assert f.mode == vs.frame_mode

def test_frames_iterator():
    from ffvideo import VideoStream
    vs = VideoStream(v0)
    frame_iter = iter(vs)
    frame = frame_iter.next()
    assert frame.timestamp == 0

