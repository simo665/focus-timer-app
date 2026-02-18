import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:focus_time/design.dart';
import 'settings.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const String ringTone1 = "sounds/cute_anime_ringtone.mp3";
  static const String ringTone2 = "sounds/cute_alarm.mp3";

  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalBusyTime = 0;
  bool isPause = false;
  bool _isResting = true;
  bool _isTimerStarted = false;
  bool _onChillMode = true;

  // Background gradient
  LinearGradient _backgroundGradient = Design.chillGradient;

  // Ringtone player
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Initialize state with provider values after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<TimerSettings>();
      setState(() {
        _secondsRemaining = settings.focusDuration;
        _isResting = false; // Start with focus ready
        // But wait, user expects to start in "Busy" or "Chill"? Usually "Busy" waiting to start.
        // Let's assume start = "Busy" (not resting)
        _onChillMode = false;
        _backgroundGradient = Design.focusGradient;
      });
      _checkBatteryOptimization();
    });
  }

  Future<void> _checkBatteryOptimization() async {
    bool? isDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (isDisabled == false) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Design.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Timer Reliability",
            style: TextStyle(color: Design.lightText, fontFamily: "Knewave"),
          ),
          content: const Text(
            "To ensure your focus sessions aren't interrupted when the screen is off, please disable battery optimization for Focus Time.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Not Now",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Design.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Go to Settings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  // function to change the background color based on the timer state
  void _changeMode(bool busy) {
    if (busy) {
      setState(() {
        _backgroundGradient = Design.focusGradient;
        _onChillMode = false;
      });
    } else {
      setState(() {
        _backgroundGradient = Design.chillGradient;
        _onChillMode = true;
      });
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

    final settings = context.read<TimerSettings>();
    final audioProvider = context.read<AudioProvider>();

    // Start background music if enabled
    if (settings.isBackgroundMusicEnabled) {
      audioProvider.playMusic(
        !restTimer,
        volume: settings.volume,
      ); // !restTimer means busy mode (work)
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
        _secondsRemaining = restTimer
            ? settings.chillDuration
            : settings.focusDuration;
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
          _changeMode(false); // Default to chill look on finish? Or stop?
          // keeping as is from original logic, seems to go to chill look logic (false = chill/not busy)

          // play ring tone for notification
          _playRingTone(restTimer ? ringTone2 : ringTone1);

          // Stop background music on finish?
          // Usually we stop music when timer ends.
          audioProvider.pauseMusic(); // Pause so it can resume? Or stop?

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
    context.read<AudioProvider>().pauseMusic();

    if (isPause) {
      _startTimer(_isResting, reset: false);
    } else {
      setState(() {
        isPause = true;
        _changeMode(false); // Go to "chill" visual state on pause?
      });
    }
  }

  void _resetTimer() {
    if (!_isTimerStarted && !isPause) {
      // Allow reset if paused too
      // If purely stopped, maybe reset to default?
      // Let's rely on original logic but allow reset while paused
    }

    _timer?.cancel();
    context.read<AudioProvider>().stopMusic();

    final settings = context.read<TimerSettings>();

    setState(() {
      isPause = false;
      _isResting = false; // Reset to "ready to focus"
      _secondsRemaining = settings.focusDuration;
      _totalBusyTime = 0;
      _changeMode(true); // "Busy" style ready
      _isTimerStarted = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
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
    // Listen to settings changes to update default time if timer not running
    final settings = context.watch<TimerSettings>();

    // Sync with settings if timer is idle
    if (!_isTimerStarted && !isPause) {
      if (_isResting) {
        _secondsRemaining = settings.chillDuration;
      } else {
        _secondsRemaining = settings.focusDuration;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Focus Time",
          style: TextStyle(
            fontSize: 28, // Slightly smaller for balance
            fontFamily: "Knewave",
            color: Design.lightText,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Design.lightText),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              // Upon return, if timer is stopped, reset to new defaults?
              if (!_isTimerStarted && !isPause) {
                _resetTimer();
              }
            },
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          // Ensure content is within safe area
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Mode Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _onChillMode ? "Chilling Time" : "Busy Mode",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Knewave",
                    color: Design.lightText,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const Spacer(),

              // Timer Display
              Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative Circle
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Timer Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_secondsRemaining),
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight
                              .bold, // Use system font for readability
                          fontFamily:
                              "Knewave", // Stick to requested font but maybe system is better? Let's trying keeping Knewave as per design
                          color: Design.lightText,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 10.0,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total Focus: ${_formatDuration(_totalBusyTime)}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Design.lightText.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start Button
                    _buildControlButton(
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _startTimer(false, isButton: true),
                      isActive: !_isTimerStarted,
                      isPrimary: true,
                    ),
                    const SizedBox(width: 20),
                    // Pause Button
                    _buildControlButton(
                      icon: isPause
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      onPressed: _pauseTimer,
                      isActive: _isTimerStarted,
                      isPrimary: false,
                    ),
                    const SizedBox(width: 20),
                    // Reset Button
                    _buildControlButton(
                      icon: Icons.refresh_rounded,
                      onPressed: _resetTimer,
                      isActive: _isTimerStarted || isPause,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    required bool isPrimary,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isActive ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? Design.accent : Colors.white,
            disabledBackgroundColor: isPrimary
                ? Design.accent.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            foregroundColor: isPrimary ? Colors.white : Design.primary,
            disabledForegroundColor: isPrimary
                ? Colors.white.withOpacity(0.7)
                : Design.primary.withOpacity(0.5),
            padding: EdgeInsets.all(isPrimary ? 24 : 18),
            shape: const CircleBorder(),
            elevation: 0,
          ),
          child: Icon(icon, size: isPrimary ? 40 : 30),
        ),
      ),
    );
  }
}
