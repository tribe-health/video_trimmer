import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/thumbnail_viewer.dart';
import 'package:video_trimmer/trim_editor_painter.dart';

VideoPlayerController videoPlayerController;

class TrimEditor extends StatefulWidget {
  final double viewerWidth;
  final double viewerHeight;
  final File videoFile;
  final double circleSize;
  final double circleSizeOnDrag;
  final Color circlePaintColor;
  final Color borderPaintColor;
  final Color scrubberPaintColor;
  final int thumbnailQuality;
  final bool showDuration;
  final TextStyle durationTextStyle;
  final Function(double startValue) onChangeStart;
  final Function(double endValue) onChangeEnd;
  final Function(bool isPlaying) onChangePlaybackState;

  /// Widget for displaying the video trimmer.
  ///
  /// This has frame wise preview of the video with a
  /// slider for selecting the part of the video to be
  /// trimmed.
  ///
  /// The required parameters are [viewerWidth], [viewerHeight]
  /// & [videoFile].
  ///
  /// * [viewerWidth] to define the total trimmer area width.
  ///
  ///
  /// * [viewerHeight] to define the total trimmer area height.
  ///
  ///
  /// * [videoFile] for passing the video file.
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [circleSize] for specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  /// By default it is set to `5.0`.
  ///
  ///
  /// * [circleSizeOnDrag] for specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`. By default it is set to `8.0`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  ///
  ///
  /// * [borderPaintColor] for specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  ///
  ///
  /// * [scrubberPaintColor] for specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  ///
  ///
  /// * [showDuration] for showing the start and the end point of the
  /// video on top of the trimmer area. By default it is set to `true`.
  ///
  ///
  /// * [durationTextStyle] is for providing a `TextStyle` to the
  /// duration text. By default it is set to
  /// `TextStyle(color: Colors.white)`
  ///
  ///
  /// * [onChangeStart] is a callback to the video start position.
  ///
  ///
  /// * [onChangeEnd] is a callback to the video end position.
  ///
  ///
  /// * [onChangePlaybackState] is a callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  TrimEditor({
    @required this.viewerWidth,
    @required this.viewerHeight,
    @required this.videoFile,
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.thumbnailQuality = 75,
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(
      color: Colors.white,
    ),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
  })  : assert(viewerWidth != null),
        assert(viewerHeight != null),
        assert(videoFile != null),
        assert(circleSize != null),
        assert(circleSizeOnDrag != null),
        assert(circlePaintColor != null),
        assert(borderPaintColor != null),
        assert(scrubberPaintColor != null),
        assert(thumbnailQuality != null),
        assert(showDuration != null),
        assert(durationTextStyle != null);

  @override
  _TrimEditorState createState() => _TrimEditorState();
}

class _TrimEditorState extends State<TrimEditor> {
  File _videoFile;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  bool _canUpdateStart = true;
  bool _isLeftDrag = true;

  Offset _startPos = Offset(0, 0);
  Offset _endPos = Offset(0, 0);
  Offset _currentPos = Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  int _numberOfThumbnails = 0;

  double _circleSize;

  ThumbnailViewer thumbnailWidget;

  Future<void> _initializeVideoController() async {
    if (_videoFile != null) {
      videoPlayerController.addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;

        if (isPlaying) {
          widget.onChangePlaybackState(isPlaying);
          setState(() {
            _currentPosition =
                videoPlayerController.value.position.inMilliseconds;
            print("CURRENT POS: $_currentPosition");

            if (_currentPosition > _videoEndPos.toInt()) {
              videoPlayerController.pause();
              widget.onChangePlaybackState(false);
            }

            if (_currentPosition <= _videoEndPos.toInt()) {
              _currentPos = Offset(
                (_currentPosition / _videoDuration) * _thumbnailViewerW,
                0,
              );
            }
          });
        }
      });

      videoPlayerController.setVolume(1.0);
      _videoDuration = videoPlayerController.value.duration.inMilliseconds;
      print(_videoFile.path);

      _videoEndPos = _videoDuration.toDouble();
      widget.onChangeEnd(_videoEndPos);

      final ThumbnailViewer _thumbnailWidget = ThumbnailViewer(
        videoFile: _videoFile,
        videoDuration: _videoDuration,
        thumbnailHeight: _thumbnailViewerH,
        numberOfThumbnails: _numberOfThumbnails,
        quality: widget.thumbnailQuality,
      );
      thumbnailWidget = _thumbnailWidget;
    }
  }

  void _setVideoStartPosition(DragUpdateDetails details) {
    setState(() {
      _startPos += details.delta;
      _startFraction = (_startPos.dx / _thumbnailViewerW);
      print("START PERCENT: $_startFraction");
      _videoStartPos = _videoDuration * _startFraction;
      widget.onChangeStart(_videoStartPos);
      videoPlayerController
          .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
    });
  }

  void _setVideoEndPosition(DragUpdateDetails details) {
    setState(() {
      _endPos += details.delta;
      _endFraction = _endPos.dx / _thumbnailViewerW;
      print("END PERCENT: $_endFraction");
      _videoEndPos = _videoDuration * _endFraction;
      widget.onChangeEnd(_videoEndPos);
      videoPlayerController
          .seekTo(Duration(milliseconds: _videoEndPos.toInt()));
    });
  }

  @override
  void initState() {
    super.initState();
    _circleSize = widget.circleSize;

    _videoFile = widget.videoFile;
    _thumbnailViewerH = widget.viewerHeight;

    _numberOfThumbnails = widget.viewerWidth ~/ _thumbnailViewerH;
    print('Number of thumbnails generated: $_numberOfThumbnails');
    _thumbnailViewerW = _numberOfThumbnails * _thumbnailViewerH;

    _endPos = Offset(_thumbnailViewerW, _thumbnailViewerH);
    _initializeVideoController();
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    widget.onChangePlaybackState(false);
    if (widget.videoFile != null) {
      videoPlayerController.setVolume(0.0);
      videoPlayerController.pause();
      widget.onChangePlaybackState(false);
      videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        print("START");
        print(details.localPosition);
        print((_startPos.dx - details.localPosition.dx).abs());
        print((_endPos.dx - details.localPosition.dx).abs());

        if (_endPos.dx >= _startPos.dx) {
          if ((_startPos.dx - details.localPosition.dx).abs() >
              (_endPos.dx - details.localPosition.dx).abs()) {
            setState(() {
              _canUpdateStart = false;
            });
          } else {
            setState(() {
              _canUpdateStart = true;
            });
          }
        } else {
          if (_startPos.dx > details.localPosition.dx) {
            _isLeftDrag = true;
          } else {
            _isLeftDrag = false;
          }
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        setState(() {
          _circleSize = widget.circleSize;
        });
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        print("UPDATE");
        print("START POINT: ${_startPos.dx + details.delta.dx}");
        print("END POINT: ${_endPos.dx + details.delta.dx}");

        _circleSize = widget.circleSizeOnDrag;

        if (_endPos.dx >= _startPos.dx) {
          _isLeftDrag = false;
          if (_canUpdateStart && _startPos.dx + details.delta.dx > 0) {
            _isLeftDrag = false; // To prevent from scrolling over
            _setVideoStartPosition(details);
          } else if (!_canUpdateStart &&
              _endPos.dx + details.delta.dx < _thumbnailViewerW) {
            _isLeftDrag = true; // To prevent from scrolling over
            _setVideoEndPosition(details);
          }
        } else {
          if (_isLeftDrag && _startPos.dx + details.delta.dx > 0) {
            _setVideoStartPosition(details);
          } else if (!_isLeftDrag &&
              _endPos.dx + details.delta.dx < _thumbnailViewerW) {
            _setVideoEndPosition(details);
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.showDuration
              ? Container(
                  width: _thumbnailViewerW,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                            Duration(milliseconds: _videoStartPos.toInt())
                                .toString()
                                .split('.')[0],
                            style: widget.durationTextStyle),
                        Text(
                          Duration(milliseconds: _videoEndPos.toInt())
                              .toString()
                              .split('.')[0],
                          style: widget.durationTextStyle,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          CustomPaint(
            foregroundPainter: TrimEditorPainter(
              startPos: _startPos,
              endPos: _endPos,
              currentPos: _currentPos,
              circleSize: _circleSize,
              circlePaintColor: widget.circlePaintColor,
              borderPaintColor: widget.borderPaintColor,
              scrubberPaintColor: widget.scrubberPaintColor,
            ),
            child: Container(
              color: Colors.grey[900],
              height: _thumbnailViewerH,
              width: _thumbnailViewerW,
              child: thumbnailWidget == null ? Column() : thumbnailWidget,
            ),
          ),
        ],
      ),
    );
  }
}
