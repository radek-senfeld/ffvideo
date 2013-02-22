ctypedef signed long long int64_t
ctypedef unsigned char uint8_t

cdef enum:
    SEEK_SET = 0
    SEEK_CUR = 1
    SEEK_END = 2

cdef extern from "libavutil/rational.h":
    struct AVRational:
        int num
        int den

    double av_q2d(AVRational  a)
    AVRational av_mul_q (AVRational b, AVRational c)
    AVRational av_div_q (AVRational b, AVRational c)

cdef extern from "libavutil/mathematics.h":
    int64_t av_rescale(int64_t a, int64_t b, int64_t c)
    int64_t av_rescale_q(int64_t a, AVRational bq, AVRational cq)

cdef extern from "libavutil/avutil.h":
    cdef enum PixelFormat:
        PIX_FMT_NONE= -1,
        PIX_FMT_YUV420P,   #< Planar YUV 4:2:0 (1 Cr & Cb sample per 2x2 Y samples)
        PIX_FMT_YUV422,    #< Packed pixel, Y0 Cb Y1 Cr
        PIX_FMT_RGB24,     #< Packed pixel, 3 bytes per pixel, RGBRGB...
        PIX_FMT_BGR24,     #< Packed pixel, 3 bytes per pixel, BGRBGR...
        PIX_FMT_YUV422P,   #< Planar YUV 4:2:2 (1 Cr & Cb sample per 2x1 Y samples)
        PIX_FMT_YUV444P,   #< Planar YUV 4:4:4 (1 Cr & Cb sample per 1x1 Y samples)
        PIX_FMT_RGBA32,    #< Packed pixel, 4 bytes per pixel, BGRABGRA..., stored in cpu endianness
        PIX_FMT_YUV410P,   #< Planar YUV 4:1:0 (1 Cr & Cb sample per 4x4 Y samples)
        PIX_FMT_YUV411P,   #< Planar YUV 4:1:1 (1 Cr & Cb sample per 4x1 Y samples)
        PIX_FMT_RGB565,    #< always stored in cpu endianness
        PIX_FMT_RGB555,    #< always stored in cpu endianness, most significant bit to 1
        PIX_FMT_GRAY8,
        PIX_FMT_MONOWHITE, #< 0 is white
        PIX_FMT_MONOBLACK, #< 0 is black
        PIX_FMT_PAL8,      #< 8 bit with RGBA palette
        PIX_FMT_YUVJ420P,  #< Planar YUV 4:2:0 full scale (jpeg)
        PIX_FMT_YUVJ422P,  #< Planar YUV 4:2:2 full scale (jpeg)
        PIX_FMT_YUVJ444P,  #< Planar YUV 4:4:4 full scale (jpeg)
        PIX_FMT_XVMC_MPEG2_MC,#< XVideo Motion Acceleration via common packet passing(xvmc_render.h)
        PIX_FMT_XVMC_MPEG2_IDCT,
        PIX_FMT_UYVY422,   #< Packed pixel, Cb Y0 Cr Y1
        PIX_FMT_UYVY411,   #< Packed pixel, Cb Y0 Y1 Cr Y2 Y3
        PIX_FMT_NB,

    struct AVDictionaryEntry:
        char *key
        char *value

    struct AVDictionary:
        int count
        AVDictionaryEntry *elems

    void av_free(void *) nogil
    void av_freep(void *) nogil

cdef extern from "libavutil/log.h":
    int AV_LOG_VERBOSE
    int AV_LOG_ERROR
    void av_log_set_level(int)

cdef extern from "libavcodec/avcodec.h":
    # use an unamed enum for defines
    cdef enum:
        AVSEEK_FLAG_BACKWARD = 1 #< seek backward
        AVSEEK_FLAG_BYTE     = 2 #< seeking based on position in bytes
        AVSEEK_FLAG_ANY      = 4 #< seek to any frame, even non keyframes
        CODEC_CAP_TRUNCATED = 0x0008
        CODEC_FLAG_TRUNCATED = 0x00010000 # input bitstream might be truncated at a random location instead of only at frame boundaries
        AV_TIME_BASE = 1000000
        FF_I_TYPE = 1 # Intra
        FF_P_TYPE = 2 # Predicted
        FF_B_TYPE = 3 # Bi-dir predicted
        FF_S_TYPE = 4 # S(GMC)-VOP MPEG4
        FF_SI_TYPE = 5
        FF_SP_TYPE = 6

    cdef int CODEC_FLAG_GRAY
    cdef AVRational AV_TIME_BASE_Q
    cdef int64_t AV_NOPTS_VALUE

    enum AVDiscard:
        # we leave some space between them for extensions (drop some keyframes for intra only or drop just some bidir frames)
        AVDISCARD_NONE   = -16 # discard nothing
        AVDISCARD_DEFAULT=   0 # discard useless packets like 0 size packets in avi
        AVDISCARD_NONREF =   8 # discard all non reference
        AVDISCARD_BIDIR  =  16 # discard all bidirectional frames
        AVDISCARD_NONKEY =  32 # discard all frames except keyframes
        AVDISCARD_ALL    =  48 # discard all

    enum AVMediaType:
        AVMEDIA_TYPE_UNKNOWN = -1
        AVMEDIA_TYPE_VIDEO = 0
        AVMEDIA_TYPE_AUDIO = 1
        AVMEDIA_TYPE_DATA = 2
        AVMEDIA_TYPE_SUBTITLE = 3
        AVMEDIA_TYPE_ATTACHMENT = 4
        AVMEDIA_TYPE_NB = 5

    struct AVCodecContext:
        int max_b_frames
        int codec_type
        int codec_id
        int flags
        int width
        int height
        int pix_fmt
        int frame_number
        int hurry_up
        int skip_idct
        int skip_frame
        AVRational time_base

    struct AVCodec:
        char *name
        int type
        int id
        int priv_data_size
        int capabilities
        AVCodec *next
        AVRational *supported_framerates #array of supported framerates, or NULL if any, array is terminated by {0,0}
        int *pix_fmts       #array of supported pixel formats, or NULL if unknown, array is terminanted by -1

    struct AVPacket:
        int64_t pts                            #< presentation time stamp in time_base units
        int64_t dts                            #< decompression time stamp in time_base units
        char *data
        int   size
        int   stream_index
        int   flags
        int   duration                      #< presentation duration in time_base units (0 if not available)
        void  *priv
        int64_t pos                            #< byte position in stream, -1 if unknown

    struct AVFrame:
        uint8_t *data[4]
        int linesize[4]
        int64_t pts
        int coded_picture_number
        int display_picture_number
        int pict_type
        int key_frame
        int repeat_pict

    struct AVPicture:
        uint8_t *data[4]
        int linesize[4]

    AVCodec *avcodec_find_decoder(int id)
    int avcodec_open2(AVCodecContext *avctx, AVCodec *codec, AVDictionary **options)
    int avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr, AVPacket *avpkt) nogil
    int avpicture_fill(AVPicture *picture, void *ptr, int pix_fmt, int width, int height) nogil
    AVFrame *avcodec_alloc_frame()
    int avpicture_get_size(int pix_fmt, int width, int height)
    int avpicture_layout(AVPicture* src, int pix_fmt, int width, int height,
                     unsigned char *dest, int dest_size)
#    int img_convert(AVPicture *dst, int dst_pix_fmt,
#                AVPicture *src, int pix_fmt,
#                int width, int height)

    void avcodec_flush_buffers(AVCodecContext *avctx)
    int avcodec_close (AVCodecContext *avctx)

cdef extern from "libavformat/avformat.h":
    struct AVFrac:
        int64_t val, num, den

    void av_register_all()

    struct AVCodecParserContext:
        pass

    struct AVIndexEntry:
        pass

    struct AVStream:
        int index    #/* stream index in AVFormatContext */
        int id       #/* format specific stream id */
        AVCodecContext *codec #/* codec context */
        # real base frame rate of the stream.
        # for example if the timebase is 1/90000 and all frames have either
        # approximately 3600 or 1800 timer ticks then r_frame_rate will be 50/1
        AVRational r_frame_rate
        void *priv_data
        # internal data used in avformat_find_stream_info()
        int64_t codec_info_duration
        int codec_info_nb_frames
        # encoding: PTS generation when outputing stream
        AVFrac pts
        # this is the fundamental unit of time (in seconds) in terms
        # of which frame timestamps are represented. for fixed-fps content,
        # timebase should be 1/framerate and timestamp increments should be
        # identically 1.
        AVRational time_base
        int pts_wrap_bits # number of bits in pts (used for wrapping control)
        # ffmpeg.c private use
        int stream_copy   # if TRUE, just copy stream
        int discard       # < selects which packets can be discarded at will and dont need to be demuxed
        # FIXME move stuff to a flags field?
        # quality, as it has been removed from AVCodecContext and put in AVVideoFrame
        # MN:dunno if thats the right place, for it
        float quality
        # decoding: position of the first frame of the component, in
        # AV_TIME_BASE fractional seconds.
        int64_t start_time
        # decoding: duration of the stream, in AV_TIME_BASE fractional
        # seconds.
        int64_t duration
        char language[4] # ISO 639 3-letter language code (empty string if undefined)
        # av_read_frame() support
        int need_parsing                  # < 1->full parsing needed, 2->only parse headers dont repack
        AVCodecParserContext *parser
        int64_t cur_dts
        int last_IP_duration
        int64_t last_IP_pts
        # av_seek_frame() support
        AVIndexEntry *index_entries # only used if the format does not support seeking natively
        int nb_index_entries
        int index_entries_allocated_size
        int64_t nb_frames                 # < number of frames in this stream if known or 0

    struct ByteIOContext:
        pass

    struct AVInputFormat:
        pass

    struct AVFormatContext:
        int nb_streams
        AVStream **streams
        int64_t timestamp
        int64_t start_time
        AVStream *cur_st
        AVPacket cur_pkt
        ByteIOContext pb
        # decoding: total file size. 0 if unknown
        int64_t file_size
        int64_t duration
        # decoding: total stream bitrate in bit/s, 0 if not
        # available. Never set it directly if the file_size and the
        # duration are known as ffmpeg can compute it automatically. */
        int bit_rate
        # av_seek_frame() support
        int64_t data_offset    # offset of the first packet
        int index_built
        int flags

    int avformat_open_input(AVFormatContext **ic_ptr, char *filename,
                       AVInputFormat *fmt,
                       AVDictionary **options)
    int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options)

    void av_dump_format(AVFormatContext *ic,
                 int index,
                 char *url,
                 int is_output)
    void av_free_packet(AVPacket *pkt)
    int av_read_packet(AVFormatContext *s, AVPacket *pkt) nogil
    int av_read_frame(AVFormatContext *s, AVPacket *pkt) nogil
    int av_seek_frame(AVFormatContext *s, int stream_index, int64_t timestamp, int flags) nogil
    int av_seek_frame_binary(AVFormatContext *s, int stream_index, int64_t target_ts, int flags) nogil

    void av_parser_close(AVCodecParserContext *s)

    int av_index_search_timestamp(AVStream *st, int64_t timestamp, int flags)
    void avformat_close_input(AVFormatContext **s)

cdef extern from "libavformat/avio.h":
    int url_ferror(ByteIOContext *s)
    int url_feof(ByteIOContext *s)

cdef extern from "libswscale/swscale.h":
    int SWS_FAST_BILINEAR
    int SWS_BILINEAR
    int SWS_BICUBIC

    struct SwsVector:
        double *coeff
        int length

    struct SwsFilter:
        SwsVector *lumH
        SwsVector *lumV
        SwsVector *chrH
        SwsVector *chrV

    struct SwsContext:
        pass

    void sws_freeContext(SwsContext *swsContext) nogil

    SwsContext *sws_getContext(int srcW, int srcH, int srcFormat, int dstW, int dstH, int dstFormat, int flags,
                    SwsFilter *srcFilter, SwsFilter *dstFilter, double *param) nogil

    int sws_scale(SwsContext *context, uint8_t* src[], int srcStride[], int srcSliceY,
                    int srcSliceH, uint8_t* dst[], int dstStride[]) nogil
