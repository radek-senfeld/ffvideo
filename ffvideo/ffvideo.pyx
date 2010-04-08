# ffvideo.pyx
#
# Copyright (C) 2009 Zakhar Zibarov <zakhar.zibarov@gmail.com>
# Copyright (C) 2006-2007 James Evans <jaevans@users.sf.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

from ffmpeg cimport *

cdef extern from "Python.h":
    object PyBuffer_New(int)
    object PyBuffer_FromObject(object, int, int)
    int PyObject_AsCharBuffer(object, char **, Py_ssize_t *) except -1

av_register_all()
av_log_set_level(AV_LOG_ERROR);

class FFVideoError(Exception):
    pass

class DecoderError(FFVideoError):
    pass

class FFVideoValueError(FFVideoError, ValueError):
    pass

class NoMoreData(StopIteration):
    pass
    
FAST_BILINEAR = SWS_FAST_BILINEAR
BILINEAR = SWS_BILINEAR
BICUBIC = SWS_BICUBIC


FRAME_MODES = {
    'RGB': PIX_FMT_RGB24,
    'L': PIX_FMT_GRAY8,
    'YUV420P': PIX_FMT_YUV420P
}

cdef class VideoStream:
    """Class represents video stream"""
    
    cdef AVFormatContext *format_ctx
    cdef AVCodecContext *codec_ctx
    cdef AVCodec *codec
    cdef AVPacket packet

    cdef int streamno
    cdef AVStream *stream
    
    cdef int frameno
    cdef AVFrame *frame
    cdef int64_t _frame_pts
    
    cdef int ffmpeg_frame_mode
    cdef object __frame_mode

    # public
    cdef readonly object filename
    cdef readonly object codec_name

    cdef readonly double framerate
    cdef readonly double duration
    cdef readonly int width
    cdef readonly int height

    cdef readonly int frame_width
    cdef readonly int frame_height

    cdef public int scale_mode

    property frame_mode:
        def __set__(self, mode):
            if mode not in FRAME_MODES:
                raise FFVideoValueError("Not supported frame mode")
            self.__frame_mode = mode
            self.ffmpeg_frame_mode = FRAME_MODES[mode]

        def __get__(self):
            return self.__frame_mode

    property frame_size:
        def __set__(self, size):
            try:
                fw, fh = size
            except (TypeError, ValueError), e:
                raise FFVideoValueError("frame_size must be a tuple (int, int)")
            if fw is None and fh is None:
                raise FFVideoValueError("both width and height cannot be None")

            if fw is None:
                self.frame_width = round(fh * <float>self.width / self.height / 2.0) * 2
                self.frame_height = round(fh / 2.0) * 2
            elif fh is None:
                self.frame_width = round(fw / 2.0) * 2
                self.frame_height = round(fw * <float>self.height / self.width / 2.0) * 2
            else:
                self.frame_width = round(fw / 2.0) * 2
                self.frame_height = round(fh / 2.0) * 2

        def __get__(self):
            return (self.frame_width, self.frame_height)

    def __cinit__(self, filename, frame_size=None, frame_mode='RGB', 
                  scale_mode=BICUBIC):
        self.format_ctx = NULL
        self.codec_ctx = NULL
        self.frame = avcodec_alloc_frame()
        self.duration = 0
        self.width = 0
        self.height = 0
        self.frameno = 0
        self.streamno = -1

    def __init__(self, filename, frame_size=None, frame_mode='RGB', 
                 scale_mode=BICUBIC):
        cdef int ret
        cdef int i

        self.filename = filename

        self.frame_mode = frame_mode
        self.scale_mode = scale_mode

        ret = av_open_input_file(&self.format_ctx, filename, NULL, 0, NULL)
        if ret != 0:
            raise DecoderError("Unable to open file %s" % filename)

        ret = av_find_stream_info(self.format_ctx)
        if ret < 0:
            raise DecoderError("Unable to find stream info: %d" % ret)

        for i in xrange(self.format_ctx.nb_streams):
            if self.format_ctx.streams[i].codec.codec_type == CODEC_TYPE_VIDEO:
                self.streamno = i
                break
        else:
            raise DecoderError("Unable to find video stream")

        self.stream = self.format_ctx.streams[self.streamno]
        self.framerate = av_q2d(self.stream.r_frame_rate)

        if self.stream.duration == 0 or self.stream.duration == AV_NOPTS_VALUE:
            self.duration = self.format_ctx.duration / <double>AV_TIME_BASE
        else:
            self.duration = self.stream.duration * av_q2d(self.stream.time_base)

        self.codec_ctx = self.stream.codec
        self.codec = avcodec_find_decoder(self.codec_ctx.codec_id)

        if self.codec == NULL:
            raise DecoderError("Unable to get decoder")

        # Inform the codec that we can handle truncated bitstreams -- i.e.,
        # bitstreams where frame boundaries can fall in the middle of packets
        if self.codec.capabilities & CODEC_CAP_TRUNCATED:
            self.codec_ctx.flags |= CODEC_FLAG_TRUNCATED

        if self.frame_mode in ('L', 'F'):
            self.codec_ctx.flags |= CODEC_FLAG_GRAY

        self.width = self.codec_ctx.width
        self.height = self.codec_ctx.height

        # Open codec
        ret = avcodec_open(self.codec_ctx, self.codec)
        if ret < 0:
            raise DecoderError("Unable to open codec")

        # for some videos, avcodec_open will set these to 0,
        # so we'll only be using it if it is not 0, otherwise,
        # we rely on the resolution provided by the header;
        if self.codec_ctx.width != 0 and self.codec_ctx.height !=0:
            self.width = self.codec_ctx.width
            self.height = self.codec_ctx.height

        if self.width <= 0 or self.height <= 0:
            raise DecoderError("Video width/height is 0; cannot decode")

        if frame_size is None:
            self.frame_size = (self.width, self.height)
        else:
            self.frame_size = frame_size

        self.codec_name = self.codec.name

        self.__decode_next_frame()

    def __dealloc__(self):
        if self.packet.data:
            av_free_packet(&self.packet)
        
        av_free(self.frame)
        if self.codec:
            avcodec_close(self.codec_ctx)
            self.codec_ctx = NULL
        if self.format_ctx:
            av_close_input_file(self.format_ctx)
            self.format_ctx = NULL

    def dump(self):
        print "max_b_frames=%s" % self.codec_ctx.max_b_frames
        av_log_set_level(AV_LOG_VERBOSE);
        dump_format(self.format_ctx, 0, self.filename, 0);
        av_log_set_level(AV_LOG_ERROR);

    def __decode_next_frame(self):
        cdef int ret
        cdef int frame_finished = 0
        cdef int64_t pts

        while frame_finished == 0:
            self.packet.stream_index = -1
            while self.packet.stream_index != self.streamno:
                if self.packet.data:
                    av_free_packet(&self.packet) # free data owned by unused stream

                ret = av_read_frame(self.format_ctx, &self.packet)
                if ret < 0:
                    # ??????????
                    av_free_packet(&self.packet)
                    raise NoMoreData("Unable to read frame [%d]" % ret)

#            print "packet>> pts=%d dts=%d stream_index=%d duration=%d size=%d, flags=0x%08X" % \
#                (self.packet.pts, self.packet.dts, self.packet.stream_index,
#                 self.packet.duration, self.packet.size, self.packet.flags) 
            with nogil:
                ret = avcodec_decode_video(self.codec_ctx, self.frame, 
                                           &frame_finished, 
                                           self.packet.data, self.packet.size)
            if ret < 0:
                # ???????? 
                if self.packet.data:
                    av_free_packet(&self.packet)
                raise IOError("Unable to decode video picture: %d" % ret)
#            print "= frame_finished=%d size=%d ret=%d" % (frame_finished, self.packet.size, ret)
        
        if self.packet.pts == AV_NOPTS_VALUE:
            pts = self.packet.dts
        else:
            pts = self.packet.pts

#        print "frame>> pict_type=%s" % "*IPBSip"[self.frame.pict_type],
#        print "pts=%s, dts=%s, frameno=%s" % (pts, self.packet.dts, self.frameno),
#        print "ts=%.3f" % av_q2d(av_mul_q(AVRational(pts-self.stream.start_time, 1), self.stream.time_base))
        
        # TODO: fix memory leaks
        if self.packet.data:
            av_free_packet(&self.packet)
            
        self.frame.pts = av_rescale_q(pts-self.stream.start_time, 
                                      self.stream.time_base, AV_TIME_BASE_Q)
        self.frame.display_picture_number = <int>av_q2d(
            av_mul_q(av_mul_q(AVRational(pts - self.stream.start_time, 1), 
                              self.stream.r_frame_rate),
                     self.stream.time_base)
        )
        return self.frame.pts
 
    def dump_next_frame(self):
        pts = self.__decode_next_frame()
        print "pts=%d, frameno=%d" % (pts, self.frameno)
        print "f.pts=%s, " % (self.frame.pts,)
        print "codec_ctx.frame_number=%s" % self.codec_ctx.frame_number
        print "f.coded_picture_number=%s, f.display_picture_number=%s" % \
              (self.frame.coded_picture_number, self.frame.display_picture_number)
 
    def current(self):
        cdef AVFrame *scaled_frame
        cdef Py_ssize_t buflen
        cdef char *data_ptr
        cdef SwsContext *img_convert_ctx
        
        scaled_frame = avcodec_alloc_frame()
        if scaled_frame == NULL:
            raise MemoryError("Unable to allocate new frame")
        
        buflen = avpicture_get_size(self.ffmpeg_frame_mode, 
                                    self.frame_width, self.frame_height)
        data = PyBuffer_New(buflen)
        PyObject_AsCharBuffer(data, &data_ptr, &buflen)
        
        with nogil:
            avpicture_fill(<AVPicture *>scaled_frame, <uint8_t *>data_ptr, 
                       self.ffmpeg_frame_mode, self.frame_width, self.frame_height)
        
            img_convert_ctx = sws_getContext(
                self.width, self.height, self.codec_ctx.pix_fmt,
                self.frame_width, self.frame_height, self.ffmpeg_frame_mode,
                self.scale_mode, NULL, NULL, NULL) 
        
            sws_scale(img_convert_ctx,
                self.frame.data, self.frame.linesize, 0, self.height,
                scaled_frame.data, scaled_frame.linesize)
        
            sws_freeContext(img_convert_ctx)
            av_free(scaled_frame)
            
        return VideoFrame(data, self.frame_size, self.frame_mode, 
                          timestamp=<double>self.frame.pts/<double>AV_TIME_BASE, 
                          frameno=self.frame.display_picture_number)
    
    def get_frame_no(self, frameno):
        cdef int64_t gpts = av_rescale(frameno, 
                                      self.stream.r_frame_rate.den*AV_TIME_BASE, 
                                      self.stream.r_frame_rate.num)
        return self.get_frame_at_pts(gpts)
    
    def get_frame_at_sec(self, float timestamp):
        return self.get_frame_at_pts(<int64_t>(timestamp * AV_TIME_BASE))
    
    def get_frame_at_pts(self, int64_t pts):
        cdef int ret
        cdef int64_t stream_pts
        
        stream_pts = av_rescale_q(pts, AV_TIME_BASE_Q, self.stream.time_base) + \
                    self.stream.start_time
        ret = av_seek_frame(self.format_ctx, self.streamno, stream_pts, 
                            AVSEEK_FLAG_BACKWARD)
        if ret < 0:
            raise FFVideoError("Unable to seek: %d" % ret)
        avcodec_flush_buffers(self.codec_ctx)
        
        # if we hurry it we can get bad frames later in the GOP
        self.codec_ctx.skip_idct = AVDISCARD_BIDIR
        self.codec_ctx.skip_frame = AVDISCARD_BIDIR
        
        #self.codec_ctx.hurry_up = 1
        hurried_frames = 0
        while self.__decode_next_frame() < pts:
            pass

        #self.codec_ctx.hurry_up = 0

        self.codec_ctx.skip_idct = AVDISCARD_DEFAULT
        self.codec_ctx.skip_frame = AVDISCARD_DEFAULT

        return self.current()
    
    def __iter__(self):
        # rewind
        ret = av_seek_frame(self.format_ctx, self.streamno, 
                            self.stream.start_time, AVSEEK_FLAG_BACKWARD)
        if ret < 0:
            raise FFVideoError("Unable to rewind: %d" % ret)
        avcodec_flush_buffers(self.codec_ctx)
        return self

    def __next__(self):
        self.__decode_next_frame()
        return self.current()

    def __getitem__(self, frameno):
        return self.get_frame_no(frameno)

    def __repr__(self):
        return "<VideoStream '%s':%.4f>" % (self.filename, <double>self.frame.pts/<double>AV_TIME_BASE)


cdef class VideoFrame:
    cdef readonly int width
    cdef readonly int height
    cdef readonly object size
    cdef readonly object mode

    cdef readonly int frameno
    cdef readonly double timestamp

    cdef readonly object data

    def __init__(self, data, size, mode, timestamp=0, frameno=0):
        self.data = data
        self.width, self.height = size
        self.size = size
        self.mode = mode
        self.timestamp = timestamp
        self.frameno = frameno

    def image(self):
        if self.mode not in ('RGB', 'L', 'F'):
            raise FFVideoError('Cannot represent this color mode into PIL Image')

        try:
            import Image
        except ImportError:
            from PIL import Image
        return Image.frombuffer(self.mode, self.size, self.data, 'raw', self.mode, 0, 1)

    def ndarray(self):
        if self.mode not in ('RGB', 'L'):
            raise FFVideoError('Cannot represent this color mode into PIL Image')

        import numpy
        if self.mode == 'RGB':
            shape = (self.height, self.width, 3)
        elif self.mode == 'L':
            shape = (self.height, self.width)
        return numpy.ndarray(buffer=self.data, dtype=numpy.uint8, shape=shape)



