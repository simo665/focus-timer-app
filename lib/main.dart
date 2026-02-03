import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // timer logic
  Timer? _timer;
  static const int defaultTime = 10;
  static const int defaultRestTime = 10;
  int _secondsRemaining = defaultTime;
  bool isPause = false;
  String pauseText = "Pause";
  
  // background colors
  Color _appBarColor = Color(0xffFFB3CB);
  Color _backgroundColor = Color(0xffDE648A);
  
  // Ringtone player
  final AudioPlayer _player = AudioPlayer();

  // function to change the background color based on the timer state
  void _changeColors(bool busy) {
    if (busy) {
      setState(() {
      _backgroundColor = Color(0xff9F47DE);
      _appBarColor = Color(0xffC795DE);
      });
    } else {
      _appBarColor = Color(0xffFFB3CB);
      _backgroundColor = Color(0xffDE648A);
    }
  }
  
  // play ringtone function
  void _playRingTone(String source) async {
    await _player.play(AssetSource(source));
  }

  // starting timer button logic
  void _startTimer(bool restTimer) {
    // cancel previous timer if it exists
    _timer?.cancel();
    setState(() {
      isPause = false;
    });

    // reset remaining seconds
    setState(() {
      if (!restTimer) {
        _secondsRemaining = defaultTime;
      } else {
        _secondsRemaining = defaultRestTime;
      }
    });

    // change background color
    if (restTimer) {
      _changeColors(false);
    } else {
      _changeColors(true);
    }

    // start new timer
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        setState(() {
          // check if timer is finished
          if (_secondsRemaining == 0) {
            // cancel timer
            timer.cancel();
            // change color
            _changeColors(false);
            // play ring tone for notification
            if (restTimer) {
              _playRingTone("sounds/cute_anime_ringtone.mp3");
            } else {
              _playRingTone("sounds/cute_alarm.mp3");
            }

            // wait x seconds before next time
            // start new timer for rest if not in rest already
            Future.delayed(const Duration(seconds: 10), () {
              if (!restTimer) {
                _startTimer(true);
              } else {
                _startTimer(false);
              }
            });
            return;
          } else {
            _secondsRemaining--;
          }
        });
      }
    );
  }

  void _pauseTimer() {
    if (isPause) {
      setState(() {
        isPause = false;
        pauseText = "Pause";

      });
    } else {
      setState(() {
        isPause = true;
        pauseText = "Resume";
        _timer?.cancel();
      });
    }
    setState(() {
      _changeColors(false);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      isPause = true;
      _secondsRemaining = defaultTime;
      _changeColors(false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Helper method to format seconds into minutes:seconds
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Focus Time", style: TextStyle(
            fontSize: 32,
            fontFamily: "Knewave"
          ),),
          backgroundColor: _appBarColor,
        ),
        backgroundColor: _backgroundColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_formatDuration(_secondsRemaining), style: const TextStyle(fontSize: 80, fontFamily: "Knewave")),
            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _startTimer(false),
                  child: const Text("Start", style: TextStyle(
                      fontSize: 24,
                      fontFamily: "Knewave",
                      color: Color(0xffDE5086)
                  ),),
                ),
                const SizedBox(width: 5,),
                ElevatedButton(
                  onPressed: _pauseTimer,
                  child: Text(pauseText, style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Knewave",
                    color: Color(0xffDE5086)
                  ),),
                ),
                const SizedBox(width: 5,),
                ElevatedButton(
                  onPressed: _resetTimer,
                  child: const Text("Reset", style: TextStyle(
                      fontSize: 24,
                      fontFamily: "Knewave",
                      color: Color(0xffDE5086)
                  ),),
                ),
              ]
            )
          ]
        )
    );
  }
}
