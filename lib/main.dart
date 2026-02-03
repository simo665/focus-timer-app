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
    return const MaterialApp(home: TimerScreen());
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {

  static const int defaultBusyTime = 60*24;
  static const int defaultRestTime = 60*5;
  static const String ringTone1 = "sounds/cute_anime_ringtone.mp3";
  static const String ringTone2 = "sounds/cute_alarm.mp3";

  Timer? _timer;
  int _secondsRemaining = defaultBusyTime;
  int _totalBusyTime = 0;
  bool isPause = false;
  bool _isResting = true;
  bool _isTimerStarted = false;
  bool _OnChillMode = true;

  // background colors
  Color _appBarColor = Color(0xffFFB3CB);
  Color _backgroundColor = Color(0xffDE648A);

  // Ringtone player
  final AudioPlayer _player = AudioPlayer();

  // function to change the background color based on the timer state
  void _changeMode(bool busy) {
    if (busy) {
      setState(() {
        _backgroundColor = Color(0xff9F47DE);
        _appBarColor = Color(0xffC795DE);
        _OnChillMode = false;
      });
    } else {
      _appBarColor = Color(0xffFFB3CB);
      _backgroundColor = Color(0xffDE648A);
      _OnChillMode = true;
    }
  }

  // play ringtone function
  void _playRingTone(String source) async {
    await _player.play(AssetSource(source));
  }
  // starting timer button logic
  void _startTimer(bool restTimer, {bool reset = true, bool isButton = false}) {
    // Check if the user clicking starts while the timer already started
    if (isButton & _isTimerStarted) {
      return;
    }

    // cancel previous timer if it exists
    _timer?.cancel();
    setState(() {
      isPause = false;
      _isResting = restTimer;
      _isTimerStarted = true;
    });
    // reset remaining seconds
    if (reset) {
      setState(() {
        _secondsRemaining = restTimer ? defaultRestTime : defaultBusyTime;
      });
    }
    // change background color
    _changeMode(!restTimer);
    // start new timer
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        // check if timer is finished
        if (_secondsRemaining == 0) {
          // cancel timer
          timer.cancel();
          // change color
          _changeMode(false);
          // play ring tone for notification
          _playRingTone( restTimer ? ringTone2 : ringTone1);

          // wait x seconds before next time
          // start new timer for rest if not in rest already
          Future.delayed(const Duration(seconds: 10), () {
            _startTimer(!restTimer);
          });
          return;
        } else {
          _secondsRemaining--;
          if (!restTimer) {
            _totalBusyTime++;
          }
        }
      });
    });
  }

  void _pauseTimer() {
    if (!_isTimerStarted) {
      return;
    }
    _timer?.cancel();
    if (isPause) {
      _startTimer(_isResting, reset: false);
    } else {
      setState(() {
        isPause = true;
        _changeMode(false);
      });
    }
  }

  void _resetTimer() {
    if (!_isTimerStarted) {
      return;
    }

    _timer?.cancel();
    setState(() {
      isPause = false;
      _isResting = true;
      _secondsRemaining = defaultBusyTime;
      _totalBusyTime = 0;
      _changeMode(false);
      _isTimerStarted = false;
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
    String twoDigitHours = twoDigits(duration.inHours.remainder(60));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (twoDigitHours == "00") {
      return "$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Focus Time",
          style: TextStyle(fontSize: 32, fontFamily: "Knewave"),
        ),
        backgroundColor: _appBarColor,
      ),
      backgroundColor: _backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _OnChillMode ? "Chilling Time" : "Busy",
            style: TextStyle(
              fontSize: 44,
              fontFamily: "Knewave",
              color: _OnChillMode ? Color(0xffFFB3CB) : Color(0xffC795DE),
            ),
          ),
          const SizedBox(height: 60,),
          Text(
            _formatDuration(_secondsRemaining),
            style: const TextStyle(
                fontSize: 80,
                fontFamily: "Knewave",
              color: Colors.white
            ),
          ),
          Text(
            _formatDuration(_totalBusyTime),
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Knewave",
              color: Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _startTimer(false, isButton: true,),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerStarted ? Colors.white60 : Colors.white
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Knewave",
                    color: Color(0xffDE5086),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: _pauseTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimerStarted ? Colors.white : Colors.white60
                ),
                child: Text(
                  isPause ? "Resume" : "Pause",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Knewave",
                    color: Color(0xffDE5086),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: _resetTimer,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerStarted ? Colors.white : Colors.white60
                ),
                child: const Text(
                  "Reset",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Knewave",
                    color: Color(0xffDE5086),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
