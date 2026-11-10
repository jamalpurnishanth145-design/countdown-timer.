
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CountdownApp());
}

class CountdownApp extends StatefulWidget {
  const CountdownApp({super.key});

  @override
  State<CountdownApp> createState() => _CountdownAppState();
}

class _CountdownAppState extends State<CountdownApp> {
  bool isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Countdown Timer',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurpleAccent,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: TimerScreen(
        isDark: isDark,
        toggleTheme: () {
          setState(() => isDark = !isDark);
        },
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;

  const TimerScreen({
    super.key,
    required this.isDark,
    required this.toggleTheme,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final hoursController = TextEditingController(text: '00');
  final minutesController = TextEditingController(text: '05');
  final secondsController = TextEditingController(text: '00');

  Timer? timer;

  int totalSeconds = 300;
  int remainingSeconds = 300;

  bool isRunning = false;

  List<String> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      history = prefs.getStringList('timer_history') ?? [];
    });
  }

  Future<void> saveHistory(int seconds) async {
    final prefs = await SharedPreferences.getInstance();

    final entry =
        '${formatTime(seconds)} - ${DateTime.now().toString().substring(0, 16)}';

    history.insert(0, entry);

    if (history.length > 20) {
      history = history.take(20).toList();
    }

    await prefs.setStringList('timer_history', history);

    if (mounted) setState(() {});
  }

  int getInputSeconds() {
    final h = int.tryParse(hoursController.text) ?? 0;
    final m = int.tryParse(minutesController.text) ?? 0;
    final s = int.tryParse(secondsController.text) ?? 0;

    return h.clamp(0, 99) * 3600 +
        m.clamp(0, 59) * 60 +
        s.clamp(0, 59);
  }

  String formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    if (isRunning) return;

    if (remainingSeconds == 0) {
      final value = getInputSeconds();

      if (value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid time.'),
          ),
        );
        return;
      }

      totalSeconds = value;
      remainingSeconds = value;
      saveHistory(value);
    } else if (totalSeconds == 0) {
      return;
    }

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) {
        if (remainingSeconds > 1) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          t.cancel();

          SystemSound.play(SystemSoundType.alert);

          setState(() {
            remainingSeconds = 0;
            isRunning = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Time is up!'),
            ),
          );
        }
      },
    );
  }

  void pauseTimer() {
    timer?.cancel();

    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();

    final value = getInputSeconds();

    setState(() {
      isRunning = false;
      totalSeconds = value;
      remainingSeconds = value;
    });
  }

  void setPreset(int minutes) {
    timer?.cancel();

    final value = minutes * 60;

    setState(() {
      isRunning = false;
      totalSeconds = value;
      remainingSeconds = value;

      hoursController.text = '00';
      minutesController.text =
          minutes.toString().padLeft(2, '0');
      secondsController.text = '00';
    });
  }

  Widget timeInput(
    String label,
    TextEditingController controller,
  ) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onChanged: (_) {
          if (!isRunning) {
            final value = getInputSeconds();

            setState(() {
              totalSeconds = value;
              remainingSeconds = value;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    hoursController.dispose();
    minutesController.dispose();
    secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds == 0
        ? 0.0
        : remainingSeconds / totalSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Countdown Timer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'FOCUS • TIME • ACHIEVE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                height: 250,
                width: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'TIME REMAINING',
                          style: TextStyle(
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          formatTime(remainingSeconds),
                          style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          isRunning
                              ? 'Running'
                              : remainingSeconds == 0
                                  ? 'Completed'
                                  : 'Ready',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Set Your Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                timeInput('Hours', hoursController),
                const SizedBox(width: 10),
                timeInput('Minutes', minutesController),
                const SizedBox(width: 10),
                timeInput('Seconds', secondsController),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Presets',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [1, 5, 10, 15, 30].map((minutes) {
                return ActionChip(
                  label: Text('$minutes min'),
                  onPressed: isRunning
                      ? null
                      : () => setPreset(minutes),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isRunning
                        ? pauseTimer
                        : startTimer,
                    icon: Icon(
                      isRunning
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      isRunning ? 'Pause' : 'Start',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Timer History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () async {
                    final prefs =
                        await SharedPreferences.getInstance();

                    await prefs.remove('timer_history');

                    setState(() {
                      history.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),

            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Text('No timer history yet.'),
                ),
              )
            else
              ...history.map(
                (item) => ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
