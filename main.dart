import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CountdownApp());

class CountdownApp extends StatefulWidget {
  const CountdownApp({super.key});
  @override
  State<CountdownApp> createState() => _CountdownAppState();
}

class _CountdownAppState extends State<CountdownApp> {
  bool dark = true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Countdown Timer',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF635BDB), useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF8B82FF), useMaterial3: true, brightness: Brightness.dark),
      home: TimerHome(onThemeToggle: () => setState(() => dark = !dark), dark: dark),
    );
  }
}

class TimerHome extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool dark;
  const TimerHome({super.key, required this.onThemeToggle, required this.dark});
  @override
  State<TimerHome> createState() => _TimerHomeState();
}

class _TimerHomeState extends State<TimerHome> {
  final hCtrl = TextEditingController(text: '00');
  final mCtrl = TextEditingController(text: '05');
  final sCtrl = TextEditingController(text: '00');
  Timer? ticker;
  int total = 300;
  int remaining = 300;
  bool running = false;
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => history = prefs.getStringList('timer_history') ?? []);
  }

  Future<void> _saveHistory(String item) async {
    final prefs = await SharedPreferences.getInstance();
    history.insert(0, item);
    if (history.length > 20) history = history.take(20).toList();
    await prefs.setStringList('timer_history', history);
    if (mounted) setState(() {});
  }

  int _readInput() {
    int h = int.tryParse(hCtrl.text) ?? 0;
    int m = int.tryParse(mCtrl.text) ?? 0;
    int s = int.tryParse(sCtrl.text) ?? 0;
    return (h.clamp(0, 99) * 3600) + (m.clamp(0, 59) * 60) + s.clamp(0, 59);
  }

  String _format(int value) {
    final hh = value ~/ 3600;
    final mm = (value % 3600) ~/ 60;
    final ss = value % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  void _setPreset(int seconds) {
    _stopTicker();
    setState(() {
      total = seconds;
      remaining = seconds;
      running = false;
      hCtrl.text = (seconds ~/ 3600).toString().padLeft(2, '0');
      mCtrl.text = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
      sCtrl.text = (seconds % 60).toString().padLeft(2, '0');
    });
  }

  void _start() {
    if (running) return;
    if (remaining <= 0) {
      final value = _readInput();
      if (value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a time greater than zero.')));
        return;
      }
      total = value;
      remaining = value;
      _saveHistory('${_format(value)} • ${DateTime.now().toLocal().toString().substring(0, 16)}');
    }
    setState(() => running = true);
    ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (remaining <= 1) {
        t.cancel();
        SystemSound.play(SystemSoundType.alert);
        setState(() { remaining = 0; running = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time is up!')));
      } else {
        setState(() => remaining--);
      }
    });
  }

  void _pause() {
    _stopTicker();
    setState(() => running = false);
  }

  void _stopTicker() {
    ticker?.cancel();
    ticker = null;
  }

  void _reset() {
    _stopTicker();
    final value = _readInput();
    setState(() {
      running = false;
      total = value;
      remaining = value;
    });
  }

  @override
  void dispose() {
    _stopTicker();
    hCtrl.dispose(); mCtrl.dispose(); sCtrl.dispose();
    super.dispose();
  }

  Widget _timeField(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            onChanged: (_) {
              if (!running) {
                final v = _readInput();
                setState(() { total = v; remaining = v; });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(tooltip: 'Switch theme', onPressed: widget.onThemeToggle, icon: Icon(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text('FOCUS. TIME. ACHIEVE.', style: TextStyle(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: 260, height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 12, strokeCap: StrokeCap.round, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('TIME REMAINING', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        FittedBox(child: Text(_format(remaining), style: const TextStyle(fontSize: 39, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]))),
                        const SizedBox(height: 8),
                        Text(running ? 'Running' : (remaining == 0 ? 'Completed' : 'Ready'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text('Set your time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            Row(children: [
              _timeField('Hours', hCtrl),
              const SizedBox(width: 10),
              _timeField('Minutes', mCtrl),
              const SizedBox(width: 10),
              _timeField('Seconds', sCtrl),
            ]),
            const SizedBox(height: 20),
            const Text('Quick presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [1, 5, 10, 15, 30].map((n) =>
              ActionChip(label: Text('$n min'), onPressed: running ? null : () => _setPreset(n * 60))
            ).toList()),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: running ? _pause : _start,
                icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(running ? 'Pause' : (remaining == 0 ? 'Start again' : 'Start')),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Reset'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16))),
            ]),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent timer history', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () async { final p = await SharedPreferences.getInstance(); await p.remove('timer_history'); setState(() => history.clear()); }, child: const Text('Clear')),
            ]),
            if (history.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('Your used timers will appear here.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))))
            else
              ...history.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.timer_outlined)),
                title: Text(item.split(' • ').first, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(item.contains(' • ') ? item.split(' • ').last : ''),
                trailing: IconButton(icon: const Icon(Icons.replay), tooltip: 'Use this time', onPressed: () {
                  final parts = item.split(' • ').first.split(':').map((x) => int.tryParse(x) ?? 0).toList();
                  _setPreset(parts[0] * 3600 + parts[1] * 60 + parts[2]);
                }),
              )),
          ],
        ),
      ),
    );
  }
}
